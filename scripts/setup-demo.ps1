# Simplified Local Kubernetes Setup for Grafana Demo
Write-Host "🚀 Setting up local Kubernetes with Docker Desktop..." -ForegroundColor Green

# Check if we can install Docker Desktop
Write-Host "📦 Checking Docker availability..." -ForegroundColor Cyan

# Option 1: Try to download and install Docker Desktop
Write-Host "💡 Docker Desktop is required for Minikube." -ForegroundColor Yellow
Write-Host "Please follow these steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣ Download Docker Desktop from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
Write-Host "2️⃣ Install Docker Desktop and restart your computer" -ForegroundColor Cyan
Write-Host "3️⃣ Run this script again after Docker is installed" -ForegroundColor Cyan
Write-Host ""

# Alternative: Check if WSL2 is available for Docker
Write-Host "🔍 Checking WSL2 availability..." -ForegroundColor Cyan
try {
    $wslVersion = wsl --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ WSL2 is available - Docker Desktop can use WSL2 backend" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ WSL2 not found - Docker Desktop will use Hyper-V" -ForegroundColor Yellow
}

# Option 2: Alternative lightweight setup using existing AKS cluster
Write-Host ""
Write-Host "🎯 Alternative: Use existing AKS cluster for demo" -ForegroundColor Yellow
Write-Host "Since you have access to AKS cluster, we can:" -ForegroundColor Cyan
Write-Host "1. Create a separate namespace for demo" -ForegroundColor Cyan
Write-Host "2. Deploy Grafana in that namespace" -ForegroundColor Cyan
Write-Host "3. Use NodePort or port-forwarding for access" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "Choose option: [1] Install Docker Desktop first, [2] Use existing AKS cluster, [Q] Quit"

switch ($choice.ToUpper()) {
    "1" {
        Write-Host "📥 Opening Docker Desktop download page..." -ForegroundColor Green
        Start-Process "https://www.docker.com/products/docker-desktop/"
        Write-Host "Please install Docker Desktop and run this script again." -ForegroundColor Yellow
    }
    "2" {
        Write-Host "🎯 Setting up demo on existing AKS cluster..." -ForegroundColor Green
        
        # Create a unique demo namespace
        $demoNamespace = "grafana-demo-$(Get-Date -Format 'MMdd-HHmm')"
        Write-Host "📁 Creating demo namespace: $demoNamespace" -ForegroundColor Cyan
        
        kubectl create namespace $demoNamespace
        
        # Deploy only Grafana (lightweight)
        Write-Host "📊 Deploying Grafana..." -ForegroundColor Cyan
        
        $grafanaYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-demo
  namespace: $demoNamespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana-demo
  template:
    metadata:
      labels:
        app: grafana-demo
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-demo-service
  namespace: $demoNamespace
spec:
  type: NodePort
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 31000
  selector:
    app: grafana-demo
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-dashboards
  namespace: $demoNamespace
data:
  dashboard.json: |
    {
      "dashboard": {
        "id": null,
        "title": "🚀 Kubernetes Demo Dashboard",
        "tags": ["demo", "interview"],
        "panels": [
          {
            "id": 1,
            "title": "Demo Panel",
            "type": "text",
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
            "options": {
              "content": "# Welcome to Grafana Demo\n\nThis is a demonstration dashboard showing:\n- Kubernetes monitoring capabilities\n- Custom dashboard creation\n- Infrastructure as Code\n- DevOps best practices\n\n**Status: Running on AKS cluster**"
            }
          }
        ]
      }
    }
"@
        
        $grafanaYaml | Out-File -FilePath "C:\temp\grafana-demo.yaml" -Encoding UTF8
        kubectl apply -f "C:\temp\grafana-demo.yaml"
        
        # Wait for deployment
        Write-Host "⏳ Waiting for Grafana to be ready..." -ForegroundColor Cyan
        kubectl wait --for=condition=available --timeout=300s deployment/grafana-demo -n $demoNamespace
        
        # Get access information
        Write-Host ""
        Write-Host "✅ Demo Grafana deployed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎯 Access Information:" -ForegroundColor Yellow
        Write-Host "   Port Forward: kubectl port-forward -n $demoNamespace svc/grafana-demo-service 3000:3000" -ForegroundColor Cyan
        Write-Host "   Then visit: http://localhost:3000" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "👤 Login Credentials:" -ForegroundColor Yellow
        Write-Host "   Username: admin" -ForegroundColor Cyan
        Write-Host "   Password: admin123" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "🚀 Quick Access Command:" -ForegroundColor Yellow
        Write-Host "   kubectl port-forward -n $demoNamespace svc/grafana-demo-service 3000:3000" -ForegroundColor Green
        
        # Show current status
        kubectl get pods -n $demoNamespace
        kubectl get svc -n $demoNamespace
    }
    default {
        Write-Host "👋 Goodbye!" -ForegroundColor Green
    }
}