# PowerShell script for deploying secure web application to AKS
# Complete setup for exposing internal AKS applications securely to the internet

param(
    [Parameter(Mandatory=$true)]
    [string]$DomainName = "myapp.yourdomain.com",
    
    [Parameter(Mandatory=$true)]
    [string]$Email = "admin@yourdomain.com",
    
    [string]$Namespace = "production",
    [string]$AppName = "secure-web-app"
)

# Functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARN] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check kubectl
    try {
        kubectl cluster-info | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "kubectl is not configured or cluster is not accessible"
        }
    }
    catch {
        Write-Error "kubectl is not configured or cluster is not accessible"
        exit 1
    }
    
    # Check helm
    try {
        helm version | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Helm is not installed"
        }
    }
    catch {
        Write-Error "Helm is not installed"
        exit 1
    }
    
    Write-Info "Prerequisites check passed"
}

function New-SecureNamespace {
    Write-Info "Setting up namespace: $Namespace"
    
    # Create namespace
    kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
    
    # Add security labels
    kubectl label namespace $Namespace `
        pod-security.kubernetes.io/enforce=baseline `
        pod-security.kubernetes.io/audit=restricted `
        pod-security.kubernetes.io/warn=restricted `
        --overwrite
    
    Write-Info "Namespace $Namespace created successfully"
}

function Install-IngressController {
    Write-Info "Installing NGINX Ingress Controller..."
    
    # Add Helm repository
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    # Install NGINX Ingress Controller
    $helmArgs = @(
        "upgrade", "--install", "ingress-nginx", "ingress-nginx/ingress-nginx",
        "--namespace", "ingress-nginx",
        "--create-namespace",
        "--set", "controller.service.type=LoadBalancer",
        "--set", "controller.service.annotations.service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path=/healthz",
        "--set", "controller.metrics.enabled=true",
        "--set", "controller.config.ssl-protocols=TLSv1.2 TLSv1.3",
        "--set", "controller.config.server-tokens=false",
        "--wait"
    )
    
    & helm $helmArgs
    
    Write-Info "NGINX Ingress Controller installed successfully"
    
    # Wait for LoadBalancer IP
    Write-Info "Waiting for LoadBalancer IP..."
    kubectl wait --namespace ingress-nginx `
        --for=condition=ready pod `
        --selector=app.kubernetes.io/component=controller `
        --timeout=300s
    
    # Get LoadBalancer IP
    $externalIp = kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    Write-Info "LoadBalancer IP: $externalIp"
    Write-Warning "Please update your DNS records to point $DomainName to $externalIp"
}

function Install-CertManager {
    Write-Info "Installing Cert-Manager..."
    
    # Install cert-manager
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
    
    # Wait for cert-manager to be ready
    kubectl wait --namespace cert-manager `
        --for=condition=ready pod `
        --selector=app.kubernetes.io/instance=cert-manager `
        --timeout=300s
    
    Write-Info "Cert-Manager installed successfully"
}

function New-SslIssuer {
    Write-Info "Setting up Let's Encrypt SSL issuer..."
    
    $issuerYaml = @"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $Email
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
    - http01:
        ingress:
          class: nginx
"@
    
    $issuerYaml | kubectl apply -f -
    
    Write-Info "SSL issuer configured successfully"
}

function Deploy-Application {
    Write-Info "Deploying secure web application..."
    
    # Apply application deployment
    kubectl apply -f examples/secure-web-app-deployment.yaml
    
    # Wait for deployment to be ready
    kubectl wait --namespace $Namespace `
        --for=condition=available deployment/$AppName `
        --timeout=300s
    
    Write-Info "Application deployed successfully"
}

function Set-NetworkPolicies {
    Write-Info "Applying network security policies..."
    
    # Apply network policies
    kubectl apply -f examples/network-security-policies.yaml
    
    Write-Info "Network security policies applied successfully"
}

function New-SecureIngress {
    Write-Info "Creating secure ingress resource..."
    
    # Read ingress file and replace domain name
    $ingressContent = Get-Content examples/secure-ingress.yaml -Raw
    $ingressContent = $ingressContent -replace "myapp.yourdomain.com", $DomainName
    
    # Apply ingress
    $ingressContent | kubectl apply -f -
    
    Write-Info "Ingress resource created successfully"
    
    # Wait for certificate to be ready
    Write-Info "Waiting for SSL certificate to be issued..."
    try {
        kubectl wait --namespace $Namespace `
            --for=condition=ready certificate/secure-web-app-tls `
            --timeout=600s
    }
    catch {
        Write-Warning "Certificate issuance may take a few minutes"
    }
}

function Test-Deployment {
    Write-Info "Verifying deployment..."
    
    # Check pod status
    Write-Info "Pod status:"
    kubectl get pods -n $Namespace -l app=$AppName
    
    # Check service
    Write-Info "Service status:"
    kubectl get svc -n $Namespace
    
    # Check ingress
    Write-Info "Ingress status:"
    kubectl get ingress -n $Namespace
    
    # Check certificate
    Write-Info "Certificate status:"
    kubectl get certificate -n $Namespace
    
    # Test connectivity
    Write-Info "Testing connectivity..."
    $externalIp = kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    
    try {
        $response = Invoke-WebRequest -Uri "http://$externalIp" -TimeoutSec 5 -UseBasicParsing
        Write-Info "✅ Application is accessible via HTTP"
    }
    catch {
        Write-Warning "⚠️ Application may not be ready yet"
    }
}

function Show-NextSteps {
    Write-Info "Deployment completed! Next steps:"
    Write-Host ""
    
    $externalIp = kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    
    Write-Host "1. Update DNS records:" -ForegroundColor Cyan
    Write-Host "   Point $DomainName to $externalIp" -ForegroundColor White
    Write-Host ""
    
    Write-Host "2. Wait for DNS propagation (may take 5-60 minutes)" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "3. Test your application:" -ForegroundColor Cyan
    Write-Host "   curl -I https://$DomainName" -ForegroundColor White
    Write-Host ""
    
    Write-Host "4. Monitor certificate status:" -ForegroundColor Cyan
    Write-Host "   kubectl get certificate -n $Namespace" -ForegroundColor White
    Write-Host ""
    
    Write-Host "5. Check application logs:" -ForegroundColor Cyan
    Write-Host "   kubectl logs -n $Namespace -l app=$AppName" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🔒 Your application is now securely exposed to the internet!" -ForegroundColor Green
}

# Main execution
function Main {
    Write-Info "Starting secure AKS web application deployment..."
    
    Test-Prerequisites
    New-SecureNamespace
    Install-IngressController
    Install-CertManager
    New-SslIssuer
    Deploy-Application
    Set-NetworkPolicies
    New-SecureIngress
    Test-Deployment
    Show-NextSteps
    
    Write-Info "✅ Deployment completed successfully!"
}

# Execute main function
try {
    Main
}
catch {
    Write-Error "Deployment failed: $_"
    exit 1
}