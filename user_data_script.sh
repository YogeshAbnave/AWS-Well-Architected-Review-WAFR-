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
export AWS_REGION={{REGION}}
echo "export AWS_DEFAULT_REGION={{REGION}}" >> /etc/profile.d/aws-region.sh
echo "export AWS_REGION={{REGION}}" >> /etc/profile.d/aws-region.sh

# Create application directory
echo "Creating application directory..."
mkdir -p /opt/wafr-app
cd /opt/wafr-app

echo "=========================================="
echo "Deploying Application Code - $(date)"
echo "=========================================="

# Download application code from S3
echo "Downloading application code from S3..."
aws s3 sync s3://{{APP_BUCKET}}/ /opt/wafr-app/ --region {{REGION}}

# Verify critical files exist
if [ ! -f "/opt/wafr-app/ui_code/WAFR_Accelerator.py" ]; then
    echo "ERROR: WAFR_Accelerator.py not found after deployment!"
    exit 1
fi

if [ ! -f "/opt/wafr-app/requirements.txt" ]; then
    echo "ERROR: requirements.txt not found after deployment!"
    exit 1
fi

echo "Application code deployed successfully"

# Set ownership
echo "Setting file ownership..."
chown -R ec2-user:ec2-user /opt/wafr-app

echo "=========================================="
echo "Installing Python Dependencies - $(date)"
echo "=========================================="

# Install Python dependencies
echo "Installing dependencies from requirements.txt..."
python3.11 -m pip install --upgrade pip
python3.11 -m pip install -r /opt/wafr-app/requirements.txt

# Verify critical packages
echo "Verifying critical packages..."
python3.11 -c "import streamlit; print(f'Streamlit version: {streamlit.__version__}')"
python3.11 -c "import boto3; print(f'Boto3 version: {boto3.__version__}')"
python3.11 -c "import langchain; print(f'LangChain version: {langchain.__version__}')"

# Create marker file
touch /opt/wafr-app/.dependencies-installed
echo "Dependencies installed successfully"

echo "=========================================="
echo "Creating Systemd Service - $(date)"
echo "=========================================="

# Create systemd service file
cat > /etc/systemd/system/wafr-streamlit.service << 'EOF'
[Unit]
Description=WAFR Streamlit Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/wafr-app
Environment="AWS_DEFAULT_REGION={{REGION}}"
Environment="AWS_REGION={{REGION}}"
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/local/bin/streamlit run ui_code/WAFR_Accelerator.py --server.port 8501 --server.address 0.0.0.0
Restart=always
RestartSec=10
StandardOutput=append:/var/log/wafr-streamlit.log
StandardError=append:/var/log/wafr-streamlit.log

[Install]
WantedBy=multi-user.target
EOF

# Replace region placeholder in service file
sed -i "s/{{REGION}}/{{REGION}}/g" /etc/systemd/system/wafr-streamlit.service

# Create log file with proper permissions
touch /var/log/wafr-streamlit.log
chown ec2-user:ec2-user /var/log/wafr-streamlit.log

# Reload systemd, enable and start service
echo "Enabling and starting WAFR Streamlit service..."
systemctl daemon-reload
systemctl enable wafr-streamlit.service
systemctl start wafr-streamlit.service

echo "=========================================="
echo "Waiting for Application to Start - $(date)"
echo "=========================================="

# Wait for application to be ready (max 5 minutes)
echo "Waiting for Streamlit to respond on port 8501..."
COUNTER=0
MAX_ATTEMPTS=60
until curl -s http://localhost:8501 > /dev/null 2>&1 || [ $COUNTER -eq $MAX_ATTEMPTS ]; do
    echo "Attempt $((COUNTER+1))/$MAX_ATTEMPTS - Waiting for Streamlit..."
    sleep 5
    COUNTER=$((COUNTER+1))
done

if [ $COUNTER -eq $MAX_ATTEMPTS ]; then
    echo "WARNING: Streamlit did not respond within 5 minutes"
    echo "Checking service status..."
    systemctl status wafr-streamlit.service --no-pager
    echo ""
    echo "Last 50 lines of Streamlit logs:"
    tail -n 50 /var/log/wafr-streamlit.log
else
    echo "Streamlit is responding on port 8501!"
    echo "Verifying health endpoint..."
    curl -s http://localhost:8501/_stcore/health || echo "Health endpoint check failed, but main app is running"
    touch /opt/wafr-app/.deployment-complete
fi

echo "=========================================="
echo "Setup Completed - $(date)"
echo "=========================================="
echo ""
echo "Service Status:"
systemctl status wafr-streamlit.service --no-pager
echo ""
echo "Application is running at http://localhost:8501"
echo "Logs available at: /var/log/wafr-streamlit.log"
echo ""
