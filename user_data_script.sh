#!/bin/bash
# WAFR EC2 Instance User Data Script
# This script runs on first boot to set up the instance

# Exit on error but continue logging
set -e
set -o pipefail

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

# Function to retry commands
retry_command() {
    local max_attempts=3
    local attempt=1
    local delay=5
    
    while [ $attempt -le $max_attempts ]; do
        if "$@"; then
            return 0
        else
            echo "Attempt $attempt failed. Retrying in $delay seconds..."
            sleep $delay
            attempt=$((attempt + 1))
            delay=$((delay * 2))
        fi
    done
    
    echo "Command failed after $max_attempts attempts: $*"
    return 1
}

echo "=========================================="
echo "WAFR Instance Setup - $(date)"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
retry_command yum update -y

# Install Python 3.11 and dependencies
echo "Installing Python 3.11 and dependencies..."
retry_command yum install -y python3.11 python3.11-pip git unzip

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

# Download application code from S3 with retry
echo "Downloading application code from S3..."
retry_command aws s3 sync s3://{{APP_BUCKET}}/ /opt/wafr-app/ --region {{REGION}}

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

# Install Python dependencies with retry
echo "Installing dependencies from requirements.txt..."
retry_command python3.11 -m pip install --upgrade pip
retry_command python3.11 -m pip install -r /opt/wafr-app/requirements.txt --timeout 300

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

# Start service with retry logic
MAX_START_ATTEMPTS=3
START_ATTEMPT=1
while [ $START_ATTEMPT -le $MAX_START_ATTEMPTS ]; do
    echo "Starting Streamlit service (attempt $START_ATTEMPT)..."
    systemctl start wafr-streamlit.service
    sleep 10
    
    if systemctl is-active --quiet wafr-streamlit.service; then
        echo "Streamlit service started successfully!"
        break
    else
        echo "Service failed to start. Checking logs..."
        journalctl -u wafr-streamlit.service -n 50 --no-pager
        
        if [ $START_ATTEMPT -eq $MAX_START_ATTEMPTS ]; then
            echo "ERROR: Failed to start Streamlit service after $MAX_START_ATTEMPTS attempts"
            exit 1
        fi
        
        START_ATTEMPT=$((START_ATTEMPT + 1))
        sleep 5
    fi
done

echo "=========================================="
echo "Waiting for Application to Start - $(date)"
echo "=========================================="

# Wait for application to be ready (max 10 minutes)
echo "Waiting for Streamlit to respond on port 8501..."
COUNTER=0
MAX_ATTEMPTS=120
WAIT_INTERVAL=5

until curl -sf http://localhost:8501 > /dev/null 2>&1 || [ $COUNTER -eq $MAX_ATTEMPTS ]; do
    echo "Attempt $((COUNTER+1))/$MAX_ATTEMPTS - Waiting for Streamlit..."
    
    # Check if service is still running
    if ! systemctl is-active --quiet wafr-streamlit.service; then
        echo "ERROR: Streamlit service stopped unexpectedly!"
        systemctl status wafr-streamlit.service --no-pager
        tail -n 100 /var/log/wafr-streamlit.log
        exit 1
    fi
    
    sleep $WAIT_INTERVAL
    COUNTER=$((COUNTER+1))
done

if [ $COUNTER -eq $MAX_ATTEMPTS ]; then
    echo "ERROR: Streamlit did not respond within 10 minutes"
    echo "Service status:"
    systemctl status wafr-streamlit.service --no-pager
    echo ""
    echo "Last 100 lines of Streamlit logs:"
    tail -n 100 /var/log/wafr-streamlit.log
    echo ""
    echo "Checking if port 8501 is listening:"
    netstat -tlnp | grep 8501 || echo "Port 8501 is not listening"
    exit 1
else
    echo "SUCCESS: Streamlit is responding on port 8501!"
    
    # Verify the app is actually working
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8501)
    echo "HTTP response code: $HTTP_CODE"
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "Application is healthy and ready!"
        touch /opt/wafr-app/.deployment-complete
        
        # Send success signal to CloudFormation if available
        if command -v cfn-signal &> /dev/null; then
            echo "Sending success signal to CloudFormation..."
            cfn-signal -e 0 --stack {{STACK_NAME}} --resource StreamlitAppInstance --region {{REGION}} || true
        fi
    else
        echo "WARNING: Application returned HTTP $HTTP_CODE instead of 200"
        exit 1
    fi
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
