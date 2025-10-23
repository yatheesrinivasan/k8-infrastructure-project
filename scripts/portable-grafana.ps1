# Portable Grafana Setup Script
# Downloads and runs Grafana directly without Docker or installation

Write-Host "🚀 Setting up Portable Grafana Demo" -ForegroundColor Green
Write-Host "This requires no installation or CSG resources!" -ForegroundColor Cyan

$demoDir = "C:\temp\grafana-portable"
$grafanaDir = "$demoDir\grafana"

# Create demo directory
Write-Host "📁 Creating demo directory..." -ForegroundColor Yellow
if (!(Test-Path $demoDir)) {
    New-Item -ItemType Directory -Path $demoDir -Force
}

# Download Grafana portable
Write-Host "⬇️ Downloading Grafana portable..." -ForegroundColor Cyan
$grafanaUrl = "https://dl.grafana.com/oss/release/grafana-10.2.0.windows-amd64.zip"
$grafanaZip = "$demoDir\grafana.zip"

if (!(Test-Path "$grafanaDir\bin\grafana-server.exe")) {
    try {
        Invoke-WebRequest -Uri $grafanaUrl -OutFile $grafanaZip -UseBasicParsing
        Write-Host "📦 Extracting Grafana..." -ForegroundColor Yellow
        
        Expand-Archive -Path $grafanaZip -DestinationPath $demoDir -Force
        
        # Find the extracted folder and rename it
        $extractedFolder = Get-ChildItem -Path $demoDir -Directory | Where-Object { $_.Name -like "grafana-*" }
        if ($extractedFolder) {
            Rename-Item -Path $extractedFolder.FullName -NewName "grafana"
        }
        
        Remove-Item $grafanaZip -Force
        Write-Host "✅ Grafana extracted successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download Grafana: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Create custom configuration
Write-Host "⚙️ Creating demo configuration..." -ForegroundColor Cyan
$configContent = @"
[server]
http_port = 3000
domain = localhost

[security]
admin_user = admin
admin_password = admin123
allow_sign_up = false

[users]
allow_sign_up = false
default_theme = dark

[dashboards]
default_home_dashboard_path = /var/lib/grafana/dashboards/demo-dashboard.json

[plugins]
allow_loading_unsigned_plugins = true
"@

$configDir = "$grafanaDir\conf"
if (!(Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force
}

$configContent | Out-File -FilePath "$configDir\custom.ini" -Encoding UTF8

# Create demo dashboard
Write-Host "📊 Creating demo dashboard..." -ForegroundColor Cyan
$dashboardsDir = "$grafanaDir\data\dashboards"
if (!(Test-Path $dashboardsDir)) {
    New-Item -ItemType Directory -Path $dashboardsDir -Force
}

$demoDashboard = @"
{
  "dashboard": {
    "id": null,
    "title": "🚀 Kubernetes Infrastructure Demo",
    "tags": ["demo", "kubernetes", "infrastructure", "portfolio"],
    "timezone": "browser",
    "refresh": "30s",
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "panels": [
      {
        "id": 1,
        "title": "Infrastructure Overview",
        "type": "text",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "options": {
          "content": "# 🏗️ Multi-Cloud Kubernetes Infrastructure\n\n## Architecture Highlights:\n- **AWS EKS** + **GCP GKE** + **Azure AKS**\n- **Terraform** Infrastructure as Code\n- **Helm** Chart Deployments\n- **Istio** Service Mesh\n- **Gatekeeper** Policy Management\n\n## Monitoring Stack:\n- ✅ Prometheus Metrics Collection\n- ✅ Grafana Visualization\n- ✅ Custom Dashboards\n- ✅ Alert Manager Integration"
        }
      },
      {
        "id": 2,
        "title": "Technical Skills Showcase",
        "type": "text",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "options": {
          "content": "# 💼 DevOps & Cloud Skills\n\n## Container Orchestration:\n- Kubernetes cluster management\n- Multi-cloud deployments\n- Resource optimization\n\n## Infrastructure as Code:\n- Terraform modules\n- Automated provisioning\n- Environment management\n\n## Monitoring & Observability:\n- Custom dashboard creation\n- Metric collection & analysis\n- Proactive alerting\n\n## Security & Compliance:\n- Policy enforcement\n- Network security\n- Access control"
        }
      },
      {
        "id": 3,
        "title": "Project Statistics",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 8},
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
        "targets": [{"expr": "15", "legendFormat": "Components"}]
      },
      {
        "id": 4,
        "title": "Cloud Providers",
        "type": "stat", 
        "gridPos": {"h": 4, "w": 6, "x": 6, "y": 8},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "fixed", "fixedColor": "blue"},
            "unit": "short"
          }
        },
        "targets": [{"expr": "3", "legendFormat": "Clouds"}]
      },
      {
        "id": 5,
        "title": "Terraform Modules",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 12, "y": 8},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "fixed", "fixedColor": "purple"},
            "unit": "short"
          }
        },
        "targets": [{"expr": "4", "legendFormat": "Modules"}]
      },
      {
        "id": 6,
        "title": "Demo Status",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 18, "y": 8},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "fixed", "fixedColor": "orange"},
            "unit": "percent"
          }
        },
        "targets": [{"expr": "100", "legendFormat": "Active"}]
      }
    ]
  }
}
"@

$demoDashboard | Out-File -FilePath "$dashboardsDir\demo-dashboard.json" -Encoding UTF8

# Start Grafana
Write-Host "🚀 Starting Grafana server..." -ForegroundColor Green
Write-Host ""
Write-Host "📊 Starting portable Grafana demo..." -ForegroundColor Yellow
Write-Host "🌐 This will open at: http://localhost:3000" -ForegroundColor Cyan
Write-Host "👤 Username: admin" -ForegroundColor White
Write-Host "🔑 Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Change to Grafana directory and start server
Set-Location $grafanaDir

try {
    # Try to open browser after a delay
    Start-Job -ScriptBlock {
        Start-Sleep -Seconds 10
        Start-Process "http://localhost:3000"
    } | Out-Null
    
    # Start Grafana server
    .\bin\grafana-server.exe --config="$configDir\custom.ini"
} catch {
    Write-Host "❌ Failed to start Grafana: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Grafana demo session completed!" -ForegroundColor Green