# Quick script to upgrade AWS CDK CLI to latest version

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "AWS CDK CLI Upgrade" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check current version
try {
    $currentVersion = cdk --version 2>&1
    Write-Host "Current CDK version: $currentVersion" -ForegroundColor Gray
} catch {
    Write-Host "CDK is not currently installed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Upgrading to latest version..." -ForegroundColor Yellow
npm install -g aws-cdk@latest

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
$newVersion = cdk --version 2>&1
Write-Host "✅ CDK upgraded successfully!" -ForegroundColor Green
Write-Host "New version: $newVersion" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
