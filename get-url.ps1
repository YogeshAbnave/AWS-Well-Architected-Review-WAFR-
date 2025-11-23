# Get WAFR Application URL
$stackName = "WellArchitectedReviewUsingGenAIStack"
$region = "us-east-1"

Write-Host "Checking stack status..." -ForegroundColor Cyan

try {
    $outputs = aws cloudformation describe-stacks --stack-name $stackName --region $region --query "Stacks[0].Outputs" --output json | ConvertFrom-Json
    
    Write-Host ""
    Write-Host "=== WAFR Accelerator URLs ===" -ForegroundColor Green
    Write-Host ""
    
    foreach ($output in $outputs) {
        if ($output.OutputKey -eq "CloudFrontURL") {
            Write-Host "CloudFront URL (PRIMARY):" -ForegroundColor Green
            Write-Host $output.OutputValue -ForegroundColor White
            Write-Host ""
        }
        elseif ($output.OutputKey -eq "ALB-DNS") {
            Write-Host "ALB URL:" -ForegroundColor Yellow
            Write-Host $output.OutputValue -ForegroundColor White
            Write-Host ""
        }
    }
    
    Write-Host "Note: If CloudFront shows an error, wait 15-20 minutes for propagation" -ForegroundColor Yellow
    
} catch {
    Write-Host "Could not get stack outputs. Stack may still be deploying." -ForegroundColor Red
    Write-Host "Run: aws cloudformation describe-stacks --stack-name $stackName --region $region" -ForegroundColor Yellow
}
