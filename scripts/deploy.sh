#!/bin/bash

# Kubernetes Deployment and Management Script
# Provides easy commands for deploying and managing the K8s infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="terraform"
K8S_DIR="kubernetes"
SECURITY_DIR="security"

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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    local missing_tools=()
    
    # Check for required tools
    for tool in terraform kubectl aws helm; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and try again."
        exit 1
    fi
    
    log_info "All prerequisites are satisfied."
}

# Initialize Terraform
init_terraform() {
    local env=${1:-"dev"}
    
    log_info "Initializing Terraform for environment: $env"
    
    cd "$TERRAFORM_DIR"
    terraform init
    
    if [ -f "environments/$env/terraform.tfvars" ]; then
        log_info "Using variables file: environments/$env/terraform.tfvars"
    else
        log_error "Variables file not found: environments/$env/terraform.tfvars"
        exit 1
    fi
    
    cd ..
}

# Plan Terraform deployment
plan_terraform() {
    local env=${1:-"dev"}
    
    log_info "Planning Terraform deployment for environment: $env"
    
    cd "$TERRAFORM_DIR"
    terraform plan -var-file="environments/$env/terraform.tfvars" -out="$env.tfplan"
    cd ..
}

# Apply Terraform
apply_terraform() {
    local env=${1:-"dev"}
    
    log_info "Applying Terraform configuration for environment: $env"
    
    cd "$TERRAFORM_DIR"
    
    if [ -f "$env.tfplan" ]; then
        terraform apply "$env.tfplan"
    else
        log_warn "Plan file not found. Running apply with var-file..."
        terraform apply -var-file="environments/$env/terraform.tfvars" -auto-approve
    fi
    
    # Get cluster name and update kubeconfig
    local cluster_name=$(terraform output -raw cluster_name)
    local aws_region=$(terraform output -json | jq -r '.aws_region.value // "us-west-2"')
    
    log_info "Updating kubeconfig for cluster: $cluster_name"
    aws eks update-kubeconfig --region "$aws_region" --name "$cluster_name"
    
    cd ..
}

# Deploy Kubernetes manifests
deploy_k8s() {
    log_info "Deploying Kubernetes manifests..."
    
    # Apply network policies first
    if [ -f "$K8S_DIR/network-policies.yaml" ]; then
        log_info "Applying network policies..."
        kubectl apply -f "$K8S_DIR/network-policies.yaml"
    fi
    
    # Apply DaemonSet
    if [ -f "$K8S_DIR/logging-daemonset.yaml" ]; then
        log_info "Applying logging DaemonSet..."
        kubectl apply -f "$K8S_DIR/logging-daemonset.yaml"
    fi
    
    # Wait for pods to be ready
    log_info "Waiting for DaemonSet pods to be ready..."
    kubectl rollout status daemonset/logging-daemon -n kube-system --timeout=300s
    
    log_info "Kubernetes manifests deployed successfully."
}

# Get cluster info
get_cluster_info() {
    local env=${1:-"dev"}
    
    log_info "Getting cluster information for environment: $env"
    
    cd "$TERRAFORM_DIR"
    
    if ! terraform show > /dev/null 2>&1; then
        log_error "Terraform state not found. Please deploy the infrastructure first."
        cd ..
        return 1
    fi
    
    echo ""
    echo "=== Cluster Information ==="
    echo "Cluster Name: $(terraform output -raw cluster_name 2>/dev/null || echo 'N/A')"
    echo "Cluster Endpoint: $(terraform output -raw cluster_endpoint 2>/dev/null || echo 'N/A')"
    echo "VPC ID: $(terraform output -raw vpc_id 2>/dev/null || echo 'N/A')"
    
    cd ..
    
    echo ""
    echo "=== Kubernetes Status ==="
    kubectl get nodes -o wide 2>/dev/null || echo "Unable to connect to cluster"
    
    echo ""
    echo "=== Monitoring URLs ==="
    echo "Grafana: $(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo 'Not available')"
    echo "Prometheus: Available via port-forward: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
}

# Destroy infrastructure
destroy_terraform() {
    local env=${1:-"dev"}
    
    log_warn "This will destroy all infrastructure for environment: $env"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_info "Operation cancelled."
        return 0
    fi
    
    log_info "Destroying Terraform infrastructure for environment: $env"
    
    cd "$TERRAFORM_DIR"
    terraform destroy -var-file="environments/$env/terraform.tfvars" -auto-approve
    cd ..
    
    log_info "Infrastructure destroyed."
}

# Port forward services
port_forward() {
    local service=${1:-"grafana"}
    
    case $service in
        "grafana")
            log_info "Port forwarding Grafana (http://localhost:3000)"
            kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
            ;;
        "prometheus")
            log_info "Port forwarding Prometheus (http://localhost:9090)"
            kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
            ;;
        "alertmanager")
            log_info "Port forwarding AlertManager (http://localhost:9093)"
            kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
            ;;
        *)
            log_error "Unknown service: $service"
            echo "Available services: grafana, prometheus, alertmanager"
            exit 1
            ;;
    esac
}

# Show logs
show_logs() {
    local component=${1:-"daemon"}
    
    case $component in
        "daemon")
            log_info "Showing DaemonSet logs..."
            kubectl logs -n kube-system -l app=logging-daemon --tail=50 -f
            ;;
        "prometheus")
            log_info "Showing Prometheus logs..."
            kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus --tail=50 -f
            ;;
        "grafana")
            log_info "Showing Grafana logs..."
            kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50 -f
            ;;
        *)
            log_error "Unknown component: $component"
            echo "Available components: daemon, prometheus, grafana"
            exit 1
            ;;
    esac
}

# Main function
main() {
    local command=${1:-"help"}
    local env=${2:-"dev"}
    
    case $command in
        "check")
            check_prerequisites
            ;;
        "init")
            check_prerequisites
            init_terraform "$env"
            ;;
        "plan")
            check_prerequisites
            plan_terraform "$env"
            ;;
        "apply")
            check_prerequisites
            init_terraform "$env"
            plan_terraform "$env"
            apply_terraform "$env"
            ;;
        "deploy")
            check_prerequisites
            init_terraform "$env"
            apply_terraform "$env"
            deploy_k8s
            ;;
        "deploy-k8s")
            deploy_k8s
            ;;
        "info")
            get_cluster_info "$env"
            ;;
        "destroy")
            check_prerequisites
            destroy_terraform "$env"
            ;;
        "port-forward")
            port_forward "$env"
            ;;
        "logs")
            show_logs "$env"
            ;;
        "help"|*)
            echo "Kubernetes Infrastructure Management Script"
            echo ""
            echo "Usage: $0 <command> [environment] [options]"
            echo ""
            echo "Commands:"
            echo "  check                    - Check prerequisites"
            echo "  init [env]              - Initialize Terraform"
            echo "  plan [env]              - Plan Terraform deployment"
            echo "  apply [env]             - Apply Terraform (infrastructure only)"
            echo "  deploy [env]            - Full deployment (infrastructure + K8s)"
            echo "  deploy-k8s              - Deploy Kubernetes manifests only"
            echo "  info [env]              - Show cluster information"
            echo "  destroy [env]           - Destroy infrastructure"
            echo "  port-forward <service>  - Port forward services (grafana|prometheus|alertmanager)"
            echo "  logs <component>        - Show component logs (daemon|prometheus|grafana)"
            echo "  help                    - Show this help"
            echo ""
            echo "Environments: dev, prod (default: dev)"
            echo ""
            echo "Examples:"
            echo "  $0 deploy dev           - Deploy development environment"
            echo "  $0 deploy prod          - Deploy production environment"
            echo "  $0 port-forward grafana - Access Grafana locally"
            echo "  $0 logs daemon          - Show DaemonSet logs"
            ;;
    esac
}

# Run main function
main "$@"