# WAFR Accelerator Deployment Guide - 502 Error Fix

## Current Situation

Your stack is currently in `UPDATE_IN_PROGRESS` state from a previous deployment. This means CloudFormation is still processing the last update.

## Solution Options

### Option 1: Wait for Current Deployment (RECOMMENDED)

The previous deployment is likely waiting for the EC2 instance to signal success (up to 15 minutes). 

**Check status:**
```powershell
cd AWS-Well-Architected-Review-WAFR-
aws cloudformation describe-stacks --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --query "Stacks[0].StackStatus"
```

**Monitor events:**
```powershell
aws cloudformation describe-stack-events --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --max-items 10
```

**Wait for completion:**
- If status becomes `UPDATE_COMPLETE` → Proceed to Option 3 (Get URL)
- If status becomes `UPDATE_ROLLBACK_COMPLETE` or `UPDATE_FAILED` → Proceed to Option 2

### Option 2: Cancel Current Update and Redeploy

If the update is stuck or failing:

```powershell
# Cancel the current update
aws cloudformation cancel-update-stack --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1

# Wait for cancellation to complete (check status)
aws cloudformation wait stack-update-complete --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1

# Then redeploy with our fixes
cd AWS-Well-Architected-Review-WAFR-
cdk deploy --require-approval never
```

### Option 3: Get Application URL (After Successful Deployment)

Once the stack is in `UPDATE_COMPLETE` or `CREATE_COMPLETE` state:

```powershell
# Get all stack outputs including CloudFront URL
aws cloudformation describe-stacks --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output table
```

Look for:
- **CloudFrontURL** - This is your main application URL (https://xxxxx.cloudfront.net)
- **ALB-DNS** - ALB endpoint for troubleshooting
- **FrontEnd-EC2-Instance-Id** - EC2 instance ID

### Option 4: Fresh Deployment (If All Else Fails)

If the stack is completely stuck:

```powershell
# Delete the stack
aws cloudformation delete-stack --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1

# Deploy fresh
cd AWS-Well-Architected-Review-WAFR-
cdk deploy --require-approval never
```

## What We Fixed

The 502 Bad Gateway error was caused by:

1. **Missing CloudFront Distribution** - Added CloudFront CDN layer
2. **No Deployment Signals** - Added CloudFormation signals to verify app startup
3. **Insufficient Logging** - Added CloudWatch Logs for troubleshooting
4. **No Startup Verification** - Enhanced user data script to verify app health

## Monitoring Deployment

### Check EC2 Instance Status
```powershell
# Get instance ID from stack outputs
$instanceId = aws cloudformation describe-stacks --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --query "Stacks[0].Outputs[?OutputKey=='FrontEnd-EC2-Instance-Id'].OutputValue" --output text

# Check instance state
aws ec2 describe-instances --instance-ids $instanceId --region us-east-1 --query "Reservations[0].Instances[0].State.Name"

# View user data logs (after instance is running)
aws ssm start-session --target $instanceId --region us-east-1
# Then run: tail -f /var/log/user-data.log
```

### Check CloudWatch Logs
```powershell
# View application logs
aws logs tail /aws/ec2/wafr-streamlit --follow --region us-east-1
```

### Check ALB Target Health
```powershell
# Get target group ARN
$tgArn = aws elbv2 describe-target-groups --region us-east-1 --query "TargetGroups[?contains(TargetGroupName, 'StreamlitAppTargetGroup')].TargetGroupArn" --output text

# Check target health
aws elbv2 describe-target-health --target-group-arn $tgArn --region us-east-1
```

## Expected Deployment Timeline

1. **0-2 minutes**: CloudFormation creates resources (VPC, ALB, EC2, etc.)
2. **2-5 minutes**: EC2 instance boots and runs user data script
3. **5-10 minutes**: Dependencies install, Streamlit starts
4. **10-12 minutes**: Health checks pass, CloudFormation receives success signal
5. **12-15 minutes**: CloudFront distribution propagates globally

**Total: ~15-20 minutes for complete deployment**

## Troubleshooting

### If deployment times out:
- Check `/var/log/user-data.log` on EC2 instance
- Check CloudWatch Logs at `/aws/ec2/wafr-streamlit`
- Verify IAM permissions for EC2 role
- Check security group allows ALB → EC2 traffic on port 8501

### If you get 502 after deployment:
- Wait 5-10 minutes for CloudFront to propagate
- Check ALB target health (should be "healthy")
- Try accessing ALB directly (use ALB-DNS output)
- Check Streamlit service: `systemctl status wafr-streamlit.service`

### If CloudFront shows error:
- CloudFront takes 15-20 minutes to fully deploy
- Check ALB is accessible first
- Verify EC2 instance is healthy

## Next Steps

1. **Check current stack status** using Option 1 commands above
2. **Wait or cancel** based on the status
3. **Deploy** once stack is ready
4. **Get URL** from stack outputs
5. **Access application** via CloudFront URL

## Quick Commands Reference

```powershell
# Check stack status
aws cloudformation describe-stacks --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --query "Stacks[0].StackStatus"

# Get outputs (including URL)
aws cloudformation describe-stacks --stack-name WellArchitectedReviewUsingGenAIStack --region us-east-1 --query "Stacks[0].Outputs"

# Deploy
cd AWS-Well-Architected-Review-WAFR-
cdk deploy --require-approval never

# View logs
aws logs tail /aws/ec2/wafr-streamlit --follow --region us-east-1
```
