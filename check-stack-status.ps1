# Check CloudFormation Stack Status
param(
    [string]$StackName = "WellArchitectedReviewUsingGenAIStack",
    [string]$Region = "us-east-1"
)

Write-Host "Checking stack status for: $StackName" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host ""

# Get stack status
$stackStatus = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query "Stacks[0].StackStatus" `
    --output text 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error getting stack status:" -ForegroundColor Red
    Write-Host $stackStatus
    exit 1
}

Write-Host "Current Status: $stackStatus" -ForegroundColor Yellow
Write-Host ""

# Get recent stack events
Write-Host "Recent Stack Events:" -ForegroundColor Cyan
aws cloudformation describe-stack-events `
    --stack-name $StackName `
    --region $Region `
    --max-items 10 `
    --query "StackEvents[].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]" `
    --output table

Write-Host ""

# Check if stack is in a terminal state
$terminalStates = @("CREATE_COMPLETE", "UPDATE_COMPLETE", "ROLLBACK_COMPLETE", "UPDATE_ROLLBACK_COMPLETE", "CREATE_FAILED", "UPDATE_FAILED")
$inProgressStates = @("CREATE_IN_PROGRESS", "UPDATE_IN_PROGRESS", "UPDATE_COMPLETE_CLEANUP_IN_PROGRESS", "ROLLBACK_IN_PROGRESS", "UPDATE_ROLLBACK_IN_PROGRESS")

if ($terminalStates -contains $stackStatus) {
    Write-Host "Stack is in terminal state: $stackStatus" -ForegroundColor Green
    
    if ($stackStatus -eq "UPDATE_COMPLETE") {
        Write-Host ""
        Write-Host "Getting stack outputs..." -ForegroundColor Cyan
        aws cloudformation describe-stacks `
            --stack-name $StackName `
            --region $Region `
            --query "Stacks[0].Outputs[].[OutputKey,OutputValue,Description]" `
            --output table
    }
} elseif ($inProgressStates -contains $stackStatus) {
    Write-Host "Stack is still updating. Status: $stackStatus" -ForegroundColor Yellow
    Write-Host "Please wait for the update to complete before deploying again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can monitor progress with:" -ForegroundColor Cyan
    Write-Host "  aws cloudformation describe-stack-events --stack-name $StackName --region $Region" -ForegroundColor White
} else {
    Write-Host "Stack is in state: $stackStatus" -ForegroundColor Yellow
}
