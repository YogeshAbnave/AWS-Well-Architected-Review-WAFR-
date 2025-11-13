# AWS ECS Deployment Guide

Complete deployment guide for WAFR Accelerator on AWS ECS Fargate with ALB.

## Configuration

- **AWS Region**: us-east-1
- **AWS Account**: 992167236365
- **ECR Repository**: wafr-accelerator
- **ECS Cluster**: wafr-cluster
- **ECS Service**: wafr-service
- **Task Family**: wafr-accelerator-task
- **Container Port**: 8502
- **ALB Port**: 80 (443 for HTTPS)

## Prerequisites

- AWS CLI installed and configured
- Docker installed
- Admin access to AWS account 992167236365
- GitHub repository with Actions enabled

## Deployment Steps

### 1. One-Time AWS Infrastructure Setup

Run the setup script to create ECR, ECS cluster, IAM roles, and CloudWatch logs:

```bash
cd AWS-Well-Architected-Review-WAFR-
chmod +x deploy-setup.sh
./deploy-setup.sh
```

This creates:
- ECR repository: `wafr-accelerator`
- ECS cluster: `wafr-cluster`
- IAM role: `ecsTaskExecutionRole-wafr`
- CloudWatch log group: `/ecs/wafr-accelerator`

### 2. Build and Push Docker Image

```bash
chmod +x deploy-docker.sh
./deploy-docker.sh
```

Or manually:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 992167236365.dkr.ecr.us-east-1.amazonaws.com

# Build image
docker build -t wafr-accelerator:latest .

# Tag for ECR
docker tag wafr-accelerator:latest \
  992167236365.dkr.ecr.us-east-1.amazonaws.com/wafr-accelerator:latest

# Push to ECR
docker push 992167236365.dkr.ecr.us-east-1.amazonaws.com/wafr-accelerator:latest
```

### 3. Register ECS Task Definition

```bash
aws ecs register-task-definition \
  --cli-input-json file://ecs/taskdef.json \
  --region us-east-1
```

### 4. Create Application Load Balancer (ALB)

#### Option A: AWS Console (Recommended)

1. Go to EC2 → Load Balancers → Create Load Balancer
2. Choose Application Load Balancer
3. Configure:
   - Name: `wafr-alb`
   - Scheme: Internet-facing
   - IP address type: IPv4
   - VPC: Select your VPC
   - Subnets: Select 2+ subnets in different AZs
   - Security group: Allow inbound 80 (and 443 for HTTPS)

4. Create Target Group:
   - Name: `wafr-targets`
   - Target type: IP
   - Protocol: HTTP
   - Port: 8502
   - VPC: Same as ALB
   - Health check path: `/`

5. Add listener:
   - Protocol: HTTP
   - Port: 80
   - Forward to: `wafr-targets`

#### Option B: AWS CLI

```bash
# Get your VPC ID
VPC_ID=$(aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text --region us-east-1)

# Create target group
aws elbv2 create-target-group \
  --name wafr-targets \
  --protocol HTTP \
  --port 8502 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path "/" \
  --region us-east-1

# Get subnet IDs (you need at least 2 in different AZs)
SUBNET_1="subnet-xxxxxxxx"
SUBNET_2="subnet-yyyyyyyy"

# Create security group for ALB
ALB_SG=$(aws ec2 create-security-group \
  --group-name wafr-alb-sg \
  --description "Security group for WAFR ALB" \
  --vpc-id $VPC_ID \
  --region us-east-1 \
  --query 'GroupId' \
  --output text)

# Allow inbound HTTP
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region us-east-1

# Create ALB
aws elbv2 create-load-balancer \
  --name wafr-alb \
  --subnets $SUBNET_1 $SUBNET_2 \
  --security-groups $ALB_SG \
  --scheme internet-facing \
  --type application \
  --region us-east-1
```

### 5. Create ECS Service

#### Option A: AWS Console (Recommended)

1. Go to ECS → Clusters → wafr-cluster → Services → Create
2. Configure:
   - Launch type: Fargate
   - Task definition: wafr-accelerator-task (latest)
   - Service name: `wafr-service`
   - Number of tasks: 2
   - Deployment type: Rolling update

3. Networking:
   - VPC: Same as ALB
   - Subnets: Select 2+ subnets
   - Security group: Create new or use existing (allow 8502 from ALB SG)
   - Auto-assign public IP: ENABLED

4. Load balancing:
   - Load balancer type: Application Load Balancer
   - Load balancer: wafr-alb
   - Container to load balance: wafr-accelerator:8502
   - Target group: wafr-targets

5. Create service

#### Option B: AWS CLI

```bash
# Create security group for ECS tasks
TASK_SG=$(aws ec2 create-security-group \
  --group-name wafr-task-sg \
  --description "Security group for WAFR ECS tasks" \
  --vpc-id $VPC_ID \
  --region us-east-1 \
  --query 'GroupId' \
  --output text)

# Allow inbound 8502 from ALB security group
aws ec2 authorize-security-group-ingress \
  --group-id $TASK_SG \
  --protocol tcp \
  --port 8502 \
  --source-group $ALB_SG \
  --region us-east-1

# Get target group ARN
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
  --names wafr-targets \
  --region us-east-1 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Create ECS service
aws ecs create-service \
  --cluster wafr-cluster \
  --service-name wafr-service \
  --task-definition wafr-accelerator-task \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$TASK_SG],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=wafr-accelerator,containerPort=8502" \
  --region us-east-1
```

### 6. Configure GitHub Actions CI/CD

#### Create GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_REGION`: us-east-1
- `AWS_ACCOUNT_ID`: 992167236365

#### Create IAM User for CI/CD

```bash
# Create CI user
aws iam create-user --user-name github-actions-wafr

# Attach policy
aws iam put-user-policy \
  --user-name github-actions-wafr \
  --policy-name WAFRDeploymentPolicy \
  --policy-document file://ecs/ci-user-policy.json

# Create access key
aws iam create-access-key --user-name github-actions-wafr
```

Save the AccessKeyId and SecretAccessKey as GitHub secrets.

#### Test CI/CD

Push to main branch:

```bash
git add .
git commit -m "Add ECS deployment configuration"
git push origin main
```

The GitHub Action will automatically build, push to ECR, and update ECS service.

### 7. Access Your Application

Get the ALB DNS name:

```bash
aws elbv2 describe-load-balancers \
  --names wafr-alb \
  --region us-east-1 \
  --query 'LoadBalancers[0].DNSName' \
  --output text
```

Access your application at: `http://<ALB-DNS-NAME>`

### 8. (Optional) Configure Custom Domain with HTTPS

1. Request ACM certificate in us-east-1:
   ```bash
   aws acm request-certificate \
     --domain-name app.yourdomain.com \
     --validation-method DNS \
     --region us-east-1
   ```

2. Add DNS validation records in Route53 or your DNS provider

3. Add HTTPS listener to ALB:
   ```bash
   aws elbv2 create-listener \
     --load-balancer-arn <ALB-ARN> \
     --protocol HTTPS \
     --port 443 \
     --certificates CertificateArn=<CERT-ARN> \
     --default-actions Type=forward,TargetGroupArn=<TARGET-GROUP-ARN> \
     --region us-east-1
   ```

4. Create Route53 A record (ALIAS) pointing to ALB

## Monitoring

### CloudWatch Logs

View logs:
```bash
aws logs tail /ecs/wafr-accelerator --follow --region us-east-1
```

### ECS Service Status

```bash
aws ecs describe-services \
  --cluster wafr-cluster \
  --services wafr-service \
  --region us-east-1
```

### Task Status

```bash
aws ecs list-tasks \
  --cluster wafr-cluster \
  --service-name wafr-service \
  --region us-east-1
```

## Troubleshooting

### Tasks not starting

Check task logs:
```bash
aws logs tail /ecs/wafr-accelerator --follow --region us-east-1
```

Check service events:
```bash
aws ecs describe-services \
  --cluster wafr-cluster \
  --services wafr-service \
  --region us-east-1 \
  --query 'services[0].events[0:5]'
```

### ALB health checks failing

- Verify security group allows ALB → Tasks on port 8502
- Check health check path is `/`
- Verify container is listening on 0.0.0.0:8502

### GitHub Actions failing

- Verify GitHub secrets are set correctly
- Check IAM user has required permissions
- Review GitHub Actions logs

## Cleanup

To remove all resources:

```bash
# Delete ECS service
aws ecs delete-service \
  --cluster wafr-cluster \
  --service wafr-service \
  --force \
  --region us-east-1

# Delete ECS cluster
aws ecs delete-cluster \
  --cluster wafr-cluster \
  --region us-east-1

# Delete ALB and target group (via Console or CLI)

# Delete ECR images and repository
aws ecr delete-repository \
  --repository-name wafr-accelerator \
  --force \
  --region us-east-1

# Delete IAM role
aws iam detach-role-policy \
  --role-name ecsTaskExecutionRole-wafr \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws iam delete-role --role-name ecsTaskExecutionRole-wafr

# Delete log group
aws logs delete-log-group \
  --log-group-name /ecs/wafr-accelerator \
  --region us-east-1
```

## Cost Estimation

Approximate monthly costs (us-east-1):
- ECS Fargate (2 tasks, 0.5 vCPU, 1GB): ~$30
- ALB: ~$20
- ECR storage: ~$1
- CloudWatch Logs: ~$5
- Data transfer: Variable

**Total**: ~$56/month (excluding data transfer)

## Support

For issues or questions, refer to:
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS Fargate Documentation](https://docs.aws.amazon.com/fargate/)
- [Streamlit Documentation](https://docs.streamlit.io/)
