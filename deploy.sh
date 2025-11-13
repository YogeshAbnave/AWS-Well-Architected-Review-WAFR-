#!/bin/bash

# WAFR Accelerator CDK Deployment Script
# Region: us-east-1

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "WAFR Accelerator CDK Deployment"
echo "=========================================="
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    MISSING_DEPS=0
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        echo "❌ Python 3 is not installed"
        echo "   Install from: https://www.python.org/downloads/"
        MISSING_DEPS=1
    else
        echo "✅ Python 3: $(python3 --version)"
    fi
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is not installed"
        echo "   Install from: https://aws.amazon.com/cli/"
        MISSING_DEPS=1
    else
        AWS_VERSION=$(aws --version 2>&1 || echo "unknown")
        echo "✅ AWS CLI: $AWS_VERSION"
    fi
    
    # Check Node.js (required for CDK)
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js is not installed (required for AWS CDK)"
        echo ""
        echo "   📥 Install Node.js:"
        echo "   Windows: Download from https://nodejs.org/ (LTS version)"
        echo "   Linux: sudo apt install nodejs npm"
        echo "   macOS: brew install node"
        echo ""
        MISSING_DEPS=1
    else
        echo "✅ Node.js: $(node --version)"
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        echo "❌ npm is not installed (comes with Node.js)"
        MISSING_DEPS=1
    else
        echo "✅ npm: $(npm --version)"
    fi
    
    # Check CDK
    if ! command -v cdk &> /dev/null; then
        echo "⚠️  AWS CDK is not installed"
        echo ""
        read -p "   Install AWS CDK now? (y/n): " INSTALL_CDK
        if [ "$INSTALL_CDK" == "y" ] || [ "$INSTALL_CDK" == "Y" ]; then
            echo "   Installing AWS CDK globally..."
            npm install -g aws-cdk
            echo "✅ AWS CDK installed: $(cdk --version)"
        else
            echo "❌ AWS CDK is required. Install with: npm install -g aws-cdk"
            MISSING_DEPS=1
        fi
    else
        echo "✅ AWS CDK: $(cdk --version)"
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "❌ AWS credentials not configured"
        echo "   Run: aws configure"
        MISSING_DEPS=1
    else
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
        echo "✅ AWS Account: $AWS_ACCOUNT"
        echo "   Identity: $AWS_USER"
    fi
    
    # Check Bedrock model access
    echo ""
    echo "Checking Bedrock model access..."
    BEDROCK_MODELS=$(aws bedrock list-foundation-models --region us-east-1 --query 'modelSummaries[?contains(modelId, `claude-3-5-sonnet`) || contains(modelId, `titan-embed`)].modelId' --output text 2>/dev/null || echo "")
    
    if [ -z "$BEDROCK_MODELS" ]; then
        echo "⚠️  Unable to verify Bedrock model access"
        echo "   Make sure you have access to:"
        echo "   - Claude 3.5 Sonnet"
        echo "   - Titan Text Embeddings V2"
        echo "   Request access at: https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess"
    else
        echo "✅ Bedrock models accessible"
    fi
    
    echo ""
    
    if [ $MISSING_DEPS -eq 1 ]; then
        echo "❌ Missing required dependencies. Please install them and try again."
        exit 1
    fi
    
    echo "✅ All prerequisites met!"
    echo ""
}

# Function to install Python dependencies
install_dependencies() {
    echo "Installing Python dependencies..."
    
    if [ -f "requirements.txt" ]; then
        python3 -m pip install -r requirements.txt
        echo "✅ Dependencies installed"
    else
        echo "❌ requirements.txt not found"
        exit 1
    fi
    
    echo ""
}

# Function to bootstrap CDK
bootstrap_cdk() {
    echo "Bootstrapping AWS CDK..."
    
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION="us-east-1"
    
    echo "Account: $AWS_ACCOUNT"
    echo "Region: $AWS_REGION"
    
    cdk bootstrap aws://$AWS_ACCOUNT/$AWS_REGION
    
    echo "✅ CDK bootstrapped"
    echo ""
}

# Function to synthesize CDK stack
synth_stack() {
    echo "Synthesizing CDK stack..."
    cdk synth
    echo "✅ Stack synthesized"
    echo ""
}

# Function to deploy CDK stack
deploy_stack() {
    echo "Deploying CDK stack..."
    echo "⚠️  This will create AWS resources that may incur costs"
    echo ""
    
    cdk deploy --require-approval never
    
    echo ""
    echo "✅ Stack deployed successfully!"
    echo ""
}

# Function to get stack outputs
get_outputs() {
    echo "=========================================="
    echo "Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "Getting stack outputs..."
    
    STACK_NAME="WellArchitectedReviewUsingGenAIStack"
    
    # Get CloudFront URL
    CLOUDFRONT_URL=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
        --output text \
        --region us-east-1 2>/dev/null || echo "Not found")
    
    # Get Cognito User Pool ID
    USER_POOL_ID=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs[?OutputKey==`CognitoUserPoolId`].OutputValue' \
        --output text \
        --region us-east-1 2>/dev/null || echo "Not found")
    
    echo ""
    echo "📋 Stack Outputs:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Application URL: $CLOUDFRONT_URL"
    echo "Cognito User Pool ID: $USER_POOL_ID"
    echo ""
    echo "To view all outputs:"
    echo "  aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs' --region us-east-1"
    echo ""
}

# Function to create Cognito user
create_user() {
    echo "=========================================="
    echo "Create Cognito User"
    echo "=========================================="
    echo ""
    
    STACK_NAME="WellArchitectedReviewUsingGenAIStack"
    
    USER_POOL_ID=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs[?OutputKey==`CognitoUserPoolId`].OutputValue' \
        --output text \
        --region us-east-1 2>/dev/null)
    
    if [ -z "$USER_POOL_ID" ] || [ "$USER_POOL_ID" == "None" ]; then
        echo "❌ Could not find Cognito User Pool ID"
        echo "Make sure the stack is deployed first"
        exit 1
    fi
    
    echo "User Pool ID: $USER_POOL_ID"
    echo ""
    
    read -p "Enter username: " USERNAME
    read -p "Enter email: " EMAIL
    read -sp "Enter password: " PASSWORD
    echo ""
    
    echo ""
    echo "Creating user..."
    
    aws cognito-idp admin-create-user \
        --user-pool-id $USER_POOL_ID \
        --username $USERNAME \
        --user-attributes Name=email,Value=$EMAIL Name=email_verified,Value=true \
        --temporary-password "TempPass123!" \
        --region us-east-1
    
    echo ""
    echo "Setting permanent password..."
    
    aws cognito-idp admin-set-user-password \
        --user-pool-id $USER_POOL_ID \
        --username $USERNAME \
        --password $PASSWORD \
        --permanent \
        --region us-east-1
    
    echo ""
    echo "✅ User created successfully!"
    echo ""
    echo "Username: $USERNAME"
    echo "Email: $EMAIL"
    echo ""
}

# Main script logic
case "$1" in
    pre-req)
        check_prerequisites
        install_dependencies
        bootstrap_cdk
        ;;
    
    deploy)
        synth_stack
        deploy_stack
        get_outputs
        ;;
    
    post-deploy)
        create_user
        ;;
    
    destroy)
        echo "⚠️  This will destroy all resources created by the stack"
        read -p "Are you sure? (yes/no): " CONFIRM
        if [ "$CONFIRM" == "yes" ]; then
            cdk destroy
        else
            echo "Cancelled"
        fi
        ;;
    
    outputs)
        get_outputs
        ;;
    
    *)
        echo "Usage: $0 {pre-req|deploy|post-deploy|destroy|outputs}"
        echo ""
        echo "Commands:"
        echo "  pre-req      - Check prerequisites, install dependencies, bootstrap CDK"
        echo "  deploy       - Deploy the CDK stack"
        echo "  post-deploy  - Create Cognito user"
        echo "  destroy      - Destroy the CDK stack"
        echo "  outputs      - Display stack outputs"
        echo ""
        echo "Example:"
        echo "  ./deploy.sh pre-req"
        echo "  ./deploy.sh deploy"
        echo "  ./deploy.sh post-deploy"
        exit 1
        ;;
esac
