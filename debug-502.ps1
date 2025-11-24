# Debug 502 Error
Write-Host "=== Checking ALB Target Health ===" -ForegroundColor Cyan

# Get target group
$tg = aws elbv2 describe-target-groups --region us-east-1 --query "TargetGroups[?contains(TargetGroupName, 'StreamlitAppTargetGroup')]" | ConvertFrom-Json

if ($tg) {
    $tgArn = $tg[0].TargetGroupArn
    Write-Host "Target Group: $($tg[0].TargetGroupName)" -ForegroundColor Green
    
    # Check health
    Write-Host "`nTarget Health:" -ForegroundColor Yellow
    aws elbv2 describe-target-health --target-group-arn $tgArn --region us-east-1 | ConvertFrom-Json | ConvertTo-Json -Depth 5
    
    # Get instance ID
    $health = aws elbv2 describe-target-health --target-group-arn $tgArn --region us-east-1 | ConvertFrom-Json
    $instanceId = $health.TargetHealthDescriptions[0].Target.Id
    
    Write-Host "`n=== Checking EC2 Instance ===" -ForegroundColor Cyan
    Write-Host "Instance ID: $instanceId" -ForegroundColor Green
    
    # Check if Streamlit is running
    Write-Host "`nChecking Streamlit service..." -ForegroundColor Yellow
    $cmd = aws ssm send-command --instance-ids $instanceId --document-name "AWS-RunShellScript" --parameters 'commands=["systemctl status wafr-streamlit.service","curl -I http://localhost:8501","netstat -tlnp | grep 8501"]' --region us-east-1 | ConvertFrom-Json
    
    Start-Sleep -Seconds 5
    
    $output = aws ssm get-command-invocation --command-id $cmd.Command.CommandId --instance-id $instanceId --region us-east-1 | ConvertFrom-Json
    
    Write-Host "`nService Status:" -ForegroundColor Yellow
    Write-Host $output.StandardOutputContent
    
    if ($output.StandardErrorContent) {
        Write-Host "`nErrors:" -ForegroundColor Red
        Write-Host $output.StandardErrorContent
    }
    
} else {
    Write-Host "No target group found!" -ForegroundColor Red
}

Write-Host "`n=== Checking ALB ===" -ForegroundColor Cyan
$alb = aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?contains(LoadBalancerName, 'StreamlitAppALB')]" | ConvertFrom-Json
if ($alb) {
    Write-Host "ALB DNS: $($alb[0].DNSName)" -ForegroundColor Green
    Write-Host "`nTesting ALB directly..." -ForegroundColor Yellow
    curl -I "http://$($alb[0].DNSName)" 2>&1 | Select-String "HTTP"
}
