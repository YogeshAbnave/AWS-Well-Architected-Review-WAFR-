#!/bin/bash

# Quick script to upgrade AWS CDK CLI to latest version

echo "=========================================="
echo "AWS CDK CLI Upgrade"
echo "=========================================="
echo ""

# Check current version
if command -v cdk &> /dev/null; then
    CURRENT_VERSION=$(cdk --version 2>&1)
    echo "Current CDK version: $CURRENT_VERSION"
else
    echo "CDK is not currently installed"
fi

echo ""
echo "Upgrading to latest version..."
npm install -g aws-cdk@latest

echo ""
echo "=========================================="
NEW_VERSION=$(cdk --version 2>&1)
echo "✅ CDK upgraded successfully!"
echo "New version: $NEW_VERSION"
echo "=========================================="
