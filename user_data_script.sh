#!/bin/bash
# WAFR EC2 Instance User Data Script
# This script runs on first boot to set up the instance

set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=========================================="
echo "WAFR Instance Setup - $(date)"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
yum update -y

# Install Python 3.11 and dependencies
echo "Installing Python 3.11 and dependencies..."
yum install -y python3.11 python3.11-pip git unzip

# Install AWS CLI v2
echo "Installing AWS CLI v2..."
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Set AWS region
export AWS_DEFAULT_REGION={{REGION}}
echo "export AWS_DEFAULT_REGION={{REGION}}" >> /etc/profile.d/aws-region.sh

# Create application directory
echo "Creating application directory..."
mkdir -p /opt/wafr-app
cd /opt/wafr-app

# Set ownership
chown -R ec2-user:ec2-user /opt/wafr-app

echo "=========================================="
echo "Setup completed - $(date)"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Deploy application code to /opt/wafr-app"
echo "2. Install Python dependencies: python3.11 -m pip install -r requirements.txt"
echo "3. Start Streamlit: streamlit run ui_code/WAFR_Accelerator.py --server.port 8502"
echo ""
