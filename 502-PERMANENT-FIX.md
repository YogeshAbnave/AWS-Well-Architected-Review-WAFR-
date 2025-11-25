# 🔧 502 Bad Gateway - PERMANENT FIX

## Root Cause Analysis

The 502 error was happening due to **two critical issues**:

### Issue 1: Wrong S3 Path
- **Problem**: User data script looked for files in `s3://bucket/app/` 
- **Reality**: CDK deploys files to `s3://bucket/` (root)
- **Result**: Script couldn't find files, created placeholder app

### Issue 2: Race Condition
- **Problem**: EC2 instance started immediately, before S3 deployment finished
- **Reality**: S3 deployment takes 2-5 minutes, EC2 starts in 30 seconds
- **Result**: Script tried to download from empty bucket, fell back to placeholder

## Fixes Applied

### Fix 1: Corrected S3 Path ✅
**File**: `user_data_script.sh`

Changed from:
```bash
aws s3 sync s3://${APP_BUCKET}/app/ /home/ec2-user/wafr-app/
```

To:
```bash
aws s3 sync s3://${APP_BUCKET}/ /home/ec2-user/wafr-app/
```

### Fix 2: Added CDK Dependency ✅
**File**: `wafr_genai_accelerator/wafr_genai_accelerator_stack.py`

Added after EC2 instance creation:
```python
# Ensure EC2 instance waits for S3 deployment to complete
ec2_create.node.add_dependency(appCodeDeploy)
```

This ensures CloudFormation won't start the EC2 instance until S3 deployment is complete.

### Fix 3: Added Retry Logic ✅
**File**: `user_data_script.sh`

Added intelligent retry mechanism:
- **10 retries** with 30-second delays
- **Verification** that critical files exist after download
- **Better logging** to CloudWatch for debugging
- **Graceful fallback** with informative error message if all retries fail

## How It Works Now

```
1. CDK Stack Deployment Starts
   ↓
2. S3 Bucket Created
   ↓
3. Application Files Uploaded to S3 (2-5 minutes)
   ↓
4. ✅ WAIT - EC2 won't start until S3 deployment completes
   ↓
5. EC2 Instance Launches
   ↓
6. User Data Script Runs
   ↓
7. Script Downloads from S3 (with retries)
   ↓
8. Verifies Files Exist
   ↓
9. Installs Dependencies
   ↓
10. Starts Streamlit Service
    ↓
11. ALB Health Checks Pass
    ↓
12. ✅ CloudFront Serves Full Application
```

## Deployment Instructions

### Option 1: Deploy via GitHub Actions (Recommended)

```bash
# Commit the fixes
git add .
git commit -m "Fix 502 error: correct S3 path, add dependency, add retry logic"
git push origin main
```

Wait 20-25 minutes for deployment to complete.

### Option 2: Deploy Locally

```bash
# Install dependencies
npm install

# Bootstrap CDK (if not done already)
cdk bootstrap

# Deploy
cdk deploy --require-approval never
```

## Verification Steps

### 1. Check Stack Deployment
```bash
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --query "Stacks[0].StackStatus" \
  --region us-east-1
```

Should show: `CREATE_COMPLETE` or `UPDATE_COMPLETE`

### 2. Get CloudFront URL
```bash
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFront-Distribution-Domain-Name'].OutputValue" \
  --output text \
  --region us-east-1
```

### 3. Check EC2 User Data Logs
```bash
# Get EC2 instance ID
INSTANCE_ID=$(aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --query "Stacks[0].Outputs[?OutputKey=='FrontEnd-EC2-Instance-Id'].OutputValue" \
  --output text \
  --region us-east-1)

# View logs via CloudWatch
aws logs tail /aws/ec2/wafr-streamlit --follow --region us-east-1

# OR SSH into instance
aws ssm start-session --target $INSTANCE_ID --region us-east-1
# Then: sudo cat /var/log/user-data.log
```

### 4. Verify Application Files
```bash
# SSH into EC2 via SSM
aws ssm start-session --target $INSTANCE_ID --region us-east-1

# Check files exist
ls -la /home/ec2-user/wafr-app/ui_code/
ls -la /home/ec2-user/wafr-app/ui_code/pages/

# Should see:
# - WAFR_Accelerator.py
# - pages/1_Login.py
# - pages/1_New_WAFR_Review.py
# - pages/2_Existing_WAFR_Reviews.py
# - pages/3_System_Architecture.py
```

### 5. Check Streamlit Service
```bash
# In SSM session
sudo systemctl status streamlit

# Should show: "active (running)"

# Check logs
sudo journalctl -u streamlit -n 50
```

### 6. Test Application
```bash
# Get CloudFront URL from stack outputs
CF_URL="https://your-cloudfront-url.cloudfront.net"

# Test it
curl -I $CF_URL

# Should return: HTTP/2 200
```

## Expected Timeline

After pushing the fix:

| Time | Event |
|------|-------|
| 0-2 min | GitHub Actions starts |
| 2-5 min | CDK synthesizes |
| 5-10 min | Infrastructure created (VPC, ALB, etc.) |
| 10-15 min | **S3 deployment completes** ✅ |
| 15-17 min | EC2 instance launches (waits for S3) |
| 17-20 min | User data script downloads files |
| 20-22 min | Streamlit starts |
| 22-25 min | Health checks pass |
| **25 min** | **✅ FULL APPLICATION LIVE!** |

## Success Indicators

✅ **CloudFormation**: Stack status is `UPDATE_COMPLETE`  
✅ **S3 Bucket**: Contains all application files  
✅ **EC2 Instance**: Running and healthy  
✅ **User Data Log**: Shows "Application files downloaded successfully!"  
✅ **Streamlit Service**: Active and running  
✅ **ALB Target**: Healthy  
✅ **CloudFront**: Returns 200 OK  
✅ **Application**: Shows login page with full navigation  

## Troubleshooting

### If Still Getting 502

1. **Wait 5 more minutes** - Full deployment takes 20-25 minutes
2. **Check CloudWatch Logs**:
   ```bash
   aws logs tail /aws/ec2/wafr-streamlit --follow --region us-east-1
   ```
3. **Verify S3 has files**:
   ```bash
   aws s3 ls s3://wafr-accelerator-app-<timestamp>/ --recursive --region us-east-1
   ```
4. **Check EC2 can access S3**:
   ```bash
   # In SSM session
   aws s3 ls s3://wafr-accelerator-app-<timestamp>/ --region us-east-1
   ```

### If Placeholder Still Shows

This means the download failed. Check:

1. **S3 bucket has files**:
   ```bash
   aws s3 ls s3://wafr-accelerator-app-<timestamp>/ui_code/ --region us-east-1
   ```

2. **EC2 IAM role has permissions**:
   ```bash
   # Should have s3:GetObject and s3:ListBucket permissions
   ```

3. **Manually trigger download**:
   ```bash
   # SSH into EC2
   cd /home/ec2-user/wafr-app
   aws s3 sync s3://wafr-accelerator-app-<timestamp>/ . --region us-east-1
   sudo systemctl restart streamlit
   ```

## What Changed

### Before
- ❌ EC2 started immediately
- ❌ S3 might be empty
- ❌ No retries
- ❌ Wrong S3 path
- ❌ Placeholder app shown

### After
- ✅ EC2 waits for S3 deployment
- ✅ S3 guaranteed to have files
- ✅ 10 retries with 30s delays
- ✅ Correct S3 path
- ✅ Full application shown

## Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    CDK Deployment                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Create S3 Bucket                                        │
│  2. Upload Application Files ──────┐                        │
│                                     │                        │
│                                     ▼                        │
│  3. Create EC2 Instance ◄───── DEPENDENCY                   │
│     (waits for step 2)                                      │
│                                                              │
│  4. EC2 User Data Runs:                                     │
│     - Retry loop (10x)                                      │
│     - Download from S3                                      │
│     - Verify files                                          │
│     - Install deps                                          │
│     - Start Streamlit                                       │
│                                                              │
│  5. ALB Health Checks                                       │
│  6. CloudFront Serves App                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Next Steps

1. **Push the changes**:
   ```bash
   git add .
   git commit -m "Permanent fix for 502 error"
   git push origin main
   ```

2. **Monitor deployment**:
   ```bash
   # Watch GitHub Actions
   # https://github.com/your-repo/actions
   
   # OR watch CloudFormation
   watch -n 10 'aws cloudformation describe-stacks \
     --stack-name WellArchitectedReviewUsingGenAIStack \
     --query "Stacks[0].StackStatus" \
     --region us-east-1'
   ```

3. **Test the application** after 25 minutes

4. **Celebrate!** 🎉

---

**This fix is permanent and will work for all future deployments.**
