# IMMEDIATE FIX - Deploy WAFR Application
$stackName = "WellArchitectedReviewUsingGenAIStack"
$region = "us-east-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYING WAFR APPLICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check current stack status
Write-Host "Checking stack status..." -ForegroundColor Yellow
$status = aws cloudformation describe-stacks --stack-name $stackName --region $region --query "Stacks[0].StackStatus" --output text 2>&1

if ($status -like "*ROLLBACK_COMPLETE*" -or $status -like "*UPDATE_ROLLBACK_COMPLETE*") {
    Write-Host "Stack is in rollback state. Deleting..." -ForegroundColor Yellow
    aws cloudformation delete-stack --stack-name $stackName --region $region
    
    Write-Host "Waiting for stack deletion (this may take 5-10 minutes)..." -ForegroundColor Yellow
    aws cloudformation wait stack-delete-complete --stack-name $stackName --region $region
    Write-Host "Stack deleted successfully!" -ForegroundColor Green
    Write-Host ""
}

# Deploy the stack
Write-Host "Deploying stack with all fixes..." -ForegroundColor Green
Write-Host "This will take approximately 10-15 minutes" -ForegroundColor Yellow
Write-Host ""

cd AWS-Well-Architected-Review-WAFR-
cdk deploy --require-approval never

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment initiated!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "After deployment completes, run:" -ForegroundColor Yellow
Write-Host "  .\get-url.ps1" -ForegroundColor White
Write-Host ""
