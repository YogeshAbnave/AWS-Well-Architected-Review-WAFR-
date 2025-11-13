#!/bin/bash
# Deployment diagnostic script
# Run this to check why the application isn't working

INSTANCE_ID="$1"
REGION="${2:-us-east-1}"

if [ -z "$INSTANCE_ID" ]; then
    echo "Usage: $0 <instance-id> [region]"
    echo "Example: $0 i-0db5fe0d9d71c02cd us-east-1"
    exit 1
fi

echo "=========================================="
echo "WAFR Deployment Diagnostic"
echo "Instance: $INSTANCE_ID"
echo "Region: $REGION"
echo "=========================================="
echo ""

# Check instance status
echo "1. Checking EC2 instance status..."
aws ec2 describe-instance-status \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query "InstanceStatuses[0].{State:InstanceState.Name,SystemStatus:SystemStatus.Status,InstanceStatus:InstanceStatus.Status}" \
    --output table

echo ""

# Check target health
echo "2. Checking ALB target health..."
TARGET_GROUPS=$(aws elbv2 describe-target-groups --region "$REGION" --query "TargetGroups[?contains(TargetGroupName, 'Streamlit')].TargetGroupArn" --output text)

if [ -n "$TARGET_GROUPS" ]; then
    for TG in $TARGET_GROUPS; do
        echo "Target Group: $TG"
        aws elbv2 describe-target-health \
            --target-group-arn "$TG" \
            --region "$REGION" \
            --query "TargetHealthDescriptions[*].{Target:Target.Id,Port:Target.Port,Health:TargetHealth.State,Reason:TargetHealth.Reason,Description:TargetHealth.Description}" \
            --output table
    done
else
    echo "No target groups found"
fi

echo ""

# Get user data execution log via SSM
echo "3. Checking user data execution (last 50 lines)..."
echo "Connecting via SSM..."

aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["tail -n 50 /var/log/user-data.log"]' \
    --query "Command.CommandId" \
    --output text > /tmp/command-id.txt

COMMAND_ID=$(cat /tmp/command-id.txt)
echo "Command ID: $COMMAND_ID"
echo "Waiting for command to complete..."
sleep 5

aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --region "$REGION" \
    --query "StandardOutputContent" \
    --output text

echo ""

# Check Streamlit service status
echo "4. Checking Streamlit service status..."
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["systemctl status wafr-streamlit.service --no-pager"]' \
    --query "Command.CommandId" \
    --output text > /tmp/command-id2.txt

COMMAND_ID2=$(cat /tmp/command-id2.txt)
sleep 5

aws ssm get-command-invocation \
    --command-id "$COMMAND_ID2" \
    --instance-id "$INSTANCE_ID" \
    --region "$REGION" \
    --query "StandardOutputContent" \
    --output text

echo ""

# Check if Streamlit is listening on port 8501
echo "5. Checking if port 8501 is listening..."
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["netstat -tlnp | grep 8501 || echo \"Port 8501 not listening\""]' \
    --query "Command.CommandId" \
    --output text > /tmp/command-id3.txt

COMMAND_ID3=$(cat /tmp/command-id3.txt)
sleep 5

aws ssm get-command-invocation \
    --command-id "$COMMAND_ID3" \
    --instance-id "$INSTANCE_ID" \
    --region "$REGION" \
    --query "StandardOutputContent" \
    --output text

echo ""

# Check Streamlit logs
echo "6. Checking Streamlit application logs (last 50 lines)..."
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["tail -n 50 /var/log/wafr-streamlit.log 2>/dev/null || echo \"Log file not found\""]' \
    --query "Command.CommandId" \
    --output text > /tmp/command-id4.txt

COMMAND_ID4=$(cat /tmp/command-id4.txt)
sleep 5

aws ssm get-command-invocation \
    --command-id "$COMMAND_ID4" \
    --instance-id "$INSTANCE_ID" \
    --region "$REGION" \
    --query "StandardOutputContent" \
    --output text

echo ""
echo "=========================================="
echo "Diagnostic complete!"
echo "=========================================="
