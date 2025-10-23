# Minikube Installation and Setup Script for Windows
# This script installs Minikube and sets up the Grafana monitoring stack

Write-Host "🚀 Installing Minikube and Grafana Monitoring Stack..." -ForegroundColor Green

# Step 1: Download and install Minikube
Write-Host "📦 Downloading Minikube..." -ForegroundColor Cyan
$minikubePath = "C:\temp\minikube.exe"
try {
    Invoke-WebRequest -Uri "https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe" -OutFile $minikubePath -UseBasicParsing
    Write-Host "✅ Minikube downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download Minikube: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Add Minikube to PATH (temporary for this session)
$env:PATH += ";C:\temp"
Write-Host "✅ Minikube added to PATH" -ForegroundColor Green

# Step 3: Start Minikube cluster
Write-Host "🏗️ Starting Minikube cluster..." -ForegroundColor Cyan
try {
    & $minikubePath start --driver=docker --memory=4096 --cpus=2
    Write-Host "✅ Minikube cluster started" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Docker driver failed, trying Hyper-V..." -ForegroundColor Yellow
    try {
        & $minikubePath start --driver=hyperv --memory=4096 --cpus=2
        Write-Host "✅ Minikube cluster started with Hyper-V" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to start Minikube: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Try running: minikube start --help for more options" -ForegroundColor Yellow
        exit 1
    }
}

# Step 4: Verify cluster is running
Write-Host "🔍 Verifying cluster..." -ForegroundColor Cyan
& kubectl get nodes

# Step 5: Install Helm if not present
Write-Host "📦 Installing Helm..." -ForegroundColor Cyan
try {
    $helmPath = "C:\temp\helm.exe"
    if (!(Test-Path $helmPath)) {
        Invoke-WebRequest -Uri "https://get.helm.sh/helm-v3.19.0-windows-amd64.zip" -OutFile "C:\temp\helm.zip" -UseBasicParsing
        Expand-Archive -Path "C:\temp\helm.zip" -DestinationPath "C:\temp\helm-temp" -Force
        Move-Item "C:\temp\helm-temp\windows-amd64\helm.exe" $helmPath
        Remove-Item -Recurse -Force "C:\temp\helm-temp", "C:\temp\helm.zip"
    }
    $env:PATH += ";C:\temp"
    Write-Host "✅ Helm installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install Helm: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 6: Add Helm repositories
Write-Host "📚 Adding Helm repositories..." -ForegroundColor Cyan
& helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
& helm repo add grafana https://grafana.github.io/helm-charts
& helm repo update

# Step 7: Create namespace
Write-Host "🏗️ Creating monitoring namespace..." -ForegroundColor Cyan
& kubectl create namespace demo-monitoring --dry-run=client -o yaml | kubectl apply -f -

# Step 8: Deploy Prometheus + Grafana
Write-Host "📊 Deploying Prometheus + Grafana..." -ForegroundColor Cyan
& helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
  --namespace demo-monitoring `
  --set grafana.service.type=NodePort `
  --set grafana.service.nodePort=30000 `
  --set grafana.adminPassword=admin123 `
  --set prometheus.service.type=NodePort `
  --set prometheus.service.nodePort=30001 `
  --timeout=15m `
  --wait

# Step 9: Create custom dashboard
Write-Host "🎨 Creating custom dashboard..." -ForegroundColor Cyan
$dashboardYaml = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-dashboards
  namespace: demo-monitoring
  labels:
    grafana_dashboard: "1"
data:
  kubernetes-overview.json: |
    {
      "dashboard": {
        "id": null,
        "title": "🚀 Demo - Multi-Cloud Kubernetes Overview",
        "tags": ["kubernetes", "demo", "minikube"],
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Cluster Health Status",
            "type": "stat",
            "targets": [{"expr": "up{job=\"kubernetes-apiservers\"}", "legendFormat": "API Server"}],
            "fieldConfig": {"defaults": {"color": {"mode": "thresholds"}, "thresholds": {"steps": [{"color": "red", "value": 0}, {"color": "green", "value": 1}]}}},
            "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "Total Pods",
            "type": "stat",
            "targets": [{"expr": "count(kube_pod_info)", "legendFormat": "Pods"}],
            "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0}
          },
          {
            "id": 3,
            "title": "Node Count",
            "type": "stat",
            "targets": [{"expr": "count(kube_node_info)", "legendFormat": "Nodes"}],
            "gridPos": {"h": 4, "w": 6, "x": 12, "y": 0}
          },
          {
            "id": 4,
            "title": "CPU Usage %",
            "type": "stat",
            "targets": [{"expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)", "legendFormat": "CPU"}],
            "gridPos": {"h": 4, "w": 6, "x": 18, "y": 0}
          },
          {
            "id": 5,
            "title": "Pod Status Distribution",
            "type": "piechart",
            "targets": [{"expr": "count by (phase) (kube_pod_status_phase)", "legendFormat": "{{phase}}"}],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 4}
          },
          {
            "id": 6,
            "title": "Memory Usage Trend",
            "type": "timeseries",
            "targets": [{"expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100", "legendFormat": "{{instance}}"}],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 4}
          },
          {
            "id": 7,
            "title": "Network Traffic",
            "type": "timeseries",
            "targets": [
              {"expr": "rate(node_network_receive_bytes_total[5m])", "legendFormat": "RX {{device}}"},
              {"expr": "rate(node_network_transmit_bytes_total[5m])", "legendFormat": "TX {{device}}"}
            ],
            "gridPos": {"h": 8, "w": 24, "x": 0, "y": 12}
          }
        ],
        "time": {"from": "now-1h", "to": "now"},
        "refresh": "30s"
      }
    }
"@

$dashboardYaml | Out-File -FilePath "C:\temp\dashboard.yaml" -Encoding UTF8
& kubectl apply -f "C:\temp\dashboard.yaml"

# Step 10: Wait for deployment and restart Grafana
Write-Host "⏳ Waiting for Grafana to be ready..." -ForegroundColor Cyan
& kubectl wait --for=condition=available --timeout=300s deployment/prometheus-grafana -n demo-monitoring

Write-Host "🔄 Restarting Grafana to load dashboards..." -ForegroundColor Cyan
& kubectl rollout restart deployment/prometheus-grafana -n demo-monitoring
& kubectl rollout status deployment/prometheus-grafana -n demo-monitoring --timeout=300s

# Step 11: Get Minikube IP and show access info
$minikubeIP = & minikube ip
Write-Host ""
Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Access Grafana Dashboard:" -ForegroundColor Yellow
Write-Host "   URL: http://$minikubeIP:30000" -ForegroundColor Cyan
Write-Host "   Alternative: minikube service prometheus-grafana -n demo-monitoring" -ForegroundColor Cyan
Write-Host ""
Write-Host "👤 Login Credentials:" -ForegroundColor Yellow
Write-Host "   Username: admin" -ForegroundColor Cyan
Write-Host "   Password: admin123" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Available Dashboards:" -ForegroundColor Yellow
Write-Host "   • 🚀 Demo - Multi-Cloud Kubernetes Overview (Custom)" -ForegroundColor Cyan
Write-Host "   • Kubernetes / Compute Resources / Cluster" -ForegroundColor Cyan
Write-Host "   • Kubernetes / Compute Resources / Node (Pods)" -ForegroundColor Cyan
Write-Host "   • Node Exporter / Nodes" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Quick Access Command:" -ForegroundColor Yellow
Write-Host "   minikube service prometheus-grafana -n demo-monitoring" -ForegroundColor Green

# Show services
Write-Host ""
Write-Host "📋 Services Status:" -ForegroundColor Yellow
& kubectl get svc -n demo-monitoring