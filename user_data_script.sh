#!/bin/bash
# User data script for WAFR Accelerator EC2 instance
set -e

# Logging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting user data script at $(date)"

# Set variables
REGION="{{REGION}}"
APP_BUCKET="{{APP_BUCKET}}"
STACK_NAME="{{STACK_NAME}}"

# Update system
echo "Updating system packages..."
yum update -y

# Install required packages
echo "Installing required packages..."
yum install -y python3.12 python3.12-pip git unzip

# Install AWS CLI v2
echo "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Create application directory
echo "Creating application directory..."
mkdir -p /home/ec2-user/wafr-app
cd /home/ec2-user/wafr-app

# Download application files from S3 with retry logic
echo "Downloading application files from S3..."
MAX_RETRIES=10
RETRY_COUNT=0
DOWNLOAD_SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES..."
    
    # Check if bucket has files
    if aws s3 ls s3://${APP_BUCKET}/ --region ${REGION} 2>/dev/null | grep -q .; then
        echo "S3 bucket found with files. Downloading..."
        if aws s3 sync s3://${APP_BUCKET}/ /home/ec2-user/wafr-app/ --region ${REGION} --exclude "cdk.out/*" --exclude ".git/*"; then
            # Verify critical files exist
            if [ -f "ui_code/WAFR_Accelerator.py" ] && [ -f "requirements.txt" ]; then
                echo "✅ Application files downloaded successfully!"
                DOWNLOAD_SUCCESS=true
                break
            else
                echo "⚠️ Download completed but critical files missing. Retrying..."
            fi
        else
            echo "⚠️ S3 sync failed. Retrying..."
        fi
    else
        echo "⚠️ S3 bucket empty or not ready. Waiting 30 seconds..."
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        sleep 30
    fi
done

# If download failed after all retries, create placeholder
if [ "$DOWNLOAD_SUCCESS" = false ]; then
    echo "❌ Failed to download from S3 after $MAX_RETRIES attempts. Creating placeholder..."
    mkdir -p ui_code
    cat > ui_code/WAFR_Accelerator.py <<'PYEOF'
import streamlit as st
import time

st.set_page_config(page_title="WAFR Accelerator", layout="wide")

st.title("🚀 WAFR Accelerator")
st.error("Application files could not be downloaded from S3.")
st.info("Please check CloudWatch logs at /aws/ec2/wafr-streamlit for details.")

st.write("**Troubleshooting:**")
st.write("1. Verify S3 bucket deployment completed")
st.write("2. Check EC2 IAM role has S3 read permissions")
st.write("3. SSH into instance and manually sync from S3")
st.write(f"Region: {REGION}")
PYEOF

    cat > requirements.txt <<'REQEOF'
streamlit==1.31.0
boto3==1.34.0
REQEOF
fi

# Install Python dependencies
echo "Installing Python dependencies..."
python3.12 -m pip install --upgrade pip
python3.12 -m pip install -r requirements.txt

# Create Streamlit config directory
mkdir -p /home/ec2-user/.streamlit

# Create Streamlit config
cat > /home/ec2-user/.streamlit/config.toml <<EOF
[server]
port = 8501
address = "0.0.0.0"
headless = true
enableCORS = false
enableXsrfProtection = false

[browser]
gatherUsageStats = false
EOF

# Create systemd service for Streamlit
echo "Creating Streamlit systemd service..."
cat > /etc/systemd/system/streamlit.service <<EOF
[Unit]
Description=Streamlit WAFR Accelerator
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/wafr-app
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="HOME=/home/ec2-user"
ExecStart=/usr/local/bin/streamlit run ui_code/WAFR_Accelerator.py --server.port 8501 --server.address 0.0.0.0
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
echo "Setting permissions..."
chown -R ec2-user:ec2-user /home/ec2-user/wafr-app
chown -R ec2-user:ec2-user /home/ec2-user/.streamlit

# Enable and start Streamlit service
echo "Starting Streamlit service..."
systemctl daemon-reload
systemctl enable streamlit
systemctl start streamlit

# Wait for Streamlit to start
echo "Waiting for Streamlit to start..."
sleep 10

# Check if Streamlit is running
if systemctl is-active --quiet streamlit; then
    echo "✅ Streamlit service is running"
else
    echo "❌ Streamlit service failed to start"
    systemctl status streamlit
fi

# Configure CloudWatch Logs
echo "Configuring CloudWatch Logs..."
yum install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/aws/ec2/wafr-streamlit",
            "log_stream_name": "{instance_id}/user-data"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/wafr-streamlit",
            "log_stream_name": "{instance_id}/system"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

echo "User data script completed successfully at $(date)"
