# Simple Docker check test
Write-Host "Testing Docker check..." -ForegroundColor Cyan

try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
        
        $null = docker info 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker daemon is running" -ForegroundColor Green
        } else {
            Write-Host "❌ Docker daemon is not running" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Docker is not installed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Docker check failed: $_" -ForegroundColor Red
}
