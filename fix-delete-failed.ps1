# Fix DELETE_FAILED Stack State
$stackName = "WellArchitectedReviewUsingGenAIStack"
$region = "us-east-1"

Write-Host "=== Fixing DELETE_FAILED Stack ===" -ForegroundColor Cyan
Write-Host ""

# Check current state
Write-Host "Current stack state:" -ForegroundColor Yellow
aws cloudformation describe-stacks --stack-name $stackName --region $region --query "Stacks[0].StackStatus" --output text

Write-Host ""
Write-Host "Finding resources that failed to delete..." -ForegroundColor Yellow

# Get failed resources
$events = aws cloudformation describe-stack-events --stack-name $stackName --region $region --max-items 50 | ConvertFrom-Json

$failedResources = @()
foreach ($event in $events.StackEvents) {
    if ($event.ResourceStatus -eq "DELETE_FAILED") {
        $failedResources += $event
        Write-Host "  - $($event.LogicalResourceId) ($($event.ResourceType))" -ForegroundColor Red
        if ($event.ResourceStatusReason) {
            Write-Host "    Reason: $($event.ResourceStatusReason)" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "=== Solution ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 1: Skip failed resources and continue delete" -ForegroundColor Green
Write-Host "aws cloudformation continue-update-rollback --stack-name $stackName --region $region --resources-to-skip <ResourceLogicalId>" -ForegroundColor White
Write-Host ""
Write-Host "Option 2: Force delete the stack (RECOMMENDED)" -ForegroundColor Green  
Write-Host "aws cloudformation delete-stack --stack-name $stackName --region $region" -ForegroundColor White
Write-Host ""
Write-Host "Then wait for deletion:" -ForegroundColor Yellow
Write-Host "aws cloudformation wait stack-delete-complete --stack-name $stackName --region $region" -ForegroundColor White
Write-Host ""
Write-Host "Then deploy fresh:" -ForegroundColor Yellow
Write-Host "cdk deploy --require-approval never" -ForegroundColor White
Write-Host ""

Write-Host "=== Quick Fix (Run This) ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Delete the stack" -ForegroundColor Yellow
Write-Host "aws cloudformation delete-stack --stack-name $stackName --region $region" -ForegroundColor White
Write-Host ""
Write-Host "# Wait 2-3 minutes, then check if deleted" -ForegroundColor Yellow
Write-Host "aws cloudformation describe-stacks --stack-name $stackName --region $region 2>&1" -ForegroundColor White
Write-Host ""
Write-Host "# If stack is gone, deploy fresh" -ForegroundColor Yellow
Write-Host "cd AWS-Well-Architected-Review-WAFR-" -ForegroundColor White
Write-Host "cdk deploy --require-approval never" -ForegroundColor White
