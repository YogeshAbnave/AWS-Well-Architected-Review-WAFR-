# 🗑️ Push to Delete All Resources

## What Happens Now

When you push code to GitHub, it will **automatically delete ALL AWS resources** instead of deploying.

## How to Delete Everything

### Step 1: Push Your Code
```bash
git add .
git commit -m "Delete all AWS resources"
git push origin main
```

### Step 2: Watch Deletion
Go to GitHub Actions:
```
https://github.com/YOUR_USERNAME/YOUR_REPO/actions
```

You'll see the workflow running with these steps:
1. ✅ Check if stack exists
2. ✅ Delete CloudFormation stack
3. ✅ Wait for deletion (5-10 minutes)
4. ✅ Clean up remaining S3 buckets
5. ✅ Delete CloudWatch logs
6. ✅ Verify everything is deleted

### Step 3: Confirm Deletion
After 10 minutes, check the workflow output. You should see:

```
✅ CLEANUP COMPLETE

All AWS resources have been deleted!

Cost: $0/hour 💰
```

---

## What Gets Deleted

**Everything!** Including:

### Infrastructure
- ✅ EC2 Instance
- ✅ VPC (subnets, NAT gateway, internet gateway)
- ✅ Application Load Balancer
- ✅ CloudFront Distribution
- ✅ Security Groups

### Storage
- ✅ S3 Buckets (all 6 buckets)
- ✅ DynamoDB Tables (2 tables)

### AI/ML
- ✅ Bedrock Knowledge Base
- ✅ OpenSearch Serverless Collection
- ✅ Bedrock Guardrails

### Compute
- ✅ Lambda Functions (9 functions)
- ✅ Step Functions State Machine
- ✅ SQS Queues

### Security
- ✅ IAM Roles and Policies
- ✅ Cognito User Pool

### Monitoring
- ✅ CloudWatch Log Groups
- ✅ CloudWatch Alarms

### Everything Else
- ✅ WAF Rules
- ✅ Target Groups
- ✅ SSM Parameters

---

## Timeline

| Time | What's Happening |
|------|------------------|
| 0-1 min | GitHub Actions starts |
| 1-2 min | Initiates stack deletion |
| 2-10 min | Resources being deleted |
| 10 min | Cleanup S3 and logs |
| **10-12 min** | **✅ Everything deleted!** |

---

## Verification

After the workflow completes, you can verify:

```bash
# Check stack is gone
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1
# Should return: "Stack does not exist"

# Check no EC2 instances
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Project,Values=WellArchitectedReview" \
  --query "Reservations[].Instances[?State.Name!='terminated'].InstanceId"
# Should return: []

# Check no S3 buckets
aws s3 ls | grep wafr
# Should return: nothing
```

---

## Cost Impact

**Before deletion**: ~$50-100/month  
**After deletion**: **$0/month** 💰

All resources terminated, no more charges!

---

## If You Want to Deploy Again Later

To switch back to deployment mode:

1. Restore the original workflow file
2. Push to GitHub
3. Wait 25 minutes for deployment

Or just run locally:
```bash
cdk deploy --require-approval never
```

---

## Troubleshooting

### Workflow fails with "Stack doesn't exist"
**This is fine!** It means there's nothing to delete. The workflow will complete successfully.

### Deletion takes longer than 10 minutes
**This is normal** for large stacks. The workflow will wait up to 10 minutes, but some resources may take longer. Check AWS Console to monitor progress.

### Some resources remain after deletion
Run the cleanup manually:

```bash
# Delete remaining S3 buckets
for bucket in $(aws s3 ls | grep wafr | awk '{print $3}'); do
  aws s3 rm s3://$bucket --recursive --region us-east-1
  aws s3 rb s3://$bucket --region us-east-1
done

# Delete log groups
aws logs describe-log-groups --region us-east-1 \
  --query "logGroups[?contains(logGroupName, 'wafr')].logGroupName" \
  --output text | xargs -I {} aws logs delete-log-group --log-group-name {} --region us-east-1
```

---

## Ready to Delete?

Just push your code:

```bash
git add .
git commit -m "Delete all AWS resources"
git push origin main
```

Then watch GitHub Actions do the work! 🚀

**Deletion will start automatically in 1-2 minutes.**
