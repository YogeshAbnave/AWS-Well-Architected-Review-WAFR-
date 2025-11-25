# 🗑️ Delete All AWS Resources

## Quick Delete (Recommended)

Run the PowerShell script:

```powershell
.\DELETE_ALL_RESOURCES.ps1
```

This will:
1. ✅ Delete CloudFormation stack
2. ✅ Wait for deletion to complete
3. ✅ Clean up any remaining S3 buckets
4. ✅ Delete CloudWatch log groups
5. ✅ Verify everything is deleted

**Time: 5-10 minutes**

---

## Manual Delete (Alternative)

If you prefer to delete manually or the script fails:

### Step 1: Delete CloudFormation Stack
```bash
aws cloudformation delete-stack \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1
```

### Step 2: Monitor Deletion
```bash
# Watch deletion progress
watch -n 10 'aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1 \
  --query "Stacks[0].StackStatus" 2>&1'

# When you see "Stack does not exist" - it's done!
```

### Step 3: Clean Up S3 Buckets (if any remain)
```bash
# List WAFR buckets
aws s3 ls | grep wafr

# Delete each bucket (replace <bucket-name> with actual name)
aws s3 rm s3://<bucket-name> --recursive --region us-east-1
aws s3 rb s3://<bucket-name> --region us-east-1
```

### Step 4: Delete CloudWatch Logs
```bash
# List log groups
aws logs describe-log-groups \
  --region us-east-1 \
  --query "logGroups[?contains(logGroupName, 'wafr')].logGroupName"

# Delete log group
aws logs delete-log-group \
  --log-group-name /aws/ec2/wafr-streamlit \
  --region us-east-1
```

---

## What Gets Deleted

### Infrastructure
- ✅ EC2 Instance (Streamlit app)
- ✅ VPC (with subnets, NAT gateway, internet gateway)
- ✅ Application Load Balancer (ALB)
- ✅ CloudFront Distribution
- ✅ Security Groups

### Storage
- ✅ S3 Buckets (app deployment, uploads, KB docs, prompts, UI, access logs)
- ✅ DynamoDB Tables (review runs, pillar questions)

### AI/ML
- ✅ Bedrock Knowledge Base
- ✅ OpenSearch Serverless Collection
- ✅ Bedrock Guardrails (if enabled)

### Networking
- ✅ WAF Web ACL
- ✅ Target Groups
- ✅ Load Balancer Listeners

### Security
- ✅ IAM Roles (EC2, Lambda, Step Functions)
- ✅ IAM Policies
- ✅ Cognito User Pool

### Compute
- ✅ Lambda Functions (9 functions)
- ✅ Step Functions State Machine
- ✅ SQS Queues (main + dead letter)

### Monitoring
- ✅ CloudWatch Log Groups
- ✅ CloudWatch Alarms

### Configuration
- ✅ SSM Parameters

---

## Verification

After deletion completes, verify everything is gone:

```bash
# Check CloudFormation
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1
# Should return: "Stack does not exist"

# Check EC2 instances
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Project,Values=WellArchitectedReview" \
  --query "Reservations[].Instances[?State.Name!='terminated'].InstanceId"
# Should return: []

# Check S3 buckets
aws s3 ls | grep wafr
# Should return: nothing

# Check VPCs
aws ec2 describe-vpcs \
  --region us-east-1 \
  --filters "Name=tag:Project,Values=WellArchitectedReview" \
  --query "Vpcs[].VpcId"
# Should return: []
```

---

## Cost Impact

After deletion:
- ✅ **$0/hour** - No more charges
- ✅ All resources terminated
- ✅ No lingering costs

---

## Common Issues

### Issue: Stack deletion stuck
**Symptom**: Stack shows `DELETE_IN_PROGRESS` for >15 minutes

**Solution**:
```bash
# Check what's blocking deletion
aws cloudformation describe-stack-events \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1 \
  --query "StackEvents[?ResourceStatus=='DELETE_FAILED']"

# Common blockers:
# - S3 buckets not empty (delete manually)
# - ENIs still attached (wait a few minutes)
# - Security groups in use (wait for EC2 to terminate)
```

### Issue: S3 bucket won't delete
**Symptom**: "BucketNotEmpty" error

**Solution**:
```bash
# Force empty and delete
aws s3 rm s3://<bucket-name> --recursive --region us-east-1
aws s3 rb s3://<bucket-name> --force --region us-east-1
```

### Issue: VPC won't delete
**Symptom**: "DependencyViolation" error

**Solution**:
```bash
# Wait 5 minutes for ENIs to detach
# Then try again
aws cloudformation delete-stack \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1
```

---

## After Deletion

Once everything is deleted, you can:

### Option 1: Redeploy with Fixes
```bash
# Push the fixed code
git add .
git commit -m "Deploy with 502 fixes"
git push origin main

# Wait 25 minutes for fresh deployment
```

### Option 2: Keep It Deleted
Nothing to do! All resources are gone and you won't be charged.

---

## Emergency Delete (Nuclear Option)

If the script fails and manual deletion doesn't work:

```bash
# 1. Delete stack and skip failures
aws cloudformation delete-stack \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1

# 2. Force delete all S3 buckets
for bucket in $(aws s3 ls | grep wafr | awk '{print $3}'); do
  echo "Deleting $bucket"
  aws s3 rm s3://$bucket --recursive --region us-east-1
  aws s3 rb s3://$bucket --force --region us-east-1
done

# 3. Terminate all EC2 instances
for instance in $(aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Project,Values=WellArchitectedReview" \
  --query "Reservations[].Instances[?State.Name!='terminated'].InstanceId" \
  --output text); do
  echo "Terminating $instance"
  aws ec2 terminate-instances --instance-ids $instance --region us-east-1
done

# 4. Wait 5 minutes, then delete VPC manually from console
```

---

## Ready to Delete?

### Windows (PowerShell):
```powershell
.\DELETE_ALL_RESOURCES.ps1
```

### Linux/Mac (Bash):
```bash
aws cloudformation delete-stack \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1
```

**Deletion takes 5-10 minutes. Grab a coffee! ☕**
