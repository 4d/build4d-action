# Code Signing Documentation

This document provides comprehensive information about code signing capabilities in the Build 4D GitHub Action.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Basic Signing](#basic-signing)
- [Advanced Certificate Management](#advanced-certificate-management)
- [Platform-Specific Signing](#platform-specific-signing)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)

## Overview

The Build 4D Action supports comprehensive code signing for both macOS and Windows platforms. It provides flexible certificate management, automatic keychain handling, and secure cleanup of sensitive materials.

### Supported Platforms

- **macOS**: Full support with keychain management
- **Windows**: Code signing with certificate store integration

### Supported Certificate Formats

- **P12/PFX**: PKCS#12 certificate files
- **Base64 Encoded**: Certificates stored as GitHub secrets
- **Certificate Store**: Windows certificate store integration

## Prerequisites

### macOS Requirements

- macOS runner (`macos-latest` or specific version)
- Valid Apple Developer certificate
- Certificate password (if applicable)

### Windows Requirements

- Windows runner (`windows-latest` or specific version)
- Valid code signing certificate
- Certificate thumbprint or store location

## Basic Signing

### Simple Certificate by Name

```yaml
- uses: 4d/build4d-action@v3
  with:
    actions: "build,sign"
    sign-certificate: "Developer ID Application: Your Company Name"
    sign-files: "MyApp.app,MyFramework.framework"
```

### Certificate with Custom Entitlements

```yaml
- uses: 4d/build4d-action@v3
  with:
    actions: "build,sign"
    sign-certificate: "Developer ID Application: Your Company Name"
    entitlements-file: "Resources/custom.entitlements"
    sign-deep: "true"
```

## Advanced Certificate Management

### Base64 Encoded Certificate (Recommended for CI/CD)

```yaml
- uses: 4d/build4d-action@v3
  with:
    actions: "build,sign"
    sign-certificate-base64: ${{ secrets.SIGNING_CERTIFICATE_BASE64 }}
    sign-certificate-password: ${{ secrets.CERTIFICATE_PASSWORD }}
    sign-deep: "true"
```

### Certificate from File Path

```yaml
- uses: 4d/build4d-action@v3
  with:
    actions: "build,sign"
    sign-certificate-path: "certificates/signing.p12"
    sign-certificate-password: ${{ secrets.CERTIFICATE_PASSWORD }}
```

### Custom Keychain Password

```yaml
- uses: 4d/build4d-action@v3
  with:
    actions: "build,sign"
    sign-certificate-base64: ${{ secrets.SIGNING_CERTIFICATE_BASE64 }}
    sign-certificate-password: ${{ secrets.CERTIFICATE_PASSWORD }}
    keychain-password: ${{ secrets.KEYCHAIN_PASSWORD }}
```

## Platform-Specific Signing

### macOS Advanced Options

```yaml
- uses: 4d/build4d-action@v3
  with:
    actions: "build,sign"
    sign-certificate-base64: ${{ secrets.SIGNING_CERTIFICATE_BASE64 }}
    sign-certificate-password: ${{ secrets.CERTIFICATE_PASSWORD }}
    sign-identity: "Developer ID Application: Your Company Name"
    sign-timestamp-url: "http://timestamp.apple.com/ts01"
    sign-deep: "true"
    sign-options: '{"hardened-runtime": true, "secure-timestamp": true}'
    entitlements-file: "Resources/app.entitlements"
```

### Windows Code Signing

```yaml
- uses: 4d/build4d-action@v3
  with:
    actions: "build,sign"
    sign-windows-certificate: ${{ secrets.WINDOWS_CERT_BASE64 }}
    sign-windows-thumbprint: ${{ secrets.CERT_THUMBPRINT }}
    sign-windows-store: "CurrentUser"
    sign-timestamp-url: "http://timestamp.digicert.com"
```

### Cross-Platform Signing

```yaml
- uses: 4d/build4d-action@v3
  with:
    actions: "build,sign"
    # macOS signing
    sign-certificate-base64: ${{ secrets.MACOS_CERT_BASE64 }}
    sign-certificate-password: ${{ secrets.MACOS_CERT_PASSWORD }}
    # Windows signing
    sign-windows-certificate: ${{ secrets.WINDOWS_CERT_BASE64 }}
    sign-windows-thumbprint: ${{ secrets.WINDOWS_CERT_THUMBPRINT }}
    # Common options
    sign-timestamp-url: "http://timestamp.digicert.com"
```

## Input Parameters Reference

### Core Signing Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `sign-certificate` | Certificate name for macOS | No | `""` |
| `sign-files` | List of files to sign (relative paths) | No | `""` |
| `entitlements-file` | Path to entitlements file | No | `""` |

### Advanced Certificate Management

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `sign-certificate-base64` | Base64 encoded certificate (P12/PFX) | No | `""` |
| `sign-certificate-password` | Certificate password | No | `""` |
| `sign-certificate-path` | Path to certificate file | No | `""` |
| `keychain-password` | Custom keychain password (macOS) | No | `""` |
| `sign-identity` | Signing identity (alternative to certificate name) | No | `""` |

### Signing Options

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `sign-timestamp-url` | Timestamp server URL | No | `""` |
| `sign-deep` | Enable deep signing (macOS) | No | `"false"` |
| `sign-options` | Additional signing options as JSON | No | `""` |

### Windows-Specific Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `sign-windows-certificate` | Windows code signing certificate | No | `""` |
| `sign-windows-thumbprint` | Certificate thumbprint | No | `""` |
| `sign-windows-store` | Certificate store location | No | `"CurrentUser"` |

## Security Best Practices

### 1. Store Certificates as Secrets

Always store certificates and passwords as GitHub repository secrets:

```yaml
# Never commit certificates or passwords to your repository
sign-certificate-base64: ${{ secrets.SIGNING_CERTIFICATE_BASE64 }}
sign-certificate-password: ${{ secrets.CERTIFICATE_PASSWORD }}
```

### 2. Use Base64 Encoding for Certificates

Convert your certificate to base64 format for storage:

```bash
# macOS/Linux
base64 -i your-certificate.p12 | pbcopy

# Windows
certutil -encode your-certificate.p12 certificate.base64
```

### 3. Limit Secret Access

Configure your repository secrets with appropriate access controls:

- Use environment-specific secrets for different deployment stages
- Limit secret access to specific branches or tags
- Review secret access logs regularly

### 4. Certificate Cleanup

The action automatically cleans up temporary certificates and keychains, but you can verify:

- Temporary keychains are deleted after signing
- Certificate files are removed from the runner
- No sensitive data persists between runs

## Troubleshooting

### Common Issues

#### Certificate Not Found

```yaml
# Make sure the certificate name matches exactly
sign-certificate: "Developer ID Application: Your Company Name (TEAMID)"

# Or use identity instead
sign-identity: "Your Company Name"
```

#### Keychain Access Denied

```yaml
# Ensure certificate password is correct
sign-certificate-password: ${{ secrets.CERTIFICATE_PASSWORD }}

# Or provide custom keychain password
keychain-password: ${{ secrets.KEYCHAIN_PASSWORD }}
```

#### Base64 Decoding Issues

```yaml
# Ensure base64 string doesn't contain line breaks
sign-certificate-base64: ${{ secrets.SIGNING_CERTIFICATE_BASE64 }}

# Verify base64 encoding is correct
# base64 -D <<< "$BASE64_STRING" | file -
```

### Debug Mode

Enable debug mode to see detailed signing information:

```yaml
env:
  RUNNER_DEBUG: 1
```

### Verification Commands

You can verify signing after the action completes:

```bash
# macOS - verify code signature
codesign -dv --verbose=4 /path/to/signed/app

# Windows - verify digital signature
signtool verify /pa /v /d signed-file.exe
```

## Examples

### Complete macOS Signing Workflow

```yaml
name: Build and Sign macOS App
on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Build and Sign 4D Application
      uses: 4d/build4d-action@v3
      with:
        project: "MyProject/MyProject.4DProject"
        actions: "build,sign,archive"
        targets: "arm64_macOS_lib"
        
        # Certificate management
        sign-certificate-base64: ${{ secrets.MACOS_CERT_BASE64 }}
        sign-certificate-password: ${{ secrets.MACOS_CERT_PASSWORD }}
        
        # Signing options
        sign-deep: "true"
        sign-timestamp-url: "http://timestamp.apple.com/ts01"
        entitlements-file: "Resources/app.entitlements"
        
        # Files to sign
        sign-files: "MyApp.app,MyFramework.framework"
        
        # Archive settings
        archive-name: "MyApp-macOS"
        output-directory: "dist"
```

### Complete Windows Signing Workflow

```yaml
name: Build and Sign Windows App
on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Build and Sign 4D Application
      uses: 4d/build4d-action@v3
      with:
        project: "MyProject/MyProject.4DProject"
        actions: "build,sign,archive"
        targets: "x86_64_generic"
        
        # Windows certificate management
        sign-windows-certificate: ${{ secrets.WINDOWS_CERT_BASE64 }}
        sign-windows-thumbprint: ${{ secrets.WINDOWS_CERT_THUMBPRINT }}
        sign-windows-store: "CurrentUser"
        
        # Signing options
        sign-timestamp-url: "http://timestamp.digicert.com"
        
        # Archive settings
        archive-name: "MyApp-Windows"
        output-directory: "dist"
```

### Multi-Platform Signing

```yaml
name: Build and Sign Multi-Platform
on:
  push:
    tags: ['v*']

jobs:
  build:
    strategy:
      matrix:
        include:
          - os: macos-latest
            targets: "arm64_macOS_lib"
            archive-name: "MyApp-macOS"
          - os: windows-latest
            targets: "x86_64_generic"
            archive-name: "MyApp-Windows"
    
    runs-on: ${{ matrix.os }}
    steps:
    - uses: actions/checkout@v4
    
    - name: Build and Sign 4D Application
      uses: 4d/build4d-action@v3
      with:
        project: "MyProject/MyProject.4DProject"
        actions: "build,sign,archive"
        targets: ${{ matrix.targets }}
        archive-name: ${{ matrix.archive-name }}
        
        # macOS signing
        sign-certificate-base64: ${{ secrets.MACOS_CERT_BASE64 }}
        sign-certificate-password: ${{ secrets.MACOS_CERT_PASSWORD }}
        sign-deep: "true"
        
        # Windows signing
        sign-windows-certificate: ${{ secrets.WINDOWS_CERT_BASE64 }}
        sign-windows-thumbprint: ${{ secrets.WINDOWS_CERT_THUMBPRINT }}
        
        # Common options
        sign-timestamp-url: "http://timestamp.digicert.com"
        output-directory: "dist"
```

## Additional Resources

### Certificate Management Tools

- [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list) - macOS certificates
- [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/) - Windows signing tools
- [DigiCert Certificate Utility](https://www.digicert.com/util/) - Certificate management

### Timestamp Servers

- **Apple**: `http://timestamp.apple.com/ts01`
- **DigiCert**: `http://timestamp.digicert.com`
- **Sectigo**: `http://timestamp.sectigo.com`
- **GlobalSign**: `http://timestamp.globalsign.com/scripts/timstamp.dll`

### Useful Commands

```bash
# List available certificates (macOS)
security find-identity -v -p codesigning

# List certificates in keychain (macOS)
security list-keychains

# Verify certificate (Windows)
certutil -store -user My

# Create base64 from certificate
openssl base64 -in certificate.p12 -out certificate.base64
```

For more information, see the [main README](README.md) or open an issue in the repository.
