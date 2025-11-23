#!/usr/bin/env pwsh
# Get WAFR Accelerator Application URL

$stackName = "WellArchitectedReviewUsingGenAIStack"
$region = "us-east-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WAFR Accelerator - Get Application URL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check stack status
Write-Host "Checking stack status..." -ForegroundColor Yellow
$status = aws cloudformation describe-stacks --stack-name $stackName --region $region --query "Stacks[0].StackStatus" --output text 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Could not find stack '$stackName'" -ForegroundColor Red
    Write-Host "The stack may not exist yet. Please deploy first:" -ForegroundColor Yellow
    Write-Host "  cd AWS-Well-Architected-Review-WAFR-" -ForegroundColor White
    Write-Host "  cdk deploy" -ForegroundColor White
    exit 1
}

Write-Host "Stack Status: $status" -ForegroundColor Green
Write-Host ""

# Check if stack is in a good state
$goodStates = @("CREATE_COMPLETE", "UPDATE_COMPLETE")
$inProgressStates = @("CREATE_IN_PROGRESS", "UPDATE_IN_PROGRESS", "UPDATE_COMPLETE_CLEANUP_IN_PROGRESS")
$failedStates = @("CREATE_FAILED", "UPDATE_FAILED", "ROLLBACK_COMPLETE", "UPDATE_ROLLBACK_COMPLETE", "ROLLBACK_FAILED", "UPDATE_ROLLBACK_FAILED")

if ($goodStates -contains $status) {
    Write-Host "✓ Stack deployment successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Application URLs:" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    # Get outputs
    $outputs = aws cloudformation describe-stacks --stack-name $stackName --region $region --query "Stacks[0].Outputs" --output json | ConvertFrom-Json
    
    foreach ($output in $outputs) {
        $key = $output.OutputKey
        $value = $output.OutputValue
        $desc = $output.Description
        
        if ($key -eq "CloudFrontURL") {
            Write-Host ""
            Write-Host "PRIMARY URL (CloudFront):" -ForegroundColor Green
            Write-Host "   $value" -ForegroundColor White
            Write-Host "   $desc" -ForegroundColor Gray
            Write-Host ""
            Write-Host "   Note: CloudFront may take 15-20 minutes to fully propagate" -ForegroundColor Yellow
        } elseif ($key -eq "ALB-DNS") {
            Write-Host ""
            Write-Host "ALB URL (for troubleshooting):" -ForegroundColor Yellow
            Write-Host "   $value" -ForegroundColor White
            Write-Host "   $desc" -ForegroundColor Gray
        } elseif ($key -eq "FrontEnd-EC2-Instance-Id") {
            Write-Host ""
            Write-Host "EC2 Instance ID:" -ForegroundColor Cyan
            Write-Host "   $value" -ForegroundColor White
        } elseif ($key -eq "FrontEnd-EC2-Public-IP") {
            Write-Host ""
            Write-Host "EC2 Direct Access:" -ForegroundColor Cyan
            Write-Host "   http://${value}:8501" -ForegroundColor White
            Write-Host "   (Not recommended - use CloudFront URL instead)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Next Steps:" -ForegroundColor Green
    Write-Host "1. Open the CloudFront URL in your browser" -ForegroundColor White
    Write-Host "2. If you get an error, wait a few minutes for CloudFront to propagate" -ForegroundColor White
    Write-Host "3. Check application logs if needed:" -ForegroundColor White
    Write-Host "   aws logs tail /aws/ec2/wafr-streamlit --follow --region $region" -ForegroundColor Gray
    Write-Host ""
} elseif ($inProgressStates -contains $status) {
    Write-Host "Stack is still deploying..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Current Status: $status" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please wait for deployment to complete. This typically takes 15-20 minutes." -ForegroundColor White
    Write-Host ""
    Write-Host "You can monitor progress with:" -ForegroundColor Cyan
    Write-Host "  aws cloudformation describe-stack-events --stack-name $stackName --region $region --max-items 10" -ForegroundColor White
    Write-Host ""
    Write-Host "Or run this script again in a few minutes:" -ForegroundColor Cyan
    Write-Host "  .\get-app-url.ps1" -ForegroundColor White
    Write-Host ""
} elseif ($failedStates -contains $status) {
    Write-Host "Stack deployment failed or rolled back" -ForegroundColor Red
    Write-Host ""
    Write-Host "Current Status: $status" -ForegroundColor Red
    Write-Host ""
    Write-Host "To troubleshoot, check recent events:" -ForegroundColor Yellow
    Write-Host "  aws cloudformation describe-stack-events --stack-name $stackName --region $region --max-items 20" -ForegroundColor White
    Write-Host ""
    Write-Host "To retry deployment:" -ForegroundColor Yellow
    Write-Host "  cd AWS-Well-Architected-Review-WAFR-" -ForegroundColor White
    Write-Host "  cdk deploy" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Stack is in unexpected state: $status" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Check stack events for more details:" -ForegroundColor White
    Write-Host "  aws cloudformation describe-stack-events --stack-name $stackName --region $region" -ForegroundColor Gray
    Write-Host ""
}
