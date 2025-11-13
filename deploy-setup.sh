#!/bin/bash

# AWS ECS Deployment Setup Script
# Region: us-east-1
# Account: 992167236365

set -e

echo "=========================================="
echo "AWS WAFR Accelerator - ECS Deployment Setup"
echo "=========================================="
echo ""

# Variables
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="992167236365"
ECR_REPO_NAME="wafr-accelerator"
ECS_CLUSTER_NAME="wafr-cluster"
ROLE_NAME="ecsTaskExecutionRole-wafr"
LOG_GROUP_NAME="/ecs/wafr-accelerator"

echo "Step 1: Creating ECR repository..."
aws ecr create-repository \
  --repository-name $ECR_REPO_NAME \
  --region $AWS_REGION \
  2>/dev/null || echo "ECR repository already exists"

echo ""
echo "Step 2: Creating CloudWatch log group..."
aws logs create-log-group \
  --log-group-name $LOG_GROUP_NAME \
  --region $AWS_REGION \
  2>/dev/null || echo "Log group already exists"

echo ""
echo "Step 3: Creating ECS cluster..."
aws ecs create-cluster \
  --cluster-name $ECS_CLUSTER_NAME \
  --region $AWS_REGION \
  2>/dev/null || echo "ECS cluster already exists"

echo ""
echo "Step 4: Creating ECS task execution IAM role..."
aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file://ecs/trust.json \
  2>/dev/null || echo "IAM role already exists"

echo ""
echo "Step 5: Attaching policy to IAM role..."
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
  2>/dev/null || echo "Policy already attached"

echo ""
echo "Step 6: Creating ECS task IAM role..."
TASK_ROLE_NAME="ecsTaskRole-wafr"
aws iam create-role \
  --role-name $TASK_ROLE_NAME \
  --assume-role-policy-document file://ecs/trust.json \
  2>/dev/null || echo "Task IAM role already exists"

echo ""
echo "Step 7: Attaching inline policy to task role..."
aws iam put-role-policy \
  --role-name $TASK_ROLE_NAME \
  --policy-name WAFRTaskPolicy \
  --policy-document file://ecs/task-role-policy.json \
  2>/dev/null || echo "Task policy already attached"

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Build and push Docker image (see deploy-docker.sh)"
echo "2. Register task definition: aws ecs register-task-definition --cli-input-json file://ecs/taskdef.json --region us-east-1"
echo "3. Create ALB, target group, and security groups (via Console or CLI)"
echo "4. Create ECS service pointing to ALB target group"
echo "5. Configure GitHub secrets for CI/CD"
echo ""
