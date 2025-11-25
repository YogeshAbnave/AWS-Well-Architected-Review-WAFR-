# 🗑️ Automatic Resource Deletion

## ⚠️ IMPORTANT: Workflow Changed

Your GitHub Actions workflow has been **modified to DELETE resources** instead of deploying them.

## What Happens When You Push

```bash
git push origin main
```

**Result**: All AWS resources will be **DELETED** automatically! 🗑️

---

## Quick Start

### Delete Everything Now

```bash
git add .
git commit -m "Delete all AWS resources"
git push origin main
```

Then go to GitHub Actions and watch the deletion:
```
https://github.com/YOUR_USERNAME/YOUR_REPO/actions
```

**Time**: 10-12 minutes  
**Cost after**: $0/hour 💰

---

## What Changed

### Before (Old Workflow)
```yaml
name: CDK Full Stack Deployment
# Pushed code → Deployed to AWS
```

### After (New Workflow)
```yaml
name: Delete All AWS Resources
# Pushed code → Deletes everything from AWS
```

---

## Workflow Steps

When you push, GitHub Actions will:

1. ✅ **Check if stack exists**
   - If no stack: "Nothing to delete" ✅
   - If stack exists: Proceed to delete

2. ✅ **Delete CloudFormation stack**
   - Initiates deletion of all resources
   - Takes 5-10 minutes

3. ✅ **Wait for completion**
   - Monitors deletion progress
   - Checks every 15 seconds

4. ✅ **Clean up S3 buckets**
   - Empties all WAFR buckets
   - Deletes the buckets

5. ✅ **Delete CloudWatch logs**
   - Removes all log groups

6. ✅ **Verify cleanup**
   - Confirms everything is deleted
   - Shows final status

---

## What Gets Deleted

**EVERYTHING!** Including:

- EC2 instances
- VPC and networking
- Load balancers
- CloudFront distributions
- S3 buckets (6 total)
- DynamoDB tables (2 total)
- Lambda functions (9 total)
- Bedrock Knowledge Base
- OpenSearch collection
- IAM roles and policies
- Cognito user pools
- CloudWatch logs and alarms
- Step Functions
- SQS queues
- WAF rules
- SSM parameters

**Total resources deleted**: ~50+ resources

---

## Timeline

| Time | Event |
|------|-------|
| 0 min | Push code to GitHub |
| 1 min | GitHub Actions starts |
| 2 min | Stack deletion initiated |
| 2-10 min | Resources being deleted |
| 10 min | S3 and logs cleanup |
| 12 min | ✅ **Everything deleted!** |

---

## Monitoring Deletion

### Option 1: GitHub Actions (Recommended)
```
https://github.com/YOUR_USERNAME/YOUR_REPO/actions
```

### Option 2: AWS CLI
```bash
# Watch stack status
watch -n 10 'aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1 \
  --query "Stacks[0].StackStatus" 2>&1'
```

### Option 3: AWS Console
```
https://console.aws.amazon.com/cloudformation/home?region=us-east-1
```

---

## Success Indicators

After workflow completes, you'll see:

```
✅ CLEANUP COMPLETE

All AWS resources have been deleted!

Cost: $0/hour 💰

What was deleted:
  - CloudFormation stack
  - EC2 instance
  - VPC and networking
  - Load balancers
  - CloudFront distribution
  - S3 buckets
  - DynamoDB tables
  - Lambda functions
  - Bedrock Knowledge Base
  - OpenSearch collection
  - IAM roles and policies
  - CloudWatch logs
  - And everything else!
```

---

## Verification Commands

After deletion, verify everything is gone:

```bash
# 1. Check CloudFormation stack
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1
# Expected: "Stack does not exist"

# 2. Check EC2 instances
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Project,Values=WellArchitectedReview" \
  --query "Reservations[].Instances[?State.Name!='terminated'].InstanceId"
# Expected: []

# 3. Check S3 buckets
aws s3 ls | grep wafr
# Expected: (no output)

# 4. Check VPCs
aws ec2 describe-vpcs \
  --region us-east-1 \
  --filters "Name=tag:Project,Values=WellArchitectedReview" \
  --query "Vpcs[].VpcId"
# Expected: []
```

---

## Cost Impact

### Before Deletion
- EC2: ~$10/month
- NAT Gateway: ~$30/month
- OpenSearch: ~$20/month
- Other services: ~$10/month
- **Total**: ~$70/month

### After Deletion
- **Total**: **$0/month** 💰

---

## Troubleshooting

### Issue: "Stack doesn't exist"
**This is fine!** Nothing to delete. Workflow completes successfully.

### Issue: Deletion takes >10 minutes
**This is normal** for large stacks. Check AWS Console for progress.

### Issue: Some resources remain
Run manual cleanup:

```bash
# Delete S3 buckets
aws s3 ls | grep wafr | awk '{print $3}' | while read bucket; do
  aws s3 rm s3://$bucket --recursive --region us-east-1
  aws s3 rb s3://$bucket --region us-east-1
done

# Delete log groups
aws logs describe-log-groups --region us-east-1 \
  --query "logGroups[?contains(logGroupName, 'wafr')].logGroupName" \
  --output text | while read log; do
  aws logs delete-log-group --log-group-name $log --region us-east-1
done
```

### Issue: Workflow fails
Check the error in GitHub Actions. Common issues:
- AWS credentials expired
- Permissions insufficient
- Resources stuck in DELETE_IN_PROGRESS

**Solution**: Wait 5 minutes and push again.

---

## To Switch Back to Deployment Mode

If you want to deploy instead of delete:

1. Restore the original workflow file from git history
2. Or manually change the workflow back to deployment
3. Push to GitHub

---

## Files Modified

- ✅ `.github/workflows/cdk-deploy.yml` - Changed to deletion workflow
- ✅ `PUSH-TO-DELETE.md` - Quick guide
- ✅ `DELETE-EVERYTHING.md` - Detailed deletion guide
- ✅ `README-DELETE.md` - This file

---

## Ready to Delete?

```bash
git add .
git commit -m "Delete all AWS resources"
git push origin main
```

**Deletion starts automatically in 1-2 minutes!** 🚀

---

## Need Help?

- Check GitHub Actions logs
- Review AWS CloudFormation events
- Check CloudWatch logs
- Contact AWS Support if resources are stuck

---

**Remember**: Once deleted, all data is gone permanently! Make sure you have backups if needed.
