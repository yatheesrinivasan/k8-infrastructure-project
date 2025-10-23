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
