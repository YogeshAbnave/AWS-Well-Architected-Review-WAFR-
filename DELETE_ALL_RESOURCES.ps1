# Delete ALL AWS Resources for WAFR Stack
$stackName = "WellArchitectedReviewUsingGenAIStack"
$region = "us-east-1"

Write-Host "========================================" -ForegroundColor Red
Write-Host "DELETING ALL AWS RESOURCES" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# Step 1: Delete CloudFormation Stack
Write-Host "Step 1: Deleting CloudFormation Stack..." -ForegroundColor Yellow
aws cloudformation delete-stack --stack-name $stackName --region $region
Write-Host "   Stack deletion initiated" -ForegroundColor Green
Write-Host ""

# Step 2: Wait for deletion
Write-Host "Step 2: Waiting for stack deletion (this may take 5-10 minutes)..." -ForegroundColor Yellow
Write-Host "   Checking status every 30 seconds..." -ForegroundColor Gray
Write-Host ""

$maxAttempts = 20
$attempt = 0
$deleted = $false

while ($attempt -lt $maxAttempts -and -not $deleted) {
    Start-Sleep -Seconds 30
    $attempt++
    
    try {
        $status = aws cloudformation describe-stacks --stack-name $stackName --region $region --query "Stacks[0].StackStatus" --output text 2>&1
        
        if ($status -match "does not exist") {
            $deleted = $true
            Write-Host "   ✓ Stack successfully deleted!" -ForegroundColor Green
        } else {
            Write-Host "   Attempt $attempt/$maxAttempts - Status: $status" -ForegroundColor Gray
        }
    } catch {
        $deleted = $true
        Write-Host "   ✓ Stack successfully deleted!" -ForegroundColor Green
    }
}

if (-not $deleted) {
    Write-Host "   ⚠ Stack deletion taking longer than expected" -ForegroundColor Yellow
    Write-Host "   Check status manually: aws cloudformation describe-stacks --stack-name $stackName --region $region" -ForegroundColor Gray
}

Write-Host ""

# Step 3: Clean up any remaining S3 buckets
Write-Host "Step 3: Checking for remaining S3 buckets..." -ForegroundColor Yellow
$buckets = aws s3 ls | Select-String "wafr-accelerator|wafr-prompts"

if ($buckets) {
    Write-Host "   Found buckets to delete:" -ForegroundColor Yellow
    foreach ($bucket in $buckets) {
        $bucketName = ($bucket -split '\s+')[-1]
        Write-Host "   Deleting bucket: $bucketName" -ForegroundColor Gray
        
        # Empty bucket first
        aws s3 rm "s3://$bucketName" --recursive --region $region 2>$null
        
        # Delete bucket
        aws s3 rb "s3://$bucketName" --region $region 2>$null
    }
    Write-Host "   ✓ S3 buckets cleaned up" -ForegroundColor Green
} else {
    Write-Host "   ✓ No S3 buckets found" -ForegroundColor Green
}

Write-Host ""

# Step 4: Clean up CloudWatch Log Groups
Write-Host "Step 4: Checking for CloudWatch Log Groups..." -ForegroundColor Yellow
$logGroups = aws logs describe-log-groups --region $region --query "logGroups[?contains(logGroupName, 'wafr-streamlit')].logGroupName" --output text

if ($logGroups) {
    foreach ($logGroup in $logGroups -split '\s+') {
        if ($logGroup) {
            Write-Host "   Deleting log group: $logGroup" -ForegroundColor Gray
            aws logs delete-log-group --log-group-name $logGroup --region $region 2>$null
        }
    }
    Write-Host "   ✓ Log groups cleaned up" -ForegroundColor Green
} else {
    Write-Host "   ✓ No log groups found" -ForegroundColor Green
}

Write-Host ""

# Step 5: Verify cleanup
Write-Host "Step 5: Verifying cleanup..." -ForegroundColor Yellow

# Check stack
try {
    $stackExists = aws cloudformation describe-stacks --stack-name $stackName --region $region 2>&1
    if ($stackExists -match "does not exist") {
        Write-Host "   ✓ CloudFormation stack: DELETED" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ CloudFormation stack: Still exists" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✓ CloudFormation stack: DELETED" -ForegroundColor Green
}

# Check EC2 instances
$instances = aws ec2 describe-instances --region $region --filters "Name=tag:aws:cloudformation:stack-name,Values=$stackName" --query "Reservations[].Instances[?State.Name!='terminated'].InstanceId" --output text

if ($instances) {
    Write-Host "   ⚠ EC2 instances: $instances still exist" -ForegroundColor Yellow
} else {
    Write-Host "   ✓ EC2 instances: DELETED" -ForegroundColor Green
}

# Check VPCs
$vpcs = aws ec2 describe-vpcs --region $region --filters "Name=tag:aws:cloudformation:stack-name,Values=$stackName" --query "Vpcs[].VpcId" --output text

if ($vpcs) {
    Write-Host "   ⚠ VPCs: $vpcs still exist" -ForegroundColor Yellow
} else {
    Write-Host "   ✓ VPCs: DELETED" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CLEANUP COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All resources have been deleted or are being deleted." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Push your code to Git" -ForegroundColor White
Write-Host "2. Your CI/CD will deploy fresh with all fixes" -ForegroundColor White
Write-Host "3. Application will be accessible in 15-20 minutes" -ForegroundColor White
Write-Host ""
