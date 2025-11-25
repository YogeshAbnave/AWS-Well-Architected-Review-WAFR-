# 🚀 WAFR Accelerator - Start Here

## Quick Start (2 Steps to Production!)

### Step 1: Setup (5 minutes)

#### A. Add GitHub Secrets
1. Go to: `GitHub Repo → Settings → Secrets and variables → Actions`
2. Click: **New repository secret**
3. Add:
   - Name: `AWS_ACCESS_KEY_ID` → Value: (your AWS access key)
   - Name: `AWS_SECRET_ACCESS_KEY` → Value: (your AWS secret key)

#### B. Enable Bedrock Models
1. Visit: https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess
2. Enable:
   - ✅ Claude 3.5 Sonnet
   - ✅ Titan Text Embeddings V2

### Step 2: Deploy (1 command!)

```bash
git add .
git commit -m "🚀 Deploy to production"
git push origin main
```

**Done!** Your app deploys automatically in ~15-20 minutes.

---

## What Happens

```
git push
   ↓
GitHub Actions (automatic)
   ↓
AWS Deployment (automatic)
   ↓
Production URL Ready! 🎉
```

---

## After Deployment

### Get Your Production URL

**From GitHub:**
1. Go to **Actions** tab
2. Click latest workflow
3. Find CloudFront URL in outputs

**From CLI:**
```bash
aws cloudformation describe-stacks \
  --stack-name WellArchitectedReviewUsingGenAIStack \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
  --output text \
  --region us-east-1
```

### Create First User

```bash
# Linux/Mac
bash deploy.sh post-deploy

# Windows
.\deploy.ps1 post-deploy
```

### Login & Use
Open the CloudFront URL and login with your credentials!

---

## Documentation

| Document | Purpose |
|----------|---------|
| **[READY-TO-PUSH.md](READY-TO-PUSH.md)** | Quick checklist before pushing |
| **[SINGLE-PUSH-DEPLOY.md](SINGLE-PUSH-DEPLOY.md)** | Complete single-push guide |
| **[DEPLOYMENT.md](DEPLOYMENT.md)** | Full deployment documentation |
| **[PRODUCTION-READY-CHECKLIST.md](PRODUCTION-READY-CHECKLIST.md)** | Detailed production checklist |
| **[README.md](README.md)** | Main project documentation |

---

## Need Help?

### Common Issues

**"Secrets not found"**
→ Add secrets to GitHub: Settings → Secrets and variables → Actions

**"Bedrock Access Denied"**
→ Enable models: https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess

**"Workflow doesn't run"**
→ Check you pushed to `main` branch and GitHub Actions is enabled

---

## Summary

✅ **Setup:** Add 2 GitHub secrets + Enable 2 Bedrock models  
✅ **Deploy:** `git push origin main`  
✅ **Wait:** ~15-20 minutes  
✅ **Result:** Production URL ready!

**That's it!** 🚀
