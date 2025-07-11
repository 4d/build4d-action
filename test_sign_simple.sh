#!/bin/bash

# test_sign_simple.sh - Simple test script for macOS signing configurations
# This script tests key signing configurations for the build4d-action

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

# Temporary directory for test output
TEST_OUTPUT_DIR="/tmp/build4d_sign_test_output"
mkdir -p "$TEST_OUTPUT_DIR"

# Cleanup function
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    rm -rf "$TEST_OUTPUT_DIR"
    [ -f "$ERROR_FLAG" ] && rm "$ERROR_FLAG"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Function to run a test
run_test() {
    local test_name="$1"
    local sign_params="$2"
    local expected_result="${3:-should_fail}"  # should_fail, should_pass, or ignore
    
    echo -e "\n${YELLOW}📋 Testing: $test_name${NC}"
    
    # Clean error flag
    [ -f "$ERROR_FLAG" ] && rm "$ERROR_FLAG"
    
    # Build user parameters
    local user_param=$(cat << EOF
{
    "path": "$testProject",
    "workingDirectory": "$WORKINK_DIRECTORY",
    "actions": ["clean", "build", "sign"],
    "outputDirectory": "$TEST_OUTPUT_DIR",
    "debug": 1,
    "errorFlag": "$ERROR_FLAG"
    $sign_params
}
EOF
    )
    
    echo "Sign parameters: $sign_params"
    
    # Run the test
    set +e
    ../tool4d-action/run.sh "$project" "main" "$ERROR_FLAG" "$tool4d_bin" "$user_param"
    status=$?
    set -e
    
    # Check result
    case $expected_result in
        "should_fail")
            if [[ $status -ne 0 ]]; then
                echo -e "${GREEN}✅ Test passed (expected failure)${NC}"
            else
                echo -e "${RED}❌ Test failed (should have failed but didn't)${NC}"
            fi
            ;;
        "should_pass")
            if [[ $status -eq 0 ]]; then
                echo -e "${GREEN}✅ Test passed${NC}"
            else
                echo -e "${RED}❌ Test failed (exit code: $status)${NC}"
            fi
            ;;
        "ignore")
            echo -e "${YELLOW}ℹ️  Test completed (result ignored)${NC}"
            ;;
    esac
    
    # Show last few lines of output for debugging
    echo -e "${YELLOW}Last few lines of output:${NC}"
    tail -n 5 "/tmp/test_output.log" || true
    
    # Clean up after test
    [ -f "$ERROR_FLAG" ] && rm "$ERROR_FLAG"
    rm -rf "$TEST_OUTPUT_DIR"/*
}

echo -e "${GREEN}🧪 Starting macOS Signing Tests${NC}"
echo "Test project: $testProject"

# Test: No signing configuration (should build without signing)
run_test "Build without signing" ',
    "actions": ["build"]
' "should_pass"

# Test: Basic signing with certificate name (will fail without real certificate)
run_test "Basic signing with certificate name" ',
    "signCertificate": "Developer ID Application: Test Certificate"
' "should_fail"

# Test: Signing with identity
run_test "Signing with identity" ',
    "signIdentity": "Developer ID Application: Test Identity"
' "should_fail"

# Test: Signing with custom entitlements (using default entitlements)
run_test "Signing with custom entitlements" ',
    "signCertificate": "Developer ID Application: Test Certificate",
    "entitlementsFile": "'$WORKINK_DIRECTORY/Resources/default.entitlements'"
' "should_fail"

# Test: Signing with additional files
run_test "Signing with additional files" ',
    "signCertificate": "Developer ID Application: Test Certificate",
    "signFiles": ["Libraries/lib4d-arm64.dylib"]
' "should_fail"

# Test: Empty certificate
run_test "Empty certificate" ',
    "signCertificate": ""
' "should_fail"

# Test: Invalid entitlements file path
run_test "Invalid entitlements file" ',
    "signCertificate": "Developer ID Application: Test Certificate",
    "entitlementsFile": "/non/existent/entitlements.plist"
' "should_fail"

echo -e "\n${GREEN}🎉 All tests completed!${NC}"
echo -e "${YELLOW}Note: Most signing tests are expected to fail since they use fake certificates.${NC}"
echo -e "${YELLOW}The tests verify that the signing logic handles various configurations correctly.${NC}"
