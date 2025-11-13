# 🚀 WAFR Accelerator - Automatic Deployment Guide

## Overview

This repository deploys automatically via GitHub Actions when you push to `main` branch.

**What gets deployed:**
- ✅ Amazon Cognito (Authentication)
- ✅ Amazon S3 (Document Storage)
- ✅ Amazon OpenSearch Serverless (Vector Database)
- ✅ Amazon Bedrock Knowledge Base (Well-Architected Docs)
- ✅ ECS Fargate + ALB (Application)
- ✅ Amazon CloudFront (CDN)

**Deployment time:** ~15-20 minutes

## Setup (5 Minutes)

### 1. Create GitHub Secrets

Go to: **GitHub Repo → Settings → Secrets → Actions → New secret**

Create these 2 secrets:

```bash
# First, create IAM user and get credentials
aws iam create-user --user-name github-wafr-deploy

# Attach admin policy (or use custom policy from AUTO-DEPLOY.md)
aws iam attach-user-policy \
  --user-name github-wafr-deploy \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access key
aws iam create-access-key --user-name github-wafr-deploy
```

Add to GitHub:
- **Name:** `AWS_ACCESS_KEY_ID` → **Value:** (from command above)
- **Name:** `AWS_SECRET_ACCESS_KEY` → **Value:** (from command above)

### 2. Enable Bedrock Models

Go to: https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess

Enable:
- ✅ Claude 3.5 Sonnet
- ✅ Titan Text Embeddings V2

### 3. Push Code

```bash
git add .
git commit -m "Deploy WAFR Accelerator"
git push origin main
```

### 4. Monitor Deployment

1. Go to **GitHub → Actions** tab
2. Watch the deployment progress
3. Wait ~15-20 minutes
4. Get CloudFront URL from outputs

### 5. Create User

After deployment completes:

```bash
# Get User Pool ID
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --query 'Stacks[0].Outputs[?OutputKey==`CognitoUserPoolId`].OutputValue' \
  --output text \
  --region us-east-1

# Create user (replace USER_POOL_ID)
aws cognito-idp admin-create-user \
  --user-pool-id <USER_POOL_ID> \
  --username admin \
  --user-attributes Name=email,Value=admin@example.com Name=email_verified,Value=true \
  --region us-east-1

# Set password (replace USER_POOL_ID)
aws cognito-idp admin-set-user-password \
  --user-pool-id <USER_POOL_ID> \
  --username admin \
  --password "YourPassword123!" \
  --permanent \
  --region us-east-1
```

Or use the script:
```bash
bash deploy.sh post-deploy  # Linux/Mac
.\deploy.ps1 post-deploy    # Windows
```

### 6. Access Application

Get URL:
```bash
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
  --output text \
  --region us-east-1
```

Open in browser and login!

## Future Updates

Just push:
```bash
git add .
git commit -m "Update X"
git push origin main
```

GitHub Actions automatically deploys changes.

## Troubleshooting

### "Bedrock Access Denied"
→ Enable models at: https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess

### "Insufficient Permissions"
→ Verify GitHub secrets are correct
→ Ensure IAM user has admin or deployment permissions

### "Stack Already Exists"
→ That's fine! It will update the existing stack

### Workflow Doesn't Run
→ Check you pushed to `main` branch
→ Verify GitHub Actions is enabled
→ Check secrets are named exactly: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

## What's Deployed

After successful deployment:
- **Application URL:** CloudFront URL (from outputs)
- **Authentication:** Cognito User Pool
- **Storage:** S3 buckets for documents
- **AI:** Bedrock Knowledge Base with Well-Architected docs
- **Database:** OpenSearch Serverless for vector search

## Cost

**~$760/month** + Bedrock usage (variable)

To destroy:
```bash
cdk destroy
```

## Key Files

- `.github/workflows/cdk-deploy.yml` - Automatic deployment workflow
- `deploy.sh` / `deploy.ps1` - Manual deployment scripts (optional)
- `app.py` - CDK stack definition
- `Dockerfile` - Application container

## Summary

1. ✅ Add GitHub secrets (AWS credentials)
2. ✅ Enable Bedrock models
3. ✅ Push to main
4. ✅ Wait 15-20 minutes
5. ✅ Create user
6. ✅ Login and use!

**That's it!** Everything deploys automatically.
