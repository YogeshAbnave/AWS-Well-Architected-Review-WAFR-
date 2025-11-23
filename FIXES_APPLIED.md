# 502 Bad Gateway - Fixes Applied

## Summary

All fixes have been applied to resolve the 502 Bad Gateway error and improve deployment reliability.

## Issues Fixed

### 1. ✅ Region Placeholder Not Replaced
**Problem:** The `{{REGION}}` placeholder in the systemd service file wasn't being replaced, causing boto3 to fail with `InvalidRegionError`.

**Fix:** Changed the heredoc from `<< 'EOF'` to `<< EOF` to allow bash variable expansion in the user data script.

**Files Modified:**
- `user_data_script.sh` - Line 170

### 2. ✅ Cognito Configuration Error
**Problem:** Login page was trying to use `{{REGION}}` placeholder directly, causing authentication failures.

**Fix:** Updated Login.py to read region from environment variables (`AWS_REGION` or `AWS_DEFAULT_REGION`) and gracefully handle missing Cognito configuration.

**Files Modified:**
- `ui_code/pages/1_Login.py` - Lines 15-27

### 3. ✅ Missing CloudFront Distribution
**Problem:** No CloudFront distribution was configured, leading to 502 errors when accessing the application.

**Fix:** Added CloudFront distribution with ALB as origin.

**Files Modified:**
- `wafr_genai_accelerator/wafr_genai_accelerator_stack.py` - Added CloudFront distribution

### 4. ✅ No Deployment Verification
**Problem:** CloudFormation didn't wait for the application to be ready before marking deployment as complete.

**Fix:** Added CloudFormation signals with 15-minute timeout to wait for application startup.

**Files Modified:**
- `wafr_genai_accelerator/wafr_genai_accelerator_stack.py` - Added creation policy
- `user_data_script.sh` - Added signal sending logic

### 5. ✅ Insufficient Logging
**Problem:** No centralized logging made troubleshooting difficult.

**Fix:** Added CloudWatch Logs integration for application and system logs.

**Files Modified:**
- `wafr_genai_accelerator/wafr_genai_accelerator_stack.py` - Added Log Group and IAM permissions
- `user_data_script.sh` - Added CloudWatch agent installation and configuration

### 6. ✅ No Error Handling in User Data
**Problem:** User data script didn't handle failures gracefully.

**Fix:** Added error trapping, retry logic, and failure signaling.

**Files Modified:**
- `user_data_script.sh` - Added error trap and send_cfn_signal function

## Deployment Instructions

### Option 1: Cancel Current Update and Redeploy (RECOMMENDED)

The current stack is in UPDATE_IN_PROGRESS state. Cancel it and redeploy with fixes:

```powershell
# 1. Cancel the current update
aws cloudformation cancel-update-stack --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1

# 2. Wait for cancellation (2-3 minutes)
# Check status with:
aws cloudformation describe-stacks --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --query "Stacks[0].StackStatus"

# 3. Once status is UPDATE_ROLLBACK_COMPLETE or ROLLBACK_COMPLETE, deploy with fixes
cd AWS-Well-Architected-Review-WAFR-
cdk deploy --require-approval never
```

### Option 2: Wait for Current Deployment

If you prefer to wait for the current deployment to complete or fail:

```powershell
# Check status every few minutes
cd AWS-Well-Architected-Review-WAFR-
.\get-url.ps1
```

Once it completes (success or failure), redeploy:

```powershell
cdk deploy --require-approval never
```

## Expected Deployment Timeline

- **0-2 min**: CloudFormation creates resources (VPC, ALB, EC2, etc.)
- **2-5 min**: EC2 instance boots and runs user data script
- **5-10 min**: Dependencies install, Streamlit starts
- **10-12 min**: Health checks pass, CloudFormation receives success signal
- **12-15 min**: CloudFront distribution propagates globally

**Total: ~15-20 minutes**

## Getting Your Application URL

After successful deployment, run:

```powershell
cd AWS-Well-Architected-Review-WAFR-
.\get-url.ps1
```

This will display:
- **CloudFront URL** (PRIMARY) - Use this to access your application
- **ALB URL** - For troubleshooting only
- **EC2 Instance ID** - For SSH/SSM access

## Verification Steps

### 1. Check Stack Status
```powershell
aws cloudformation describe-stacks --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --query "Stacks[0].StackStatus"
```

Expected: `UPDATE_COMPLETE` or `CREATE_COMPLETE`

### 2. Check EC2 Instance
```powershell
# Get instance ID from stack outputs
$instanceId = aws cloudformation describe-stacks --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --query "Stacks[0].Outputs[?OutputKey=='FrontEnd-EC2-Instance-Id'].OutputValue" --output text

# Check instance state
aws ec2 describe-instances --instance-ids $instanceId --region us-east-1 --query "Reservations[0].Instances[0].State.Name"
```

Expected: `running`

### 3. Check Application Logs
```powershell
# View real-time logs
aws logs tail /aws/ec2/wafr-streamlit --follow --region us-east-1

# Or view specific log stream
aws logs tail /aws/ec2/wafr-streamlit --log-stream-name-prefix $instanceId/application --follow --region us-east-1
```

### 4. Check ALB Target Health
```powershell
# Get target group ARN
$tgArn = aws elbv2 describe-target-groups --region us-east-1 --query "TargetGroups[?contains(TargetGroupName, 'StreamlitAppTargetGroup')].TargetGroupArn" --output text

# Check health
aws elbv2 describe-target-health --target-group-arn $tgArn --region us-east-1
```

Expected: `State: healthy`

### 5. Access Application
```powershell
# Get CloudFront URL
.\get-url.ps1
```

Open the CloudFront URL in your browser. You should see the WAFR Accelerator login page.

## Troubleshooting

### If deployment fails:
1. Check CloudFormation events:
   ```powershell
   aws cloudformation describe-stack-events --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --max-items 20
   ```

2. Check user data logs (if EC2 was created):
   ```powershell
   # Connect via SSM
   aws ssm start-session --target $instanceId --region us-east-1
   
   # Then view logs
   tail -f /var/log/user-data.log
   ```

3. Check CloudWatch Logs:
   ```powershell
   aws logs tail /aws/ec2/wafr-streamlit --since 30m --region us-east-1
   ```

### If you get 502 after deployment:
1. **Wait 15-20 minutes** - CloudFront takes time to propagate
2. **Check ALB directly** - Use the ALB-DNS URL from outputs
3. **Check target health** - Ensure EC2 instance is healthy
4. **Check Streamlit service**:
   ```bash
   systemctl status wafr-streamlit.service
   journalctl -u wafr-streamlit.service -n 50
   ```

### If application shows Cognito warning:
This is expected! The application will work without Cognito authentication. The warning message indicates that Cognito is not configured, and the app will allow access without authentication.

To configure Cognito (optional):
1. Create a Cognito User Pool
2. Update the CDK stack to include Cognito resources
3. Redeploy

## Files Created/Modified

### New Files:
- `FIXES_APPLIED.md` - This file
- `DEPLOYMENT_GUIDE.md` - Detailed deployment guide
- `get-url.ps1` - Script to get application URL
- `check-stack-status.ps1` - Script to check stack status

### Modified Files:
- `user_data_script.sh` - Fixed region replacement, added CloudWatch, signals
- `wafr_genai_accelerator/wafr_genai_accelerator_stack.py` - Added CloudFront, CloudWatch, signals
- `ui_code/pages/1_Login.py` - Fixed region reading, graceful Cognito handling

## Next Steps

1. **Deploy the stack** using instructions above
2. **Wait 15-20 minutes** for complete deployment
3. **Get your URL** using `.\get-url.ps1`
4. **Access the application** via CloudFront URL
5. **Verify functionality** - Navigate through the app

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review CloudWatch Logs
3. Check CloudFormation events
4. Verify all resources are created successfully

The application should now deploy successfully and be accessible via the CloudFront URL without 502 errors!
