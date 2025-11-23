# Diagnose 502 Bad Gateway Error
$stackName = "WellArchitectedReviewUsingGenAIStack"
$region = "us-east-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Diagnosing 502 Bad Gateway Error" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Get Instance ID
Write-Host "1. Getting EC2 Instance ID..." -ForegroundColor Yellow
$instanceId = aws cloudformation describe-stacks --stack-name $stackName --region $region --query "Stacks[0].Outputs[?OutputKey=='FrontEnd-EC2-Instance-Id'].OutputValue" --output text
Write-Host "   Instance ID: $instanceId" -ForegroundColor Green
Write-Host ""

# 2. Check Instance State
Write-Host "2. Checking EC2 Instance State..." -ForegroundColor Yellow
aws ec2 describe-instances --instance-ids $instanceId --region $region --query "Reservations[0].Instances[0].[State.Name,PublicIpAddress]" --output table
Write-Host ""

# 3. Check ALB Target Health
Write-Host "3. Checking ALB Target Health..." -ForegroundColor Yellow
$tgArn = aws elbv2 describe-target-groups --region $region --query "TargetGroups[?contains(TargetGroupName, 'StreamlitAppTargetGroup')].TargetGroupArn" --output text
if ($tgArn) {
    aws elbv2 describe-target-health --target-group-arn $tgArn --region $region --output table
} else {
    Write-Host "   Could not find target group" -ForegroundColor Red
}
Write-Host ""

# 4. Check Streamlit Service Status via SSM
Write-Host "4. Checking Streamlit Service Status..." -ForegroundColor Yellow
$commandId = aws ssm send-command `
    --instance-ids $instanceId `
    --document-name "AWS-RunShellScript" `
    --parameters 'commands=["systemctl status wafr-streamlit.service --no-pager","curl -s http://localhost:8501 || echo FAILED","netstat -tlnp | grep 8501 || echo NOT_LISTENING"]' `
    --region $region `
    --query "Command.CommandId" `
    --output text

Write-Host "   Waiting for command to execute..." -ForegroundColor Gray
Start-Sleep -Seconds 5

$output = aws ssm get-command-invocation `
    --command-id $commandId `
    --instance-id $instanceId `
    --region $region `
    --query "StandardOutputContent" `
    --output text

Write-Host $output
Write-Host ""

# 5. Check Recent Logs
Write-Host "5. Checking Recent Application Logs..." -ForegroundColor Yellow
Write-Host "   User Data Logs:" -ForegroundColor Cyan
aws logs tail /aws/ec2/wafr-streamlit --log-stream-name-prefix "$instanceId/user-data" --since 10m --region $region --format short 2>$null
Write-Host ""
Write-Host "   Application Logs:" -ForegroundColor Cyan
aws logs tail /aws/ec2/wafr-streamlit --log-stream-name-prefix "$instanceId/application" --since 10m --region $region --format short 2>$null
Write-Host ""

# 6. Get URLs
Write-Host "6. Application URLs:" -ForegroundColor Yellow
$outputs = aws cloudformation describe-stacks --stack-name $stackName --region $region --query "Stacks[0].Outputs" --output json | ConvertFrom-Json
foreach ($output in $outputs) {
    if ($output.OutputKey -eq "CloudFrontURL") {
        Write-Host "   CloudFront: $($output.OutputValue)" -ForegroundColor White
    }
    elseif ($output.OutputKey -eq "ALB-DNS") {
        Write-Host "   ALB: $($output.OutputValue)" -ForegroundColor White
    }
    elseif ($output.OutputKey -eq "FrontEnd-EC2-Public-IP") {
        Write-Host "   EC2 Direct: http://$($output.OutputValue):8501" -ForegroundColor White
    }
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Diagnosis Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
