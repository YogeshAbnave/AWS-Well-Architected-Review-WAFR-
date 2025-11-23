# Check EC2 Instance Logs
$stackName = "WellArchitectedReviewUsingGenAIStack"
$region = "us-east-1"

Write-Host "Checking for failed EC2 instance..." -ForegroundColor Yellow

# Get the instance ID from CloudFormation events
$events = aws cloudformation describe-stack-events --stack-name $stackName --region $region --max-items 50 --output json | ConvertFrom-Json

$instanceId = $null
foreach ($event in $events.StackEvents) {
    if ($event.ResourceType -eq "AWS::EC2::Instance" -and $event.PhysicalResourceId -like "i-*") {
        $instanceId = $event.PhysicalResourceId
        Write-Host "Found instance: $instanceId" -ForegroundColor Green
        break
    }
}

if ($instanceId) {
    Write-Host ""
    Write-Host "Checking instance state..." -ForegroundColor Cyan
    aws ec2 describe-instances --instance-ids $instanceId --region $region --query "Reservations[0].Instances[0].[State.Name,PublicIpAddress]" --output table
    
    Write-Host ""
    Write-Host "Fetching user-data logs via CloudWatch..." -ForegroundColor Cyan
    aws logs tail /aws/ec2/wafr-streamlit --log-stream-name-prefix "$instanceId/user-data" --since 30m --region $region
    
    Write-Host ""
    Write-Host "Fetching application logs via CloudWatch..." -ForegroundColor Cyan
    aws logs tail /aws/ec2/wafr-streamlit --log-stream-name-prefix "$instanceId/application" --since 30m --region $region
    
} else {
    Write-Host "Could not find instance ID in CloudFormation events" -ForegroundColor Red
    Write-Host "The instance may have been terminated during rollback" -ForegroundColor Yellow
}
