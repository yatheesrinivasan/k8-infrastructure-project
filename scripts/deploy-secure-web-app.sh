#!/bin/bash

# Complete deployment script for secure public web application
# This script sets up everything needed to expose an AKS application securely to the internet

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN_NAME="myapp.yourdomain.com"
EMAIL="admin@yourdomain.com"
NAMESPACE="production"
APP_NAME="secure-web-app"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is installed and configured
    if ! kubectl cluster-info &> /dev/null; then
        log_error "kubectl is not configured or cluster is not accessible"
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

setup_namespace() {
    log_info "Setting up namespace: $NAMESPACE"
    
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Add security labels
    kubectl label namespace $NAMESPACE \
        pod-security.kubernetes.io/enforce=baseline \
        pod-security.kubernetes.io/audit=restricted \
        pod-security.kubernetes.io/warn=restricted \
        --overwrite
    
    log_info "Namespace $NAMESPACE created successfully"
}

install_ingress_controller() {
    log_info "Installing NGINX Ingress Controller..."
    
    # Add Helm repository
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    # Install NGINX Ingress Controller
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.type=LoadBalancer \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz" \
        --set controller.metrics.enabled=true \
        --set controller.config.ssl-protocols="TLSv1.2 TLSv1.3" \
        --set controller.config.server-tokens="false" \
        --wait
    
    log_info "NGINX Ingress Controller installed successfully"
    
    # Wait for LoadBalancer IP
    log_info "Waiting for LoadBalancer IP..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    
    # Get LoadBalancer IP
    EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    log_info "LoadBalancer IP: $EXTERNAL_IP"
    log_warn "Please update your DNS records to point $DOMAIN_NAME to $EXTERNAL_IP"
}

install_cert_manager() {
    log_info "Installing Cert-Manager..."
    
    # Install cert-manager
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
    
    # Wait for cert-manager to be ready
    kubectl wait --namespace cert-manager \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/instance=cert-manager \
        --timeout=300s
    
    log_info "Cert-Manager installed successfully"
}

setup_ssl_issuer() {
    log_info "Setting up Let's Encrypt SSL issuer..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
    
    log_info "SSL issuer configured successfully"
}

deploy_application() {
    log_info "Deploying secure web application..."
    
    # Apply application deployment
    kubectl apply -f examples/secure-web-app-deployment.yaml
    
    # Wait for deployment to be ready
    kubectl wait --namespace $NAMESPACE \
        --for=condition=available deployment/$APP_NAME \
        --timeout=300s
    
    log_info "Application deployed successfully"
}

setup_network_policies() {
    log_info "Applying network security policies..."
    
    # Apply network policies
    kubectl apply -f examples/network-security-policies.yaml
    
    log_info "Network security policies applied successfully"
}

create_ingress() {
    log_info "Creating secure ingress resource..."
    
    # Update domain name in ingress
    sed "s/myapp.yourdomain.com/$DOMAIN_NAME/g" examples/secure-ingress.yaml | kubectl apply -f -
    
    log_info "Ingress resource created successfully"
    
    # Wait for certificate to be ready
    log_info "Waiting for SSL certificate to be issued..."
    kubectl wait --namespace $NAMESPACE \
        --for=condition=ready certificate/secure-web-app-tls \
        --timeout=600s || log_warn "Certificate issuance may take a few minutes"
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check pod status
    log_info "Pod status:"
    kubectl get pods -n $NAMESPACE -l app=$APP_NAME
    
    # Check service
    log_info "Service status:"
    kubectl get svc -n $NAMESPACE
    
    # Check ingress
    log_info "Ingress status:"
    kubectl get ingress -n $NAMESPACE
    
    # Check certificate
    log_info "Certificate status:"
    kubectl get certificate -n $NAMESPACE
    
    # Test connectivity
    log_info "Testing connectivity..."
    EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if curl -s --connect-timeout 5 http://$EXTERNAL_IP > /dev/null; then
        log_info "✅ Application is accessible via HTTP"
    else
        log_warn "⚠️ Application may not be ready yet"
    fi
}

show_next_steps() {
    log_info "Deployment completed! Next steps:"
    echo ""
    echo "1. Update DNS records:"
    EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "   Point $DOMAIN_NAME to $EXTERNAL_IP"
    echo ""
    echo "2. Wait for DNS propagation (may take 5-60 minutes)"
    echo ""
    echo "3. Test your application:"
    echo "   curl -I https://$DOMAIN_NAME"
    echo ""
    echo "4. Monitor certificate status:"
    echo "   kubectl get certificate -n $NAMESPACE"
    echo ""
    echo "5. Check application logs:"
    echo "   kubectl logs -n $NAMESPACE -l app=$APP_NAME"
    echo ""
    echo "🔒 Your application is now securely exposed to the internet!"
}

# Main execution
main() {
    log_info "Starting secure AKS web application deployment..."
    
    check_prerequisites
    setup_namespace
    install_ingress_controller
    install_cert_manager
    setup_ssl_issuer
    deploy_application
    setup_network_policies
    create_ingress
    verify_deployment
    show_next_steps
    
    log_info "✅ Deployment completed successfully!"
}

# Run main function
main "$@"