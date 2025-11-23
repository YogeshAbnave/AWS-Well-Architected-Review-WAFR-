#!/usr/bin/env python3
"""
Docker Environment Validation Script
Checks if Docker is properly installed and running before CDK deployment.
"""

import subprocess
import sys
import platform
from typing import Tuple


def check_docker_installed() -> Tuple[bool, str]:
    """Check if Docker is installed on the system."""
    try:
        result = subprocess.run(
            ["docker", "--version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            version = result.stdout.strip()
            return True, version
        return False, "Docker command failed"
    except FileNotFoundError:
        return False, "Docker is not installed"
    except Exception as e:
        return False, f"Error checking Docker: {str(e)}"


def check_docker_running() -> Tuple[bool, str]:
    """Check if Docker daemon is running and accessible."""
    try:
        result = subprocess.run(
            ["docker", "info"],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            return True, "Docker daemon is running"
        
        # Parse error message for specific issues
        error_output = result.stderr.lower()
        if "cannot connect" in error_output or "pipe" in error_output:
            return False, "Docker daemon is not running. Please start Docker Desktop."
        elif "permission denied" in error_output:
            return False, "Permission denied. Run as administrator or add user to docker group."
        else:
            return False, f"Docker daemon error: {result.stderr[:200]}"
    except subprocess.TimeoutExpired:
        return False, "Docker daemon connection timeout"
    except Exception as e:
        return False, f"Error checking Docker daemon: {str(e)}"


def get_platform_instructions() -> str:
    """Get platform-specific instructions for starting Docker."""
    system = platform.system()
    
    if system == "Windows":
        return """
Windows Instructions:
1. Start Docker Desktop from the Start Menu or Desktop shortcut
2. Wait for Docker Desktop to fully start (check system tray icon)
3. Verify Docker is running: docker info
4. If Docker Desktop is not installed, download from: https://www.docker.com/products/docker-desktop
"""
    elif system == "Darwin":  # macOS
        return """
macOS Instructions:
1. Start Docker Desktop from Applications or Spotlight
2. Wait for Docker Desktop to fully start (check menu bar icon)
3. Verify Docker is running: docker info
4. If Docker Desktop is not installed, download from: https://www.docker.com/products/docker-desktop
"""
    else:  # Linux
        return """
Linux Instructions:
1. Start Docker service: sudo systemctl start docker
2. Enable Docker on boot: sudo systemctl enable docker
3. Add user to docker group: sudo usermod -aG docker $USER
4. Log out and back in for group changes to take effect
5. Verify Docker is running: docker info
"""


def validate_docker_environment() -> int:
    """
    Run all Docker validation checks.
    Returns 0 if all checks pass, non-zero exit code otherwise.
    """
    print("=" * 60)
    print("Docker Environment Validation")
    print("=" * 60)
    
    # Check if Docker is installed
    print("\n[1/2] Checking if Docker is installed...")
    is_installed, message = check_docker_installed()
    
    if not is_installed:
        print(f"❌ FAILED: {message}")
        print("\n" + get_platform_instructions())
        return 1
    
    print(f"✅ PASSED: {message}")
    
    # Check if Docker daemon is running
    print("\n[2/2] Checking if Docker daemon is running...")
    is_running, message = check_docker_running()
    
    if not is_running:
        print(f"❌ FAILED: {message}")
        print("\n" + get_platform_instructions())
        return 2
    
    print(f"✅ PASSED: {message}")
    
    # All checks passed
    print("\n" + "=" * 60)
    print("✅ All Docker checks passed! Ready for CDK deployment.")
    print("=" * 60)
    return 0


if __name__ == "__main__":
    exit_code = validate_docker_environment()
    sys.exit(exit_code)
