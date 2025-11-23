# Docker Setup and Troubleshooting Guide

## Overview

This CDK deployment requires Docker to build container images for AWS Lambda functions and custom resources. The `cdklabs.generative_ai_cdk_constructs` library uses Docker to package OpenSearch Serverless custom resources.

## Prerequisites

- Docker Desktop 20.10.0 or later
- At least 4GB of RAM allocated to Docker
- Sufficient disk space (at least 10GB free)

## Installation

### Windows

1. **Download Docker Desktop**
   - Visit: https://www.docker.com/products/docker-desktop
   - Download Docker Desktop for Windows
   - Run the installer

2. **System Requirements**
   - Windows 10 64-bit: Pro, Enterprise, or Education (Build 19041 or higher)
   - OR Windows 11 64-bit: Home, Pro, Enterprise, or Education
   - WSL 2 backend (recommended) or Hyper-V backend

3. **Enable WSL 2 (Recommended)**
   ```powershell
   # Run in PowerShell as Administrator
   wsl --install
   wsl --set-default-version 2
   ```

4. **Start Docker Desktop**
   - Launch Docker Desktop from Start Menu
   - Wait for Docker to fully start (check system tray icon)
   - Icon should show "Docker Desktop is running"

5. **Verify Installation**
   ```powershell
   docker --version
   docker info
   ```

### macOS

1. **Download Docker Desktop**
   - Visit: https://www.docker.com/products/docker-desktop
   - Download Docker Desktop for Mac (Intel or Apple Silicon)
   - Drag Docker.app to Applications folder

2. **Start Docker Desktop**
   - Open Docker from Applications or Spotlight
   - Grant necessary permissions when prompted
   - Wait for Docker to start (check menu bar icon)

3. **Verify Installation**
   ```bash
   docker --version
   docker info
   ```

### Linux

1. **Install Docker Engine**
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install docker.io
   
   # CentOS/RHEL
   sudo yum install docker
   
   # Fedora
   sudo dnf install docker
   ```

2. **Start Docker Service**
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

3. **Add User to Docker Group** (optional, to run without sudo)
   ```bash
   sudo usermod -aG docker $USER
   # Log out and back in for changes to take effect
   ```

4. **Verify Installation**
   ```bash
   docker --version
   docker info
   ```

## Common Issues and Solutions

### Issue 1: "Docker daemon is not running"

**Error Message:**
```
error during connect: Get "http://%2F%2F.%2Fpipe%2FdockerDesktopLinuxEngine/v1.51/info": 
open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.
```

**Solution (Windows):**
1. Open Docker Desktop from Start Menu
2. Wait 30-60 seconds for Docker to fully start
3. Check system tray - Docker icon should show "Docker Desktop is running"
4. Run `docker info` to verify

**Solution (macOS):**
1. Open Docker Desktop from Applications
2. Check menu bar - Docker icon should be steady (not animated)
3. Run `docker info` to verify

**Solution (Linux):**
```bash
sudo systemctl start docker
sudo systemctl status docker
```

### Issue 2: "Permission denied" when running Docker

**Error Message:**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution (Linux):**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, then verify
docker info
```

**Solution (Windows/macOS):**
- Ensure Docker Desktop is running with proper permissions
- Try restarting Docker Desktop

### Issue 3: Docker build fails during CDK deployment

**Error Message:**
```
RuntimeError: docker exited with status 1
```

**Solutions:**
1. **Check Docker is running:**
   ```bash
   docker info
   ```

2. **Check disk space:**
   ```bash
   docker system df
   # Clean up if needed
   docker system prune -a
   ```

3. **Increase Docker resources:**
   - Open Docker Desktop Settings
   - Go to Resources
   - Increase Memory to at least 4GB
   - Increase Disk space if needed
   - Click "Apply & Restart"

4. **Check Docker version:**
   ```bash
   docker --version
   # Should be 20.10.0 or later
   ```

### Issue 4: WSL 2 not enabled (Windows)

**Error Message:**
```
WSL 2 installation is incomplete
```

**Solution:**
```powershell
# Run in PowerShell as Administrator
wsl --install
wsl --set-default-version 2

# Restart computer
# Start Docker Desktop again
```

### Issue 5: Docker Desktop won't start

**Solutions:**

1. **Restart Docker Desktop:**
   - Quit Docker Desktop completely
   - Wait 10 seconds
   - Start Docker Desktop again

2. **Check for updates:**
   - Open Docker Desktop
   - Go to Settings → Software Updates
   - Install any available updates

3. **Reset Docker Desktop:**
   - Open Docker Desktop Settings
   - Go to Troubleshoot
   - Click "Reset to factory defaults"
   - Restart Docker Desktop

4. **Reinstall Docker Desktop:**
   - Uninstall Docker Desktop
   - Restart computer
   - Download and install latest version

## Validation Script

Before deploying, you can run the validation script to check your Docker setup:

```bash
# Linux/macOS
python3 validate_docker.py

# Windows
python validate_docker.py
```

This will check:
- Docker installation
- Docker daemon status
- Docker version compatibility

## Alternative Deployment Options

If Docker cannot be installed on your machine, consider these alternatives:

### Option 1: Use AWS Cloud9

AWS Cloud9 has Docker pre-installed:

1. Create a Cloud9 environment in AWS Console
2. Clone your repository
3. Run deployment from Cloud9 terminal

### Option 2: Use AWS CloudShell

AWS CloudShell has Docker available:

1. Open CloudShell in AWS Console
2. Upload your code or clone from repository
3. Run deployment from CloudShell

### Option 3: Pre-synthesize on another machine

1. On a machine with Docker, run:
   ```bash
   cdk synth
   ```

2. Copy the `cdk.out` directory to your machine

3. Deploy using the pre-synthesized template:
   ```bash
   cdk deploy --app cdk.out
   ```

## Verifying Docker is Ready

Run this command to verify Docker is properly configured:

```bash
docker run hello-world
```

If you see "Hello from Docker!", your Docker installation is working correctly.

## Getting Help

- Docker Documentation: https://docs.docker.com/
- Docker Desktop Troubleshooting: https://docs.docker.com/desktop/troubleshoot/
- AWS CDK Docker Requirements: https://docs.aws.amazon.com/cdk/v2/guide/docker.html

## Contact

If you continue to experience issues, please check:
1. Docker Desktop is running
2. You have sufficient system resources
3. Your Docker version is up to date
4. You have proper permissions to run Docker
