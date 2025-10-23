# Simple Docker-only Grafana Demo Setup
# This creates a standalone Grafana container for demo purposes

Write-Host "🚀 Starting Simple Grafana Demo (Docker-only)" -ForegroundColor Green
Write-Host "Creating isolated demo environment..." -ForegroundColor Cyan

# Wait for Docker to be fully ready
Write-Host "⏳ Waiting for Docker Desktop to be ready..." -ForegroundColor Cyan
$timeout = 0
$maxTimeout = 60
do {
    try {
        docker ps > $null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker is ready!" -ForegroundColor Green
            break
        }
    } catch {}
    
    Start-Sleep -Seconds 5
    $timeout += 5
    Write-Host "⏳ Still waiting... ($timeout/$maxTimeout seconds)" -ForegroundColor Yellow
} while ($timeout -lt $maxTimeout)

if ($timeout -ge $maxTimeout) {
    Write-Host "❌ Docker Desktop did not start in time. Please:" -ForegroundColor Red
    Write-Host "1. Open Docker Desktop manually" -ForegroundColor Yellow
    Write-Host "2. Wait for it to fully start" -ForegroundColor Yellow
    Write-Host "3. Run this script again" -ForegroundColor Yellow
    exit 1
}

# Stop any existing Grafana demo containers
Write-Host "🧹 Cleaning up any existing demo containers..." -ForegroundColor Cyan
docker stop grafana-demo 2>$null
docker rm grafana-demo 2>$null

# Create demo directory for configuration
$demoDir = "C:\temp\grafana-demo"
if (!(Test-Path $demoDir)) {
    New-Item -ItemType Directory -Path $demoDir -Force
}

# Create custom dashboard configuration
$dashboardConfig = @"
{
  "dashboard": {
    "id": null,
    "title": "🚀 Kubernetes Infrastructure Demo",
    "tags": ["demo", "kubernetes", "infrastructure"],
    "timezone": "browser",
    "refresh": "30s",
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "panels": [
      {
        "id": 1,
        "title": "Welcome to Infrastructure Demo",
        "type": "text",
        "gridPos": {"h": 6, "w": 24, "x": 0, "y": 0},
        "options": {
          "content": "# 🚀 Kubernetes Infrastructure Project\n\n## Key Features Demonstrated:\n- **Multi-Cloud Kubernetes Architecture** (AWS EKS, GCP GKE, Azure AKS)\n- **Infrastructure as Code** with Terraform\n- **Monitoring & Observability** with Grafana + Prometheus\n- **Security Policies** with Gatekeeper & Istio\n- **Automated Deployment** with Helm Charts\n\n## 💼 **Skills Showcased:**\n- Container Orchestration\n- DevOps Best Practices\n- Cloud-Native Architecture\n- Monitoring & Alerting\n- Security & Compliance\n\n## 📊 **Dashboard Capabilities:**\n- Real-time metrics visualization\n- Custom alerting rules\n- Multi-cloud cost optimization\n- Performance monitoring\n\n**Status:** ✅ Demo Environment Active"
        }
      },
      {
        "id": 2,
        "title": "Demo Statistics",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 6},
        "options": {
          "textMode": "auto",
          "colorMode": "background"
        },
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "fixed", "fixedColor": "green"},
            "unit": "short"
          }
        },
        "targets": [
          {
            "expr": "1",
            "legendFormat": "Demo Active"
          }
        ]
      },
      {
        "id": 3,
        "title": "Infrastructure Components",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 6, "y": 6},
        "options": {
          "textMode": "auto",
          "colorMode": "background"
        },
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "fixed", "fixedColor": "blue"},
            "unit": "short"
          }
        },
        "targets": [
          {
            "expr": "15",
            "legendFormat": "Components"
          }
        ]
      },
      {
        "id": 4,
        "title": "Cloud Providers",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 12, "y": 6},
        "options": {
          "textMode": "auto",
          "colorMode": "background"
        },
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "fixed", "fixedColor": "purple"},
            "unit": "short"
          }
        },
        "targets": [
          {
            "expr": "3",
            "legendFormat": "Clouds"
          }
        ]
      },
      {
        "id": 5,
        "title": "Demo Uptime",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 18, "y": 6},
        "options": {
          "textMode": "auto",
          "colorMode": "background"
        },
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "fixed", "fixedColor": "orange"},
            "unit": "percent"
          }
        },
        "targets": [
          {
            "expr": "100",
            "legendFormat": "Uptime %"
          }
        ]
      }
    ]
  }
}
"@

$dashboardConfig | Out-File -FilePath "$demoDir\demo-dashboard.json" -Encoding UTF8

# Start Grafana container with demo configuration
Write-Host "📊 Starting Grafana demo container..." -ForegroundColor Cyan

docker run -d `
  --name grafana-demo `
  --restart unless-stopped `
  -p 3000:3000 `
  -e GF_SECURITY_ADMIN_PASSWORD=admin123 `
  -e GF_USERS_ALLOW_SIGN_UP=false `
  -e GF_SECURITY_ALLOW_EMBEDDING=true `
  -v "${demoDir}:/var/lib/grafana/dashboards" `
  grafana/grafana:latest

# Wait for Grafana to start
Write-Host "⏳ Waiting for Grafana to start..." -ForegroundColor Cyan
$timeout = 0
do {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -TimeoutSec 2 -UseBasicParsing 2>$null
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Grafana is ready!" -ForegroundColor Green
            break
        }
    } catch {}
    
    Start-Sleep -Seconds 3
    $timeout += 3
    Write-Host "⏳ Still starting... ($timeout/60 seconds)" -ForegroundColor Yellow
} while ($timeout -lt 60)

Write-Host ""
Write-Host "✅ Grafana Demo Environment Ready!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Access Information:" -ForegroundColor Yellow
Write-Host "   URL: http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "👤 Login Credentials:" -ForegroundColor Yellow
Write-Host "   Username: admin" -ForegroundColor Cyan
Write-Host "   Password: admin123" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Demo Features:" -ForegroundColor Yellow
Write-Host "   • Infrastructure overview dashboard" -ForegroundColor Cyan
Write-Host "   • Kubernetes architecture demonstration" -ForegroundColor Cyan
Write-Host "   • Multi-cloud capabilities showcase" -ForegroundColor Cyan
Write-Host "   • DevOps best practices display" -ForegroundColor Cyan
Write-Host ""
Write-Host "🛠️ Management:" -ForegroundColor Yellow
Write-Host "   Stop demo:    docker stop grafana-demo" -ForegroundColor Cyan
Write-Host "   Start demo:   docker start grafana-demo" -ForegroundColor Cyan
Write-Host "   Remove demo:  docker rm -f grafana-demo" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Open http://localhost:3000 in your browser!" -ForegroundColor Green

# Open browser automatically
try {
    Start-Process "http://localhost:3000"
    Write-Host "🌐 Browser opened automatically" -ForegroundColor Green
} catch {
    Write-Host "💡 Please open http://localhost:3000 manually" -ForegroundColor Yellow
}

# Show container status
Write-Host ""
Write-Host "📋 Container Status:" -ForegroundColor Yellow
docker ps --filter name=grafana-demo --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"