# Local Minikube Setup for Windows
# Quick installation and deployment

# Install Minikube (if not already installed)
Write-Host "🚀 Installing Minikube..." -ForegroundColor Green
if (-not (Get-Command minikube -ErrorAction SilentlyContinue)) {
    # Install via Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install minikube -y
    } else {
        Write-Host "Please install Chocolatey first or download Minikube manually" -ForegroundColor Red
        Write-Host "Minikube: https://minikube.sigs.k8s.io/docs/start/" -ForegroundColor Yellow
        exit 1
    }
}

# Start Minikube cluster
Write-Host "🏗️ Starting Minikube cluster..." -ForegroundColor Green
minikube start --memory=4096 --cpus=2 --driver=hyperv

# Enable necessary addons
Write-Host "📦 Enabling Minikube addons..." -ForegroundColor Green
minikube addons enable metrics-server
minikube addons enable ingress

# Install Helm (if not already installed)
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "📚 Installing Helm..." -ForegroundColor Green
    choco install kubernetes-helm -y
}

# Add Helm repos and deploy
Write-Host "📊 Deploying monitoring stack..." -ForegroundColor Green
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace demo-monitoring

helm install prometheus prometheus-community/kube-prometheus-stack `
    --namespace demo-monitoring `
    --set grafana.adminPassword=admin123 `
    --set grafana.service.type=NodePort `
    --set grafana.service.nodePort=30000 `
    --wait --timeout=10m

# Get Minikube URL
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Access Grafana:" -ForegroundColor Cyan
$minikubeIP = minikube ip
Write-Host "   URL: http://$minikubeIP`:30000" -ForegroundColor Yellow
Write-Host "   Or run: minikube service prometheus-grafana -n demo-monitoring" -ForegroundColor Yellow
Write-Host ""
Write-Host "👤 Login: admin / admin123" -ForegroundColor Green