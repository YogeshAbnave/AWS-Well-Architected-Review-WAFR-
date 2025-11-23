# WAFR Accelerator CDK Deployment Script (PowerShell)
# Region: us-east-1

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "WAFR Accelerator CDK Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Check-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    Write-Host ""
    
    $missingDeps = $false
    
    # Check Docker
    Write-Host "Checking Docker..." -ForegroundColor Yellow
    try {
        $dockerVersion = docker --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
            
            # Check if Docker daemon is running
            $null = docker info 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Docker daemon is running" -ForegroundColor Green
            } else {
                Write-Host "❌ Docker daemon is not running" -ForegroundColor Red
                Write-Host "   Please start Docker Desktop and try again" -ForegroundColor Yellow
                Write-Host "   1. Open Docker Desktop from Start Menu" -ForegroundColor Yellow
                Write-Host "   2. Wait for Docker to fully start (check system tray)" -ForegroundColor Yellow
                Write-Host "   3. Run this script again" -ForegroundColor Yellow
                $missingDeps = $true
            }
        } else {
            Write-Host "❌ Docker is not installed" -ForegroundColor Red
            Write-Host "   Install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
            $missingDeps = $true
        }
    } catch {
        Write-Host "❌ Docker is not installed" -ForegroundColor Red
        Write-Host "   Install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        $missingDeps = $true
    }
    Write-Host ""
    
    # Check Python
    try {
        $pythonVersion = python --version 2>&1
        Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green
    } catch {
        Write-Host "❌ Python is not installed" -ForegroundColor Red
        Write-Host "   Install from: https://www.python.org/downloads/" -ForegroundColor Yellow
        $missingDeps = $true
    }
    
    # Check AWS CLI
    try {
        $awsVersion = aws --version 2>&1
        Write-Host "✅ AWS CLI: $awsVersion" -ForegroundColor Green
    } catch {
        Write-Host "❌ AWS CLI is not installed" -ForegroundColor Red
        Write-Host "   Install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
        $missingDeps = $true
    }
    
    # Check Node.js
    try {
        $nodeVersion = node --version 2>&1
        Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
    } catch {
        Write-Host "❌ Node.js is not installed (required for AWS CDK)" -ForegroundColor Red
        Write-Host ""
        Write-Host "   📥 Install Node.js:" -ForegroundColor Yellow
        Write-Host "   Download from: https://nodejs.org/ (LTS version recommended)" -ForegroundColor Yellow
        Write-Host ""
        $missingDeps = $true
    }
    
    # Check npm
    try {
        $npmVersion = npm --version 2>&1
        Write-Host "✅ npm: $npmVersion" -ForegroundColor Green
    } catch {
        Write-Host "❌ npm is not installed (comes with Node.js)" -ForegroundColor Red
        $missingDeps = $true
    }
    
    # Check CDK
    try {
        $cdkVersionOutput = cdk --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Extract version number (e.g., "2.1033.0" from output)
            if ($cdkVersionOutput -match '(\d+\.\d+\.\d+)') {
                $cdkVersion = $matches[1]
                Write-Host "✅ AWS CDK: $cdkVersion" -ForegroundColor Green
                
                # Check if CDK version is compatible (should be 2.1000.0 or later for schema 48.0.0)
                $versionParts = $cdkVersion.Split('.')
                $major = [int]$versionParts[0]
                $minor = [int]$versionParts[1]
                
                if ($major -lt 2 -or ($major -eq 2 -and $minor -lt 1000)) {
                    Write-Host "⚠️  CDK CLI version is outdated (found $cdkVersion, need 2.1000.0+)" -ForegroundColor Yellow
                    Write-Host ""
                    $upgrade = Read-Host "   Upgrade AWS CDK now? (y/n)"
                    if ($upgrade -eq "y" -or $upgrade -eq "Y") {
                        Write-Host "   Upgrading AWS CDK to latest version..." -ForegroundColor Yellow
                        npm install -g aws-cdk@latest
                        $newVersion = cdk --version 2>&1
                        Write-Host "✅ AWS CDK upgraded to: $newVersion" -ForegroundColor Green
                    } else {
                        Write-Host "⚠️  Warning: CDK version mismatch may cause deployment issues" -ForegroundColor Yellow
                        Write-Host "   Upgrade manually with: npm install -g aws-cdk@latest" -ForegroundColor Gray
                    }
                }
            } else {
                Write-Host "✅ AWS CDK: $cdkVersionOutput" -ForegroundColor Green
            }
        } else {
            throw "CDK not found"
        }
    } catch {
        Write-Host "⚠️  AWS CDK is not installed" -ForegroundColor Yellow
        Write-Host ""
        $install = Read-Host "   Install AWS CDK now? (y/n)"
        if ($install -eq "y" -or $install -eq "Y") {
            Write-Host "   Installing AWS CDK globally..." -ForegroundColor Yellow
            npm install -g aws-cdk@latest
            $cdkVersion = cdk --version 2>&1
            Write-Host "✅ AWS CDK installed: $cdkVersion" -ForegroundColor Green
        } else {
            Write-Host "❌ AWS CDK is required. Install with: npm install -g aws-cdk@latest" -ForegroundColor Red
            $missingDeps = $true
        }
    }
    
    # Check AWS credentials
    try {
        $awsAccount = aws sts get-caller-identity --query Account --output text 2>&1
        $awsUser = aws sts get-caller-identity --query Arn --output text 2>&1
        Write-Host "✅ AWS Account: $awsAccount" -ForegroundColor Green
        Write-Host "   Identity: $awsUser" -ForegroundColor Gray
    } catch {
        Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
        Write-Host "   Run: aws configure" -ForegroundColor Yellow
        $missingDeps = $true
    }
    
    # Check Bedrock model access
    Write-Host ""
    Write-Host "Checking Bedrock model access..." -ForegroundColor Yellow
    try {
        $bedrockModels = aws bedrock list-foundation-models --region us-east-1 --query 'modelSummaries[?contains(modelId, `claude-3-5-sonnet`) || contains(modelId, `titan-embed`)].modelId' --output text 2>&1
        if ($bedrockModels) {
            Write-Host "✅ Bedrock models accessible" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Unable to verify Bedrock model access" -ForegroundColor Yellow
            Write-Host "   Make sure you have access to:" -ForegroundColor Yellow
            Write-Host "   - Claude 3.5 Sonnet" -ForegroundColor Yellow
            Write-Host "   - Titan Text Embeddings V2" -ForegroundColor Yellow
            Write-Host "   Request access at: https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Unable to check Bedrock access" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    if ($missingDeps) {
        Write-Host "❌ Missing required dependencies. Please install them and try again." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ All prerequisites met!" -ForegroundColor Green
    Write-Host ""
}

function Install-Dependencies {
    Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
    
    if (Test-Path "requirements.txt") {
        python -m pip install -r requirements.txt
        Write-Host "✅ Dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "❌ requirements.txt not found" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
}

function Bootstrap-CDK {
    Write-Host "Bootstrapping AWS CDK..." -ForegroundColor Yellow
    
    $awsAccount = aws sts get-caller-identity --query Account --output text
    $awsRegion = "us-east-1"
    
    Write-Host "Account: $awsAccount" -ForegroundColor Gray
    Write-Host "Region: $awsRegion" -ForegroundColor Gray
    
    cdk bootstrap "aws://$awsAccount/$awsRegion"
    
    Write-Host "✅ CDK bootstrapped" -ForegroundColor Green
    Write-Host ""
}

function Synth-Stack {
    Write-Host "Synthesizing CDK stack..." -ForegroundColor Yellow
    cdk synth
    Write-Host "✅ Stack synthesized" -ForegroundColor Green
    Write-Host ""
}

function Deploy-Stack {
    Write-Host "Deploying CDK stack..." -ForegroundColor Yellow
    Write-Host "⚠️  This will create AWS resources that may incur costs" -ForegroundColor Yellow
    Write-Host ""
    
    cdk deploy --require-approval never
    
    Write-Host ""
    Write-Host "✅ Stack deployed successfully!" -ForegroundColor Green
    Write-Host ""
}

function Get-Outputs {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Deployment Complete!" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Getting stack outputs..." -ForegroundColor Yellow
    
    $stackName = "WellArchitectedReviewUsingGenAIStack"
    
    try {
        $cloudFrontUrl = aws cloudformation describe-stacks --stack-name $stackName --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' --output text --region us-east-1 2>$null
        $userPoolId = aws cloudformation describe-stacks --stack-name $stackName --query 'Stacks[0].Outputs[?OutputKey==`CognitoUserPoolId`].OutputValue' --output text --region us-east-1 2>$null
        
        Write-Host ""
        Write-Host "📋 Stack Outputs:" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
        Write-Host "Application URL: $cloudFrontUrl" -ForegroundColor Green
        Write-Host "Cognito User Pool ID: $userPoolId" -ForegroundColor Gray
        Write-Host ""
        Write-Host "To view all outputs:" -ForegroundColor Yellow
        Write-Host "  aws cloudformation describe-stacks --stack-name $stackName --query 'Stacks[0].Outputs' --region us-east-1" -ForegroundColor Gray
        Write-Host ""
    } catch {
        Write-Host "⚠️  Could not retrieve stack outputs" -ForegroundColor Yellow
    }
}

function Create-User {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Create Cognito User" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $stackName = "WellArchitectedReviewUsingGenAIStack"
    
    try {
        $userPoolId = aws cloudformation describe-stacks --stack-name $stackName --query 'Stacks[0].Outputs[?OutputKey==`CognitoUserPoolId`].OutputValue' --output text --region us-east-1 2>$null
        
        if (-not $userPoolId -or $userPoolId -eq "None") {
            Write-Host "❌ Could not find Cognito User Pool ID" -ForegroundColor Red
            Write-Host "Make sure the stack is deployed first" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "User Pool ID: $userPoolId" -ForegroundColor Gray
        Write-Host ""
        
        $username = Read-Host "Enter username"
        $email = Read-Host "Enter email"
        $password = Read-Host "Enter password" -AsSecureString
        $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        
        Write-Host ""
        Write-Host "Creating user..." -ForegroundColor Yellow
        
        aws cognito-idp admin-create-user --user-pool-id $userPoolId --username $username --user-attributes Name=email,Value=$email Name=email_verified,Value=true --temporary-password "TempPass123!" --region us-east-1
        
        Write-Host ""
        Write-Host "Setting permanent password..." -ForegroundColor Yellow
        
        aws cognito-idp admin-set-user-password --user-pool-id $userPoolId --username $username --password $passwordPlain --permanent --region us-east-1
        
        Write-Host ""
        Write-Host "✅ User created successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Username: $username" -ForegroundColor Cyan
        Write-Host "Email: $email" -ForegroundColor Gray
        Write-Host ""
    } catch {
        Write-Host "❌ Error creating user: $_" -ForegroundColor Red
        exit 1
    }
}

function Destroy-Stack {
    Write-Host "⚠️  This will destroy all resources created by the stack" -ForegroundColor Yellow
    $confirm = Read-Host "Are you sure? (yes/no)"
    if ($confirm -eq "yes") {
        cdk destroy
    } else {
        Write-Host "Cancelled" -ForegroundColor Yellow
    }
}

# Main script logic
switch ($args[0]) {
    "pre-req" {
        Check-Prerequisites
        Install-Dependencies
        Bootstrap-CDK
    }
    "deploy" {
        Synth-Stack
        Deploy-Stack
        Get-Outputs
    }
    "post-deploy" {
        Create-User
    }
    "destroy" {
        Destroy-Stack
    }
    "outputs" {
        Get-Outputs
    }
    default {
        Write-Host "Usage: .\deploy.ps1 {pre-req|deploy|post-deploy|destroy|outputs}" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Cyan
        Write-Host "  pre-req      - Check prerequisites, install dependencies, bootstrap CDK" -ForegroundColor Gray
        Write-Host "  deploy       - Deploy the CDK stack" -ForegroundColor Gray
        Write-Host "  post-deploy  - Create Cognito user" -ForegroundColor Gray
        Write-Host "  destroy      - Destroy the CDK stack" -ForegroundColor Gray
        Write-Host "  outputs      - Display stack outputs" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Example:" -ForegroundColor Yellow
        Write-Host "  .\deploy.ps1 pre-req" -ForegroundColor Gray
        Write-Host "  .\deploy.ps1 deploy" -ForegroundColor Gray
        Write-Host "  .\deploy.ps1 post-deploy" -ForegroundColor Gray
        exit 1
    }
}
