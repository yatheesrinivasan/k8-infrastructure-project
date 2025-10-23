# Docker Desktop Startup and Grafana Deployment
Write-Host "🚀 Starting Docker Desktop and Grafana Demo" -ForegroundColor Green

# Function to check if Docker is ready
function Test-DockerReady {
    try {
        $result = docker version 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# Start Docker Desktop if not running
Write-Host "📦 Ensuring Docker Desktop is running..." -ForegroundColor Cyan

$dockerProcesses = Get-Process -Name "*Docker*" -ErrorAction SilentlyContinue
if ($dockerProcesses.Count -eq 0) {
    Write-Host "🔄 Starting Docker Desktop..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -WindowStyle Minimized
}

# Wait for Docker to be ready (up to 3 minutes)
Write-Host "⏳ Waiting for Docker to be ready..." -ForegroundColor Cyan
$timeout = 0
$maxWait = 180 # 3 minutes

do {
    if (Test-DockerReady) {
        Write-Host "✅ Docker is ready!" -ForegroundColor Green
        break
    }
    
    Start-Sleep -Seconds 10
    $timeout += 10
    $minutes = [math]::Floor($timeout / 60)
    $seconds = $timeout % 60
    Write-Host "⏳ Still waiting... ($minutes`:$($seconds.ToString('00')) / 3:00)" -ForegroundColor Yellow
    
    # Show Docker processes for debugging
    if ($timeout % 30 -eq 0) {
        $dockerProcs = Get-Process -Name "*Docker*" -ErrorAction SilentlyContinue | Select-Object Name, CPU
        Write-Host "📊 Docker processes: $($dockerProcs.Count) running" -ForegroundColor Gray
    }
    
} while ($timeout -lt $maxWait)

if ($timeout -ge $maxWait) {
    Write-Host "❌ Docker did not start within 3 minutes" -ForegroundColor Red
    Write-Host "💡 Please try manually:" -ForegroundColor Yellow
    Write-Host "   1. Open Docker Desktop from Start Menu" -ForegroundColor Cyan
    Write-Host "   2. Wait for 'Engine running' status" -ForegroundColor Cyan
    Write-Host "   3. Run this script again" -ForegroundColor Cyan
    exit 1
}

# Now deploy Grafana
Write-Host ""
Write-Host "📊 Deploying Grafana Demo Container..." -ForegroundColor Cyan

# Clean up any existing demo
Write-Host "🧹 Cleaning up previous demo..." -ForegroundColor Yellow
docker stop grafana-demo 2>$null
docker rm grafana-demo 2>$null

# Start Grafana container
Write-Host "🚀 Starting new Grafana demo..." -ForegroundColor Cyan
$dockerRun = docker run -d `
  --name grafana-demo `
  --restart unless-stopped `
  -p 3000:3000 `
  -e GF_SECURITY_ADMIN_PASSWORD=admin123 `
  -e GF_USERS_ALLOW_SIGN_UP=false `
  -e GF_INSTALL_PLUGINS=grafana-kubernetes-app `
  grafana/grafana:latest

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Grafana container started: $dockerRun" -ForegroundColor Green
    
    # Wait for Grafana to be ready
    Write-Host "⏳ Waiting for Grafana to initialize..." -ForegroundColor Cyan
    Start-Sleep -Seconds 30
    
    $grafanaReady = $false
    for ($i = 0; $i -lt 12; $i++) {  # Try for 2 minutes
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -TimeoutSec 5 -UseBasicParsing 2>$null
            if ($response.StatusCode -eq 200) {
                $grafanaReady = $true
                break
            }
        } catch {}
        Start-Sleep -Seconds 10
        Write-Host "⏳ Still initializing... ($((($i+1)*10)) seconds)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    if ($grafanaReady) {
        Write-Host "🎉 Grafana Demo is Ready!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🌐 Access Information:" -ForegroundColor Yellow
        Write-Host "   URL: http://localhost:3000" -ForegroundColor Cyan
        Write-Host "   Username: admin" -ForegroundColor White
        Write-Host "   Password: admin123" -ForegroundColor White
        Write-Host ""
        Write-Host "📊 Features Available:" -ForegroundColor Yellow
        Write-Host "   • Dashboard creation and management" -ForegroundColor Cyan
        Write-Host "   • Data source configuration" -ForegroundColor Cyan
        Write-Host "   • Kubernetes monitoring capabilities" -ForegroundColor Cyan
        Write-Host "   • Custom visualization panels" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "🛠️ Container Management:" -ForegroundColor Yellow
        Write-Host "   View logs: docker logs grafana-demo" -ForegroundColor Cyan
        Write-Host "   Stop demo: docker stop grafana-demo" -ForegroundColor Cyan
        Write-Host "   Start demo: docker start grafana-demo" -ForegroundColor Cyan
        Write-Host "   Remove demo: docker rm -f grafana-demo" -ForegroundColor Cyan
        
        # Show container status
        Write-Host ""
        Write-Host "📋 Container Status:" -ForegroundColor Yellow
        docker ps --filter name=grafana-demo --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Try to open browser
        Write-Host ""
        try {
            Start-Process "http://localhost:3000"
            Write-Host "🌐 Browser opened automatically!" -ForegroundColor Green
        } catch {
            Write-Host "💡 Please open http://localhost:3000 in your browser" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "⚠️ Grafana started but may still be initializing" -ForegroundColor Yellow
        Write-Host "💡 Try accessing http://localhost:3000 in a few minutes" -ForegroundColor Cyan
    }
    
} else {
    Write-Host "❌ Failed to start Grafana container" -ForegroundColor Red
    Write-Host "🔍 Checking Docker status..." -ForegroundColor Yellow
    docker version
}

Write-Host ""
Write-Host "✨ Demo deployment complete!" -ForegroundColor Green