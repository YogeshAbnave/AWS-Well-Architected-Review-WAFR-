#!/bin/bash

# Check WAFR Application Status

INSTANCE_ID="i-08fb7dd51bc58e7c5"
REGION="us-east-1"

echo "=========================================="
echo "WAFR Application Status Check"
echo "=========================================="
echo ""

echo "Checking EC2 instance status..."
aws ec2 describe-instance-status \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'InstanceStatuses[0].[InstanceStatus.Status,SystemStatus.Status]' \
    --output table

echo ""
echo "Checking if Streamlit is running..."
echo "Fetching system log (last 50 lines)..."
echo ""

aws ec2 get-console-output \
    --instance-id $INSTANCE_ID \
    --region $REGION \
    --query 'Output' \
    --output text | tail -50

echo ""
echo "=========================================="
echo "If you see 'Streamlit' in the logs above, the app is starting"
echo "Wait a few more minutes and try accessing:"
echo "https://d1l6el5gosn1nh.cloudfront.net"
echo "=========================================="
