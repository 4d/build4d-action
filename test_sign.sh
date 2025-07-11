#!/bin/bash

# test_sign.sh - Test script for macOS signing configurations
# This script tests various signing configurations for the build4d-action

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script is designed for macOS only${NC}"
    exit 1
fi

# Initialize tool4d
if [ -f "../tool4d-action/download.sh" ]; then
    source ../tool4d-action/download.sh
    echo "Using tool4d: $tool4d_bin"
else
    echo -e "${RED}❌ Please clone 4d/tool4d-action into parent folder${NC}"
    exit 1
fi

# Setup environment
export WORKINK_DIRECTORY=$(pwd)
export ERROR_FLAG=$WORKINK_DIRECTORY/error_flag
export RUNNER_DEBUG=1

# Test project to use for signing tests
testProject="$WORKINK_DIRECTORY/Resources/test/ok/Project/ok.4DProject"
project="Project/actions.4DProject"

# Temporary directory for test certificates and files
TEST_TEMP_DIR="/tmp/build4d_sign_test"
mkdir -p "$TEST_TEMP_DIR"

# Cleanup function
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
    rm -rf "$TEST_TEMP_DIR"
    [ -f "$ERROR_FLAG" ] && rm "$ERROR_FLAG"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Counter for tests
test_count=0
passed_count=0
failed_count=0

# Function to run a test
run_test() {
    local test_name="$1"
    local user_param="$2"
    local should_fail="${3:-false}"
    
    test_count=$((test_count + 1))
    echo -e "\n${YELLOW}📋 Test $test_count: $test_name${NC}"
    echo "User parameters: $user_param"
    
    # Clean error flag
    [ -f "$ERROR_FLAG" ] && rm "$ERROR_FLAG"
    
    # Run the test
    set +e
    ../tool4d-action/run.sh "$project" "main" "$ERROR_FLAG" "$tool4d_bin" "$user_param"
    status=$?
    set -e
    
    # Check result
    if [[ "$should_fail" == "true" ]]; then
        if [[ $status -ne 0 ]]; then
            echo -e "${GREEN}✅ Test passed (expected failure)${NC}"
            passed_count=$((passed_count + 1))
        else
            echo -e "${RED}❌ Test failed (should have failed but didn't)${NC}"
            failed_count=$((failed_count + 1))
        fi
    else
        if [[ $status -eq 0 ]]; then
            echo -e "${GREEN}✅ Test passed${NC}"
            passed_count=$((passed_count + 1))
        else
            echo -e "${RED}❌ Test failed (exit code: $status)${NC}"
            failed_count=$((failed_count + 1))
        fi
    fi
    
    # Clean up after test
    [ -f "$ERROR_FLAG" ] && rm "$ERROR_FLAG"
}

# Create a dummy certificate for testing (self-signed)
create_test_certificate() {
    local cert_path="$TEST_TEMP_DIR/test_cert.p12"
    local cert_password="test123"
    
    echo -e "${YELLOW}🔐 Creating test certificate...${NC}" >&2
    
    # Create a self-signed certificate
    openssl req -x509 -newkey rsa:2048 -keyout "$TEST_TEMP_DIR/test_key.pem" -out "$TEST_TEMP_DIR/test_cert.pem" -days 1 -nodes -subj "/CN=Test Certificate" 2>/dev/null
    
    # Convert to p12 format
    openssl pkcs12 -export -out "$cert_path" -inkey "$TEST_TEMP_DIR/test_key.pem" -in "$TEST_TEMP_DIR/test_cert.pem" -password pass:$cert_password 2>/dev/null
    
    # Encode to base64
    base64 -i "$cert_path" -o "$TEST_TEMP_DIR/test_cert_base64.txt"
    
    echo "$cert_path"
}

# Create test entitlements file
create_test_entitlements() {
    local entitlements_path="$TEST_TEMP_DIR/test.entitlements"
    
    cat > "$entitlements_path" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
</dict>
</plist>
EOF
    
    echo "$entitlements_path"
}

# Function to create base user parameters
create_base_params() {
    local additional_params="$1"
    
    cat << EOF
{
    "path": "$testProject",
    "workingDirectory": "$WORKINK_DIRECTORY",
    "actions": ["build", "sign"],
    "outputDirectory": "$TEST_TEMP_DIR/output",
    "debug": 1,
    "errorFlag": "$ERROR_FLAG"
    $additional_params
}
EOF
}

echo -e "${GREEN}🧪 Starting macOS Signing Tests${NC}"
echo "Test project: $testProject"

# Create test resources
test_cert_path=$(create_test_certificate)
test_entitlements_path=$(create_test_entitlements)
test_cert_base64=$(cat "$TEST_TEMP_DIR/test_cert_base64.txt")

# Test: Basic signing with certificate name (should fail - no real certificate)
run_test "Basic signing with certificate name" "$(create_base_params ',
    "signCertificate": "Developer ID Application: Test Certificate"
')" "true"

# Test: Signing with certificate path
run_test "Signing with certificate path" "$(create_base_params ',
    "signCertificatePath": "'$test_cert_path'",
    "signCertificatePassword": "test123"
')" "true"

# Test: Signing with base64 certificate
run_test "Signing with base64 certificate" "$(create_base_params ',
    "signCertificateBase64": "'$test_cert_base64'",
    "signCertificatePassword": "test123"
')" "true"

# Test: Signing with identity
run_test "Signing with identity" "$(create_base_params ',
    "signIdentity": "Developer ID Application: Test Identity"
')" "true"

# Test: Signing with custom entitlements
run_test "Signing with custom entitlements" "$(create_base_params ',
    "signCertificate": "Developer ID Application: Test Certificate",
    "entitlementsFile": "'$test_entitlements_path'"
')" "true"

# Test: Signing with additional files
run_test "Signing with additional files" "$(create_base_params ',
    "signCertificate": "Developer ID Application: Test Certificate",
    "signFiles": ["Resources/test.txt", "Libraries/lib4d-arm64.dylib"]
')" "true"

# Test: Signing with all options combined
run_test "Signing with all options combined" "$(create_base_params ',
    "signCertificate": "Developer ID Application: Test Certificate",
    "entitlementsFile": "'$test_entitlements_path'",
    "signFiles": ["Resources/test.txt"]
')" "true"

# Test: Test without sign action (should succeed)
run_test "Build without signing" "$(create_base_params ',
    "actions": ["build"]
')" "false"

# Test: Test with invalid certificate path
run_test "Invalid certificate path" "$(create_base_params ',
    "signCertificatePath": "/non/existent/path.p12",
    "signCertificatePassword": "test123"
')" "true"

# Test: Test with invalid entitlements file
run_test "Invalid entitlements file" "$(create_base_params ',
    "signCertificate": "Developer ID Application: Test Certificate",
    "entitlementsFile": "/non/existent/entitlements.plist"
')" "true"

# Test: Test with malformed base64 certificate
run_test "Malformed base64 certificate" "$(create_base_params ',
    "signCertificateBase64": "invalid_base64_data",
    "signCertificatePassword": "test123"
')" "true"

# Test: Test with empty sign certificate
run_test "Empty sign certificate" "$(create_base_params ',
    "signCertificate": ""
')" "false"

# Summary
echo -e "\n${GREEN}📊 Test Summary${NC}"
echo "Total tests: $test_count"
echo -e "Passed: ${GREEN}$passed_count${NC}"
echo -e "Failed: ${RED}$failed_count${NC}"

if [[ $failed_count -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}💥 Some tests failed${NC}"
    exit 1
fi
