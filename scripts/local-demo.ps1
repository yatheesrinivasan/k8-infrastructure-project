#!/usr/bin/env pwsh
# Local Grafana Dashboard Demo Script
# Deploys monitoring stack directly with Helm (no Terraform needed)

param(
    [Parameter()]
    [ValidateSet("deploy", "cleanup", "port-forward", "status")]
    [string]$Action = "deploy"
)

$MonitoringNamespace = "demo-monitoring"

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Test-Prerequisites {
    Write-Info "Checking prerequisites for local deployment..."
    
    # Check kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        throw "kubectl not found. Please install kubectl."
    }
    
    # Check helm  
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        throw "helm not found. Please install helm."
    }
    
    # Check if we can connect to any cluster
    try {
        $null = kubectl cluster-info --request-timeout=5s 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "No accessible Kubernetes cluster found."
            Write-Info "Options for local development:"
            Write-Info "1. Install Docker Desktop with Kubernetes enabled"
            Write-Info "2. Install minikube: choco install minikube"
            Write-Info "3. Install kind: choco install kind"
            Write-Info "4. Use online Kubernetes playground: https://labs.play-with-k8s.com/"
            throw "No Kubernetes cluster available"
        }
    }
    catch {
        throw "Cannot connect to Kubernetes cluster: $_"
    }
    
    Write-Info "Prerequisites satisfied."
}

function Deploy-LocalMonitoring {
    Write-Info "Deploying local monitoring stack for dashboard demo..."
    
    # Create namespace
    Write-Info "Creating monitoring namespace..."
    kubectl create namespace $MonitoringNamespace --dry-run=client -o yaml | kubectl apply -f -
    
    # Add Helm repositories
    Write-Info "Adding Helm repositories..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
    helm repo update
    
    # Deploy Prometheus + Grafana stack
    Write-Info "Deploying Prometheus + Grafana stack..."
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
        --namespace $MonitoringNamespace `
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false `
        --set prometheus.prometheusSpec.retention=7d `
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=5Gi `
        --set grafana.adminPassword=admin123 `
        --set grafana.service.type=ClusterIP `
        --set grafana.persistence.enabled=true `
        --set grafana.persistence.size=2Gi `
        --set alertmanager.enabled=true `
        --wait --timeout=10m
    
    # Deploy Jaeger for tracing
    Write-Info "Deploying Jaeger tracing..."
    kubectl create namespace demo-observability --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install jaeger jaegertracing/jaeger `
        --namespace demo-observability `
        --set provisionDataStore.cassandra=false `
        --set storage.type=memory `
        --set agent.enabled=false `
        --set collector.enabled=true `
        --set query.enabled=true `
        --wait --timeout=5m
    
    # Deploy custom dashboards via ConfigMap
    Write-Info "Deploying custom dashboards..."
    Deploy-CustomDashboards
    
    Write-Info "✅ Local monitoring stack deployed successfully!"
    Write-Info ""
    Write-Info "🎯 Access Instructions:"
    Write-Info "Run: .\scripts\local-demo.ps1 port-forward"
    Write-Info "Then open: http://localhost:3000"
    Write-Info "Credentials: admin / admin123"
}

function Deploy-CustomDashboards {
    # Create ConfigMap with our custom dashboards
    $dashboardConfigMap = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-dashboards
  namespace: $MonitoringNamespace
  labels:
    grafana_dashboard: "1"
data:
  demo-overview.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Local Demo - Kubernetes Overview",
        "tags": ["demo", "kubernetes", "local"],
        "style": "dark",
        "timezone": "browser",
        "refresh": "30s",
        "time": {"from": "now-1h", "to": "now"},
        "panels": [
          {
            "id": 1,
            "title": "Cluster Nodes",
            "type": "stat",
            "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0},
            "targets": [{"expr": "count(kube_node_info)", "refId": "A"}],
            "fieldConfig": {"defaults": {"color": {"mode": "thresholds"}}}
          },
          {
            "id": 2,
            "title": "Running Pods",
            "type": "stat", 
            "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0},
            "targets": [{"expr": "count(kube_pod_status_phase{phase=\"Running\"})", "refId": "A"}],
            "fieldConfig": {"defaults": {"color": {"mode": "thresholds"}}}
          },
          {
            "id": 3,
            "title": "CPU Usage",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 4},
            "targets": [{"expr": "100 - (avg by(instance)(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)", "legendFormat": "{{instance}}", "refId": "A"}],
            "fieldConfig": {"defaults": {"unit": "percent", "min": 0, "max": 100}}
          },
          {
            "id": 4,
            "title": "Memory Usage",
            "type": "timeseries", 
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 4},
            "targets": [{"expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100", "legendFormat": "{{instance}}", "refId": "A"}],
            "fieldConfig": {"defaults": {"unit": "percent", "min": 0, "max": 100}}
          }
        ]
      }
    }
"@

    $dashboardConfigMap | kubectl apply -f -
    
    # Restart Grafana to pick up new dashboards
    kubectl rollout restart deployment/prometheus-grafana -n $MonitoringNamespace
}

function Start-PortForward {
    Write-Info "Starting port-forward to Grafana..."
    Write-Info "🌐 Grafana will be available at: http://localhost:3000"
    Write-Info "👤 Username: admin"  
    Write-Info "🔑 Password: admin123"
    Write-Info ""
    Write-Info "Press Ctrl+C to stop port-forwarding"
    
    kubectl port-forward -n $MonitoringNamespace svc/prometheus-grafana 3000:80
}

function Get-DeploymentStatus {
    Write-Info "Checking deployment status..."
    
    Write-Host "`n=== Namespaces ===" -ForegroundColor Cyan
    kubectl get namespaces | Where-Object { $_ -match "demo-" }
    
    Write-Host "`n=== Monitoring Pods ===" -ForegroundColor Cyan  
    kubectl get pods -n $MonitoringNamespace
    
    Write-Host "`n=== Observability Pods ===" -ForegroundColor Cyan
    kubectl get pods -n demo-observability
    
    Write-Host "`n=== Services ===" -ForegroundColor Cyan
    kubectl get svc -n $MonitoringNamespace | Where-Object { $_ -match "grafana|prometheus" }
    
    Write-Host "`n=== Custom Dashboards ===" -ForegroundColor Cyan
    kubectl get configmap -n $MonitoringNamespace | Where-Object { $_ -match "dashboard" }
}

function Remove-LocalMonitoring {
    Write-Warn "Removing local monitoring deployment..."
    
    $confirm = Read-Host "Are you sure you want to remove the demo monitoring stack? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Info "Cleanup cancelled."
        return
    }
    
    # Remove Helm releases
    helm uninstall prometheus -n $MonitoringNamespace 2>$null
    helm uninstall jaeger -n demo-observability 2>$null
    
    # Remove namespaces
    kubectl delete namespace $MonitoringNamespace --ignore-not-found=true
    kubectl delete namespace demo-observability --ignore-not-found=true
    
    Write-Info "✅ Cleanup completed."
}

# Main execution
try {
    switch ($Action) {
        "deploy" {
            Test-Prerequisites
            Deploy-LocalMonitoring
        }
        "port-forward" {
            Start-PortForward
        }
        "status" {
            Get-DeploymentStatus  
        }
        "cleanup" {
            Remove-LocalMonitoring
        }
        default {
            Write-Host "Local Grafana Dashboard Demo" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Usage: .\scripts\local-demo.ps1 <action>"
            Write-Host ""
            Write-Host "Actions:"
            Write-Host "  deploy      - Deploy monitoring stack locally"
            Write-Host "  port-forward - Start port-forward to access Grafana"  
            Write-Host "  status      - Check deployment status"
            Write-Host "  cleanup     - Remove demo deployment"
            Write-Host ""
            Write-Host "Example:"
            Write-Host "  .\scripts\local-demo.ps1 deploy"
            Write-Host "  .\scripts\local-demo.ps1 port-forward"
        }
    }
}
catch {
    Write-Error "Script failed: $($_.Exception.Message)"
    exit 1
}