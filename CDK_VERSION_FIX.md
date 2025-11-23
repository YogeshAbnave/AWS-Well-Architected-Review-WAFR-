# CDK Version Mismatch Fix

## Problem

When running `cdk deploy`, you may encounter this error:

```
This CDK CLI is not compatible with the CDK library used by your application.
Please upgrade the CLI to the latest version.
(Cloud assembly schema version mismatch: Maximum schema version supported is 36.0.0, but found 48.0.0)
```

## Root Cause

The CDK library in your `requirements.txt` (`aws-cdk-lib>=2.191.0`) uses a newer schema version (48.0.0) than your installed CDK CLI supports (36.0.0). This happens when:

- You have an older CDK CLI installed globally
- The CDK library was recently updated
- There's a mismatch between CLI and library versions

## Solution

### Quick Fix (Automatic)

The deployment scripts now automatically detect and offer to upgrade CDK:

```bash
# Linux/macOS
./deploy.sh pre-req

# Windows PowerShell
.\deploy.ps1 pre-req
```

When prompted, choose "y" to upgrade CDK automatically.

### Manual Fix

If you prefer to upgrade manually:

```bash
# Upgrade CDK CLI to latest version
npm install -g aws-cdk@latest

# Verify the version (should be 2.1000.0 or later)
cdk --version
```

### Using Upgrade Scripts

We've provided dedicated upgrade scripts:

```bash
# Linux/macOS
./upgrade_cdk.sh

# Windows PowerShell
.\upgrade_cdk.ps1
```

## Verification

After upgrading, verify the CDK version:

```bash
cdk --version
```

You should see version **2.1033.0** or later.

## Why This Happens

AWS CDK has two components:

1. **CDK CLI** - The command-line tool (`cdk` command)
   - Installed globally via npm: `npm install -g aws-cdk`
   - Version format: 2.1033.0

2. **CDK Library** - The Python/TypeScript library
   - Installed per-project via pip: `pip install aws-cdk-lib`
   - Version format: 2.191.0

Starting with CDK 2.179.0, the CLI and library versions diverged:
- CLI versions: 2.1000.0, 2.1001.0, 2.1002.0, etc.
- Library versions: 2.179.0, 2.180.0, 2.191.0, etc.

The CLI must be equal to or newer than the library to support the schema version.

## Version Compatibility

| CDK Library Version | Minimum CLI Version | Schema Version |
|---------------------|---------------------|----------------|
| 2.191.0+            | 2.1000.0+           | 48.0.0         |
| 2.179.0 - 2.190.0   | 2.1000.0+           | 36.0.0+        |
| < 2.179.0           | 2.x.x               | < 36.0.0       |

## Prevention

To avoid this issue in the future:

1. **Keep CDK CLI updated:**
   ```bash
   npm update -g aws-cdk
   ```

2. **Check versions before deployment:**
   ```bash
   cdk --version
   python -c "import aws_cdk; print(aws_cdk.__version__)"
   ```

3. **Use the deployment scripts** - They now check version compatibility automatically

## Troubleshooting

### Issue: npm permission errors

**Linux/macOS:**
```bash
sudo npm install -g aws-cdk@latest
```

**Windows:**
Run PowerShell as Administrator

### Issue: Multiple Node.js versions

If you have multiple Node.js versions (via nvm), ensure you're using the correct one:

```bash
# Check Node version
node --version

# Switch to LTS version (if using nvm)
nvm use --lts
```

### Issue: CDK still shows old version

Clear npm cache and reinstall:

```bash
npm cache clean --force
npm uninstall -g aws-cdk
npm install -g aws-cdk@latest
```

## Related Issues

- [AWS CDK Issue #32775](https://github.com/aws/aws-cdk/issues/32775) - CLI and library version divergence

## Next Steps

After upgrading CDK CLI:

1. Verify version: `cdk --version`
2. Run deployment: `cdk deploy` or `./deploy.sh deploy`
3. Your deployment should now proceed without version mismatch errors

## Files Modified

The following files now include automatic CDK version checking:

- `deploy.sh` - Bash deployment script
- `deploy.ps1` - PowerShell deployment script
- `upgrade_cdk.sh` - Quick upgrade script (Bash)
- `upgrade_cdk.ps1` - Quick upgrade script (PowerShell)
