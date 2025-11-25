# 🚀 Single Push to Production - Complete Guide

## ✅ Your Setup is READY!

Your application will automatically deploy to production with a single `git push`.

---

## Before You Push (One-Time Setup)

### Step 1: Add GitHub Secrets (2 minutes)

1. Go to your GitHub repository
2. Click: **Settings → Secrets and variables → Actions**
3. Click: **New repository secret**
4. Add these two secrets:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key ID |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret access key |

**Get AWS Credentials:**
```bash
# Create IAM user for GitHub Actions
aws iam create-user --user-name github-wafr-deploy

# Attach admin policy
aws iam attach-user-policy \
  --user-name github-wafr-deploy \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access key (copy the output)
aws iam create-access-key --user-name github-wafr-deploy
```

### Step 2: Enable Bedrock Models (1 minute)

1. Visit: https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess
2. Click **Edit** or **Manage model access**
3. Enable:
   - ✅ **Claude 3.5 Sonnet**
   - ✅ **Titan Text Embeddings V2**
4. Click **Save changes**

---

## Deploy to Production (Single Command!)

```bash
git add .
git commit -m "🚀 Deploy to production"
git push origin main
```

**That's it!** 🎉

---

## What Happens Automatically

```
Push to main branch
    ↓
GitHub Actions Triggered (automatic)
    ↓
1. ✅ Checkout code
2. ✅ Setup Python 3.12
3. ✅ Setup Node.js 20
4. ✅ Configure AWS credentials
5. ✅ Install AWS CDK
6. ✅ Install dependencies
7. ✅ Check/Bootstrap CDK (automatic)
8. ✅ Synthesize stack
9. ✅ Deploy to AWS (automatic)
10. ✅ Output production URL
    ↓
🎉 PRODUCTION LIVE!
```

**Time:** ~15-20 minutes

---

## Monitor Deployment

1. Go to your GitHub repository
2. Click the **Actions** tab
3. Click on the latest workflow run
4. Watch real-time deployment logs

You'll see:
- ✅ Green checkmarks for completed steps
- 🔄 Yellow spinner for in-progress steps
- ❌ Red X if something fails

---

## Get Your Production URL

### Option 1: From GitHub Actions
1. Go to **Actions** tab
2. Click on the completed workflow
3. Scroll to **Display stack outputs** step
4. Copy the CloudFront URL

### Option 2: From AWS CLI
```bash
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
  --output text \
  --region us-east-1
```

Your production URL will look like:
```
https://d1234567890abc.cloudfront.net
```

---

## Create Your First User

After deployment completes, create a user to login:

**Linux/Mac:**
```bash
bash deploy.sh post-deploy
```

**Windows:**
```powershell
.\deploy.ps1 post-deploy
```

**Or manually:**
```bash
# Get User Pool ID
USER_POOL_ID=$(aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --query 'Stacks[0].Outputs[?OutputKey==`CognitoUserPoolId`].OutputValue' \
  --output text \
  --region us-east-1)

# Create user
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username admin \
  --user-attributes Name=email,Value=admin@example.com Name=email_verified,Value=true \
  --region us-east-1

# Set password
aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username admin \
  --password "YourSecurePassword123!" \
  --permanent \
  --region us-east-1
```

---

## Access Your Application

1. Open the CloudFront URL in your browser
2. Login with your created credentials
3. Start using the WAFR Accelerator!

---

## Future Updates

Every time you push to `main`, it automatically deploys:

```bash
# Make changes to your code
git add .
git commit -m "Update feature X"
git push origin main
```

GitHub Actions will:
- ✅ Automatically detect changes
- ✅ Deploy updates to production
- ✅ Zero manual intervention needed

---

## What Gets Deployed

| Resource | Purpose | Region |
|----------|---------|--------|
| **CloudFront** | CDN for global access | Global |
| **ALB** | Load balancer | us-east-1 |
| **ECS Fargate** | Container hosting | us-east-1 |
| **OpenSearch Serverless** | Vector database | us-east-1 |
| **S3 Buckets** | Document storage | us-east-1 |
| **Cognito** | Authentication | us-east-1 |
| **Bedrock KB** | AI knowledge base | us-east-1 |
| **Lambda Functions** | Processing | us-east-1 |

**Stack Name:** `WellArchitectedReviewUsingGenAIStack`  
**Cost:** ~$760/month + Bedrock usage

---

## Troubleshooting

### ❌ "Secrets not found"
**Fix:** Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to GitHub Secrets

### ❌ "Bedrock Access Denied"
**Fix:** Enable models at https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess

### ❌ "Bootstrap failed"
**Fix:** Ensure IAM user has AdministratorAccess permissions

### ❌ "Workflow doesn't run"
**Check:**
- You pushed to `main` branch (not `master` or other)
- GitHub Actions is enabled in repository settings
- Secrets are named exactly as shown (case-sensitive)

### ❌ "Stack already exists"
**Status:** This is normal! It will update the existing stack.

---

## Rollback

If something goes wrong, rollback is easy:

```bash
# Revert to previous version
git revert HEAD
git push origin main
```

GitHub Actions will automatically deploy the previous version.

---

## Cleanup

To remove all resources:

```bash
# Using CDK
cdk destroy

# Or using AWS CLI
aws cloudformation delete-stack \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1
```

---

## Summary

### ✅ Pre-Push Checklist
- [ ] GitHub Secrets added (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
- [ ] Bedrock models enabled (Claude 3.5 Sonnet, Titan Embeddings)

### 🚀 Deploy Command
```bash
git push origin main
```

### ⏱️ Wait Time
~15-20 minutes

### 🎯 Result
Production URL ready to use!

---

## Need Help?

**Logs:**
- GitHub Actions: Repo → Actions tab → Latest run
- CloudFormation: AWS Console → CloudFormation → Stack events
- Application: CloudWatch → `/aws/ecs/wafr-accelerator`

**Documentation:**
- [DEPLOYMENT.md](DEPLOYMENT.md) - Full deployment guide
- [PRODUCTION-READY-CHECKLIST.md](PRODUCTION-READY-CHECKLIST.md) - Complete checklist
- [README.md](README.md) - Main documentation

---

## You're Ready! 🚀

Just run:
```bash
git push origin main
```

And watch your application deploy to production automatically!
