#!/bin/bash

# Docker Build and Push Script
# Region: us-east-1
# Account: 992167236365

set -e

echo "=========================================="
echo "Building and Pushing Docker Image to ECR"
echo "=========================================="
echo ""

# Variables
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="992167236365"
ECR_REPO_NAME="wafr-accelerator"
IMAGE_TAG="${1:-latest}"

ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FULL_IMAGE_NAME="${ECR_URI}/${ECR_REPO_NAME}:${IMAGE_TAG}"

echo "Step 1: Authenticating Docker with ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_URI

echo ""
echo "Step 2: Building Docker image..."
docker build -t ${ECR_REPO_NAME}:${IMAGE_TAG} .

echo ""
echo "Step 3: Tagging image for ECR..."
docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}

echo ""
echo "Step 4: Pushing image to ECR..."
docker push ${FULL_IMAGE_NAME}

echo ""
echo "=========================================="
echo "Docker Image Pushed Successfully!"
echo "=========================================="
echo ""
echo "Image URI: ${FULL_IMAGE_NAME}"
echo ""
echo "Next step: Register task definition"
echo "  aws ecs register-task-definition --cli-input-json file://ecs/taskdef.json --region us-east-1"
echo ""
