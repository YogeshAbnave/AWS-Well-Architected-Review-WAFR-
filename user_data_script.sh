#!/bin/bash
# User data script for WAFR Accelerator EC2 instance

# Set variables
REGION="{{REGION}}"
APP_BUCKET="{{APP_BUCKET}}"
STACK_NAME="{{STACK_NAME}}"

# Update system
yum update -y

# Install required packages
yum install -y python3.12 python3.12-pip git docker

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Create application directory
mkdir -p /home/ec2-user/wafr-app
cd /home/ec2-user/wafr-app

# Download application files from S3
aws s3 sync s3://${APP_BUCKET}/app/ /home/ec2-user/wafr-app/ --region ${REGION}

# Install Python dependencies
python3.12 -m pip install --upgrade pip
python3.12 -m pip install -r requirements.txt

# Create systemd service for Streamlit
cat > /etc/systemd/system/streamlit.service <<EOF
[Unit]
Description=Streamlit WAFR Accelerator
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/wafr-app
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/local/bin/streamlit run ui_code/WAFR_Accelerator.py --server.port 8501 --server.address 0.0.0.0
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chown -R ec2-user:ec2-user /home/ec2-user/wafr-app

# Enable and start Streamlit service
systemctl daemon-reload
systemctl enable streamlit
systemctl start streamlit

# Configure CloudWatch Logs
yum install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
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

# Signal completion
echo "User data script completed successfully"
