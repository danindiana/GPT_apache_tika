#!/bin/bash
# Integration test: Tika Installation and Setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

# Test 1: Java installation
log_info "Test 1: Checking Java installation..."
if java -version 2>&1 | grep -q "version"; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    log_success "Java is installed (version: $JAVA_VERSION)"
else
    log_error "Java is not installed"
fi

# Test 2: Tika JAR exists
log_info "Test 2: Checking Tika JAR file..."
if [ -f "$TIKA_JAR" ]; then
    log_success "Tika JAR found at: $TIKA_JAR"
else
    log_error "Tika JAR not found at: $TIKA_JAR"
fi

# Test 3: Tika version check
log_info "Test 3: Checking Tika version..."
if java -jar "$TIKA_JAR" --version 2>&1 | grep -q "Apache Tika"; then
    TIKA_VERSION=$(java -jar "$TIKA_JAR" --version 2>&1 | head -n 1)
    log_success "Tika version: $TIKA_VERSION"
else
    log_error "Cannot get Tika version"
fi

# Test 4: Tika list supported types
log_info "Test 4: Checking Tika supported types..."
if java -jar "$TIKA_JAR" --list-supported-types 2>&1 | grep -q "application/pdf"; then
    log_success "Tika supports PDF processing"
else
    log_error "Tika does not support PDF processing"
fi

# Test 5: GNU Parallel installation
log_info "Test 5: Checking GNU Parallel installation..."
if command -v parallel &> /dev/null; then
    PARALLEL_VERSION=$(parallel --version 2>&1 | head -n 1)
    log_success "GNU Parallel is installed: $PARALLEL_VERSION"
else
    log_error "GNU Parallel is not installed"
fi

# Test 6: curl installation
log_info "Test 6: Checking curl installation..."
if command -v curl &> /dev/null; then
    CURL_VERSION=$(curl --version 2>&1 | head -n 1)
    log_success "curl is installed: $CURL_VERSION"
else
    log_error "curl is not installed"
fi

# Summary
echo ""
echo "======================================"
echo "Test Summary:"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo "======================================"

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi

exit 0
