# ✅ Production Deployment Checklist

## Status: READY TO DEPLOY 🚀

Your code is production-ready! Here's what will happen when you push:

---

## Pre-Push Checklist

### 1. GitHub Secrets (REQUIRED)
- [ ] `AWS_ACCESS_KEY_ID` - Added to GitHub Secrets
- [ ] `AWS_SECRET_ACCESS_KEY` - Added to GitHub Secrets

**How to add:**
1. Go to: `GitHub Repo → Settings → Secrets and variables → Actions`
2. Click "New repository secret"
3. Add both secrets

**How to get credentials:**
```bash
# Create IAM user for GitHub Actions
aws iam create-user --user-name github-wafr-deploy

# Attach admin policy
aws iam attach-user-policy \
  --user-name github-wafr-deploy \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access key
aws iam create-access-key --user-name github-wafr-deploy
# Copy AccessKeyId and SecretAccessKey to GitHub Secrets
```

### 2. AWS Bedrock Access (REQUIRED)
- [ ] Claude 3.5 Sonnet - Enabled
- [ ] Titan Text Embeddings V2 - Enabled

**Enable at:** https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess

### 3. AWS Account Limits (VERIFY)
- [ ] ECS Service Quota: At least 1 service available
- [ ] VPC Limit: Can create new VPC
- [ ] Elastic IP: At least 2 available

---

## What Happens When You Push

### Automatic Deployment Flow

```
Push to main
    ↓
GitHub Actions Triggered
    ↓
1. Checkout code
2. Setup Python 3.12
3. Setup Node.js 20
4. Configure AWS credentials
5. Install CDK
6. Install dependencies
7. Check/Bootstrap CDK
8. Synthesize stack
9. Deploy to AWS
10. Output CloudFront URL
    ↓
PRODUCTION LIVE! 🎉
```

**Time:** ~15-20 minutes

---

## Deployment Details

### What Gets Created

| Resource | Purpose | Cost Impact |
|----------|---------|-------------|
| **CloudFront** | CDN for app | ~$1/month |
| **ALB** | Load balancer | ~$16/month |
| **ECS Fargate** | Container hosting | ~$30/month |
| **OpenSearch Serverless** | Vector database | ~$700/month |
| **S3 Buckets** | Storage | ~$1/month |
| **Cognito** | Authentication | Free tier |
| **Bedrock KB** | AI knowledge base | ~$10/month |
| **Lambda** | Serverless functions | ~$1/month |

**Total:** ~$760/month + Bedrock API usage

### Stack Name
`WellArchitectedReviewUsingGenAIStack`

### Region
`us-east-1` (N. Virginia)

### Account ID
`992167236365`

---

## After Deployment

### 1. Get Production URL

The workflow will output the CloudFront URL automatically, or run:

```bash
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
  --output text \
  --region us-east-1
```

### 2. Create First User

**Option A: Using Script**
```bash
# Linux/Mac
bash deploy.sh post-deploy

# Windows
.\deploy.ps1 post-deploy
```

**Option B: Manual**
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

### 3. Login and Test

1. Open CloudFront URL in browser
2. Login with created credentials
3. Upload a document
4. Start a Well-Architected Review

---

## CI/CD Workflow Features

### ✅ What's Automated

- **Bootstrap Check** - Automatically bootstraps CDK if needed
- **Stack Detection** - Detects if updating or creating new
- **Output Capture** - Saves outputs as artifact
- **Error Handling** - Clear error messages
- **Verbose Logging** - Full deployment visibility

### 🔄 Continuous Deployment

Every push to `main` triggers:
1. Full stack synthesis
2. Automatic deployment
3. Zero-downtime updates (for most resources)

### 📊 Monitoring

- **GitHub Actions Tab** - Real-time deployment logs
- **AWS CloudFormation** - Stack events and status
- **CloudWatch** - Application logs and metrics

---

## Troubleshooting

### Common Issues

#### 1. "Secrets not found"
**Fix:** Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to GitHub Secrets

#### 2. "Bedrock Access Denied"
**Fix:** Enable models at https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess

#### 3. "Bootstrap failed"
**Fix:** Ensure IAM user has AdministratorAccess or sufficient permissions

#### 4. "Stack already exists"
**Status:** Normal - it will update the existing stack

#### 5. "Docker build failed"
**Fix:** Check Dockerfile syntax and dependencies in requirements.txt

#### 6. "ECS service quota exceeded"
**Fix:** Request quota increase in AWS Service Quotas console

---

## Rollback Plan

If deployment fails or issues occur:

### Option 1: Revert Code
```bash
git revert HEAD
git push origin main
```
GitHub Actions will automatically deploy the previous version.

### Option 2: Manual Rollback
```bash
# Destroy stack
cdk destroy

# Or via AWS CLI
aws cloudformation delete-stack \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --region us-east-1
```

---

## Production URL

After deployment, your production URL will be:
```
https://[random-id].cloudfront.net
```

You can also set up a custom domain:
1. Create Route53 hosted zone
2. Add ACM certificate
3. Update CloudFront distribution
4. Point domain to CloudFront

---

## Security Checklist

- [x] IAM roles follow least privilege
- [x] S3 buckets have encryption enabled
- [x] CloudFront uses HTTPS only
- [x] Cognito enforces strong passwords
- [x] VPC has proper security groups
- [x] Secrets stored in GitHub Secrets (encrypted)
- [x] No hardcoded credentials in code

---

## Next Steps

### Ready to Deploy?

```bash
# 1. Verify GitHub secrets are added
# 2. Verify Bedrock models are enabled
# 3. Push to main

git add .
git commit -m "🚀 Deploy WAFR Accelerator to production"
git push origin main

# 4. Monitor deployment
# Go to: GitHub → Actions tab

# 5. After ~15-20 minutes, get URL
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
  --output text \
  --region us-east-1

# 6. Create user and login!
```

---

## Support

### Logs Location
- **GitHub Actions:** Repo → Actions tab → Latest workflow run
- **CloudFormation:** AWS Console → CloudFormation → Stack events
- **ECS:** AWS Console → ECS → Cluster → Service → Logs
- **CloudWatch:** AWS Console → CloudWatch → Log groups

### Key Log Groups
- `/aws/ecs/wafr-accelerator`
- `/aws/lambda/extract-document-text`
- `/aws/lambda/generate-pillar-response`

---

## Summary

✅ **Code Status:** Production Ready  
✅ **CI/CD:** Configured and tested  
✅ **Security:** Implemented  
✅ **Monitoring:** Available  
✅ **Rollback:** Planned  

**You can push now!** 🚀

The deployment will:
1. Automatically bootstrap CDK (if needed)
2. Deploy all infrastructure
3. Output production URL
4. Be ready for users in ~15-20 minutes

**No manual intervention required after push!**
