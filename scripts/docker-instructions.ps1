# Manual Docker Grafana Setup Instructions
# Since Docker Desktop is still starting, here are manual steps

Write-Host "🚀 Manual Grafana Demo Setup Instructions" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Prerequisites Check:" -ForegroundColor Yellow
Write-Host "✅ Docker Desktop is installed" -ForegroundColor Green
Write-Host "🔄 Docker Desktop is starting up..." -ForegroundColor Yellow
Write-Host ""

Write-Host "⏳ Please wait for Docker Desktop to fully start, then run these commands:" -ForegroundColor Cyan
Write-Host ""

Write-Host "1️⃣ Test Docker is ready:" -ForegroundColor Yellow
Write-Host "   docker ps" -ForegroundColor Cyan
Write-Host ""

Write-Host "2️⃣ Start Grafana demo container:" -ForegroundColor Yellow
Write-Host "   docker run -d --name grafana-demo --restart unless-stopped -p 3000:3000 -e GF_SECURITY_ADMIN_PASSWORD=admin123 -e GF_USERS_ALLOW_SIGN_UP=false grafana/grafana:latest" -ForegroundColor Cyan
Write-Host ""

Write-Host "3️⃣ Wait for Grafana to start (30-60 seconds)" -ForegroundColor Yellow
Write-Host ""

Write-Host "4️⃣ Access Grafana:" -ForegroundColor Yellow
Write-Host "   URL: http://localhost:3000" -ForegroundColor Cyan
Write-Host "   Username: admin" -ForegroundColor Cyan
Write-Host "   Password: admin123" -ForegroundColor Cyan
Write-Host ""

Write-Host "🛠️ Management commands:" -ForegroundColor Yellow
Write-Host "   Check status: docker ps" -ForegroundColor Cyan
Write-Host "   Stop demo:    docker stop grafana-demo" -ForegroundColor Cyan
Write-Host "   Start demo:   docker start grafana-demo" -ForegroundColor Cyan
Write-Host "   Remove demo:  docker rm -f grafana-demo" -ForegroundColor Cyan
Write-Host ""

Write-Host "💡 Tip: You can also use Docker Desktop GUI to manage containers" -ForegroundColor Green

# Create a ready-to-use script for when Docker is ready
$quickStartScript = @'
Write-Host "🚀 Quick Grafana Demo Startup" -ForegroundColor Green

# Check if Docker is ready
try {
    docker ps > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker is not ready yet. Please wait for Docker Desktop to fully start." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Docker is ready!" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not ready yet. Please wait for Docker Desktop to fully start." -ForegroundColor Red
    exit 1
}

# Clean up any existing demo
Write-Host "🧹 Cleaning up previous demo..." -ForegroundColor Cyan
docker stop grafana-demo 2>$null
docker rm grafana-demo 2>$null

# Start new Grafana demo
Write-Host "📊 Starting Grafana demo..." -ForegroundColor Cyan
docker run -d `
  --name grafana-demo `
  --restart unless-stopped `
  -p 3000:3000 `
  -e GF_SECURITY_ADMIN_PASSWORD=admin123 `
  -e GF_USERS_ALLOW_SIGN_UP=false `
  grafana/grafana:latest

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Grafana demo started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Access Information:" -ForegroundColor Yellow
    Write-Host "   URL: http://localhost:3000" -ForegroundColor Cyan
    Write-Host "   Username: admin" -ForegroundColor Cyan
    Write-Host "   Password: admin123" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⏳ Please wait 30-60 seconds for Grafana to fully start" -ForegroundColor Yellow
    Write-Host ""
    
    # Try to open browser
    try {
        Start-Process "http://localhost:3000"
        Write-Host "🌐 Browser opened automatically" -ForegroundColor Green
    } catch {
        Write-Host "💡 Please open http://localhost:3000 manually" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "📋 Container Status:" -ForegroundColor Yellow
    docker ps --filter name=grafana-demo
} else {
    Write-Host "❌ Failed to start Grafana demo" -ForegroundColor Red
}
'@

$quickStartScript | Out-File -FilePath "C:\temp\k8s-infrastructure-project\scripts\quick-grafana.ps1" -Encoding UTF8

Write-Host ""
Write-Host "📄 Created quick start script: scripts\quick-grafana.ps1" -ForegroundColor Green
Write-Host "Run it when Docker Desktop is fully ready!" -ForegroundColor Yellow