# Complete Local Grafana Demo Setup - No CSG Dependencies
# This script sets up everything locally without touching company infrastructure

Write-Host "🚀 Local Grafana Demo Setup (CSG-Free)" -ForegroundColor Green
Write-Host "This will create a completely isolated local environment" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Cyan

$dockerInstalled = $false
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker is installed: $dockerVersion" -ForegroundColor Green
        $dockerInstalled = $true
    }
} catch {
    Write-Host "❌ Docker not found" -ForegroundColor Red
}

if (-not $dockerInstalled) {
    Write-Host ""
    Write-Host "📥 Docker Desktop Installation Required" -ForegroundColor Yellow
    Write-Host "1. Download: https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    Write-Host "2. Install Docker Desktop" -ForegroundColor Cyan
    Write-Host "3. Restart your computer" -ForegroundColor Cyan
    Write-Host "4. Run this script again" -ForegroundColor Cyan
    Write-Host ""
    
    $install = Read-Host "Open Docker Desktop download page? [Y/N]"
    if ($install.ToUpper() -eq "Y") {
        Start-Process "https://www.docker.com/products/docker-desktop/"
    }
    
    Write-Host "Please install Docker Desktop and run this script again." -ForegroundColor Yellow
    exit 0
}

# Step 2: Download and setup Minikube (isolated)
Write-Host "📦 Setting up Minikube..." -ForegroundColor Cyan

$minikubePath = "C:\temp\minikube-demo\minikube.exe"
$demoDir = "C:\temp\minikube-demo"

# Create isolated directory
if (!(Test-Path $demoDir)) {
    New-Item -ItemType Directory -Path $demoDir -Force
}

# Download Minikube if not exists
if (!(Test-Path $minikubePath)) {
    Write-Host "⏬ Downloading Minikube..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe" -OutFile $minikubePath -UseBasicParsing
}

# Step 3: Start isolated Minikube cluster
Write-Host "🏗️ Starting local Kubernetes cluster..." -ForegroundColor Cyan
Set-Location $demoDir

try {
    # Start Minikube with specific profile to avoid conflicts
    & $minikubePath start --profile=grafana-demo --driver=docker --memory=4096 --cpus=2 --kubernetes-version=v1.28.0
    
    # Set kubectl context to our demo cluster
    & $minikubePath kubectl --profile=grafana-demo -- config use-context grafana-demo
    
    Write-Host "✅ Local cluster started successfully" -ForegroundColor Green
    
    # Verify we're using the right cluster (not CSG)
    Write-Host "🔍 Verifying cluster isolation..." -ForegroundColor Cyan
    $nodes = & $minikubePath kubectl --profile=grafana-demo -- get nodes --no-headers
    if ($nodes -match "grafana-demo") {
        Write-Host "✅ Connected to isolated local cluster" -ForegroundColor Green
    } else {
        Write-Host "❌ Cluster verification failed" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "❌ Failed to start Minikube: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Download Helm
Write-Host "📦 Setting up Helm..." -ForegroundColor Cyan
$helmPath = "$demoDir\helm.exe"
if (!(Test-Path $helmPath)) {
    Invoke-WebRequest -Uri "https://get.helm.sh/helm-v3.19.0-windows-amd64.zip" -OutFile "$demoDir\helm.zip" -UseBasicParsing
    Expand-Archive -Path "$demoDir\helm.zip" -DestinationPath "$demoDir\helm-temp" -Force
    Move-Item "$demoDir\helm-temp\windows-amd64\helm.exe" $helmPath
    Remove-Item -Recurse -Force "$demoDir\helm-temp", "$demoDir\helm.zip"
}

# Step 5: Deploy Grafana stack
Write-Host "📊 Deploying Grafana monitoring stack..." -ForegroundColor Cyan

# Add repos using minikube kubectl
& $minikubePath kubectl --profile=grafana-demo -- create namespace monitoring
& $helmPath repo add prometheus-community https://prometheus-community.github.io/helm-charts
& $helmPath repo update

# Deploy with minikube kubectl
Write-Host "🚀 Installing Prometheus + Grafana..." -ForegroundColor Cyan
& $helmPath upgrade --install prometheus prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --set grafana.service.type=NodePort `
  --set grafana.service.nodePort=30000 `
  --set grafana.adminPassword=admin123 `
  --timeout=15m `
  --wait `
  --kubeconfig ($minikubePath + " kubectl --profile=grafana-demo -- config view --raw")

# Step 6: Create custom dashboard
$dashboardYaml = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-dashboards
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  demo-dashboard.json: |
    {
      "dashboard": {
        "id": null,
        "title": "🚀 Local Kubernetes Demo",
        "tags": ["kubernetes", "demo", "local"],
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Cluster Status",
            "type": "stat",
            "targets": [{"expr": "up{job=\"kubernetes-apiservers\"}", "legendFormat": "API Server"}],
            "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "Pod Count",
            "type": "stat",
            "targets": [{"expr": "count(kube_pod_info)", "legendFormat": "Total Pods"}],
            "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0}
          },
          {
            "id": 3,
            "title": "Memory Usage",
            "type": "timeseries",
            "targets": [{"expr": "node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100", "legendFormat": "Available %"}],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 4}
          }
        ],
        "time": {"from": "now-1h", "to": "now"},
        "refresh": "30s"
      }
    }
"@

$dashboardYaml | Out-File -FilePath "$demoDir\dashboard.yaml" -Encoding UTF8
& $minikubePath kubectl --profile=grafana-demo -- apply -f "$demoDir\dashboard.yaml"

# Step 7: Get access information
$minikubeIP = & $minikubePath ip --profile=grafana-demo

Write-Host ""
Write-Host "✅ Local Grafana Demo Ready!" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Access Your Local Grafana:" -ForegroundColor Yellow
Write-Host "   Method 1: http://$minikubeIP`:30000" -ForegroundColor Cyan
Write-Host "   Method 2: minikube service prometheus-grafana -n monitoring --profile=grafana-demo" -ForegroundColor Cyan
Write-Host ""
Write-Host "👤 Login Credentials:" -ForegroundColor Yellow
Write-Host "   Username: admin" -ForegroundColor Cyan
Write-Host "   Password: admin123" -ForegroundColor Cyan
Write-Host ""
Write-Host "🛠️ Management Commands:" -ForegroundColor Yellow
Write-Host "   View services: minikube kubectl --profile=grafana-demo -- get svc -n monitoring" -ForegroundColor Cyan
Write-Host "   Stop cluster: minikube stop --profile=grafana-demo" -ForegroundColor Cyan
Write-Host "   Delete cluster: minikube delete --profile=grafana-demo" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 This is completely isolated from your CSG environment!" -ForegroundColor Green

# Show services
& $minikubePath kubectl --profile=grafana-demo -- get svc -n monitoring