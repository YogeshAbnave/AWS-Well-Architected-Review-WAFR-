# 502 Error Troubleshooting - Run These Commands

## 1. Check ALB Target Health (MOST IMPORTANT)

```powershell
# Get target group ARN
$tgArn = aws elbv2 describe-target-groups --region us-east-1 --query "TargetGroups[?contains(TargetGroupName, 'StreamlitAppTargetGroup')].TargetGroupArn" --output text

# Check if target is healthy
aws elbv2 describe-target-health --target-group-arn $tgArn --region us-east-1
```

**Expected:** `"State": "healthy"`  
**If "unhealthy":** The EC2 instance or Streamlit app has a problem

## 2. Check EC2 Instance

```powershell
# Get instance ID
$instanceId = aws cloudformation describe-stacks --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --query "Stacks[0].Outputs[?OutputKey=='FrontEnd-EC2-Instance-Id'].OutputValue" --output text

# Check instance state
aws ec2 describe-instances --instance-ids $instanceId --region us-east-1 --query "Reservations[0].Instances[0].State.Name"
```

**Expected:** `"running"`

## 3. Check Streamlit Service on EC2

```powershell
# Connect via SSM and check service
aws ssm start-session --target $instanceId --region us-east-1

# Once connected, run:
systemctl status wafr-streamlit.service
curl http://localhost:8501
tail -100 /var/log/wafr-streamlit.log
```

**Expected:** Service should be "active (running)" and curl should return HTML

## 4. Check CloudWatch Logs

```powershell
# View application logs
aws logs tail /aws/ec2/wafr-streamlit --since 30m --region us-east-1
```

## 5. Test ALB Directly (Bypass CloudFront)

```powershell
# Get ALB DNS
$albDns = aws cloudformation describe-stacks --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --query "Stacks[0].Outputs[?OutputKey=='ALB-DNS'].OutputValue" --output text

# Test it
curl $albDns
```

**If ALB works but CloudFront doesn't:** CloudFront needs time to propagate (15-20 min)  
**If ALB also shows 502:** The problem is with EC2/Streamlit

## Common Issues & Fixes

### Issue 1: Target is "unhealthy"
**Cause:** Streamlit app not running or not responding on port 8501  
**Fix:** Check logs, restart service:
```bash
sudo systemctl restart wafr-streamlit.service
```

### Issue 2: Target is "initial" 
**Cause:** Health checks haven't completed yet  
**Fix:** Wait 2-3 minutes

### Issue 3: Service failed to start
**Cause:** Missing dependencies or configuration error  
**Fix:** Check logs:
```bash
journalctl -u wafr-streamlit.service -n 100
tail -200 /var/log/user-data.log
```

### Issue 4: Port 8501 not listening
**Cause:** Streamlit didn't start  
**Fix:** Check if process is running:
```bash
ps aux | grep streamlit
netstat -tlnp | grep 8501
```

## Quick Fix Commands

If service is down, try this:

```bash
# SSH into instance
aws ssm start-session --target $instanceId --region us-east-1

# Check what's wrong
sudo systemctl status wafr-streamlit.service
sudo journalctl -u wafr-streamlit.service -n 50

# Restart service
sudo systemctl restart wafr-streamlit.service

# Watch logs
sudo tail -f /var/log/wafr-streamlit.log
```

## What to Tell Me

After running the commands above, tell me:

1. **Target Health Status:** healthy / unhealthy / initial / unavailable
2. **EC2 Instance State:** running / stopped / terminated
3. **Streamlit Service Status:** active / failed / inactive
4. **ALB Direct Test:** works / 502 error
5. **Any Error Messages:** from logs

This will help me identify the exact problem!
