# 🚀 WAFR Accelerator - Deployment Guide

## Automatic Deployment (Recommended)

### Prerequisites
1. GitHub repository with Actions enabled
2. AWS Account with Bedrock access
3. 15-20 minutes

### Steps

#### 1. Add GitHub Secrets
Go to: `Settings → Secrets and variables → Actions → New repository secret`

Add these two secrets:
- **Name:** `AWS_ACCESS_KEY_ID` → **Value:** Your AWS access key
- **Name:** `AWS_SECRET_ACCESS_KEY` → **Value:** Your AWS secret key

**How to get AWS credentials:**
```bash
# Create IAM user
aws iam create-user --user-name github-wafr-deploy

# Attach admin policy
aws iam attach-user-policy \
  --user-name github-wafr-deploy \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access key
aws iam create-access-key --user-name github-wafr-deploy
```

#### 2. Enable Bedrock Models
Visit: https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess

Enable:
- ✅ Claude 3.5 Sonnet
- ✅ Titan Text Embeddings V2

#### 3. Push to Deploy
```bash
git add .
git commit -m "Deploy WAFR Accelerator"
git push origin main
```

#### 4. Monitor Deployment
- Go to **GitHub → Actions** tab
- Watch deployment progress (~15-20 minutes)

#### 5. Get Production URL
```bash
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
  --output text \
  --region us-east-1
```

#### 6. Create User
```bash
# Linux/Mac
bash deploy.sh post-deploy

# Windows
.\deploy.ps1 post-deploy
```

---

## Manual Deployment (Alternative)

If you prefer to deploy manually without GitHub Actions:

### Prerequisites
- Docker Desktop (running)
- Python 3.12+
- Node.js & npm
- AWS CLI (configured)
- AWS CDK

### Steps

**Linux/Mac:**
```bash
bash deploy.sh pre-req    # Check prerequisites & bootstrap
bash deploy.sh deploy     # Deploy stack
bash deploy.sh post-deploy # Create user
```

**Windows:**
```powershell
.\deploy.ps1 pre-req      # Check prerequisites & bootstrap
.\deploy.ps1 deploy       # Deploy stack
.\deploy.ps1 post-deploy  # Create user
```

---

## What Gets Deployed

| Resource | Purpose |
|----------|---------|
| CloudFront | CDN for application |
| ALB | Load balancer |
| ECS Fargate | Container hosting |
| OpenSearch Serverless | Vector database |
| S3 Buckets | Document storage |
| Cognito | User authentication |
| Bedrock KB | AI knowledge base |
| Lambda Functions | Serverless processing |

**Region:** us-east-1  
**Stack Name:** WellArchitectedReviewUsingGenAIStack  
**Deployment Time:** ~15-20 minutes  
**Cost:** ~$760/month + Bedrock usage

---

## Troubleshooting

### GitHub Actions Not Running
- Verify secrets are named exactly: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- Ensure you pushed to `main` branch
- Check GitHub Actions is enabled in repository settings

### Bedrock Access Denied
Enable models at: https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess

### Bootstrap Error
Ensure your IAM user has AdministratorAccess or sufficient permissions

### Docker Not Running (Manual Deployment)
Start Docker Desktop and wait for it to fully initialize

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

## Additional Resources

- **Production Checklist:** [PRODUCTION-READY-CHECKLIST.md](PRODUCTION-READY-CHECKLIST.md)
- **Auto-Deploy Details:** [PUSH-TO-DEPLOY.md](PUSH-TO-DEPLOY.md)
- **Main README:** [README.md](README.md)

---

## Support

**Logs:**
- GitHub Actions: Repo → Actions tab
- CloudFormation: AWS Console → CloudFormation → Stack events
- Application: CloudWatch → `/aws/ecs/wafr-accelerator`

**Common Commands:**
```bash
# Get outputs
bash deploy.sh outputs

# Destroy stack
bash deploy.sh destroy
```
