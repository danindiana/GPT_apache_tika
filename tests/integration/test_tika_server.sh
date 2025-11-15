#!/bin/bash
# Integration test: Tika Server Workflow

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

# Cleanup function
cleanup() {
    log_info "Cleaning up Tika server..."
    if [ ! -z "$TIKA_PID" ]; then
        kill $TIKA_PID 2>/dev/null || true
        wait $TIKA_PID 2>/dev/null || true
    fi
}

trap cleanup EXIT

# Setup test environment
TEST_DIR="tests/fixtures"
OUTPUT_DIR="tests/results/server"
mkdir -p "$OUTPUT_DIR"

# Create test file if it doesn't exist
TEST_FILE="$TEST_DIR/test_sample.txt"
if [ ! -f "$TEST_FILE" ]; then
    echo "This is a test document for Tika server testing." > "$TEST_FILE"
fi

# Test 1: Start Tika server
log_info "Test 1: Starting Tika server on port 9989..."
java -jar "$TIKA_JAR" --server --port 9989 > "$OUTPUT_DIR/server.log" 2>&1 &
TIKA_PID=$!

# Wait for server to start
sleep 5

if ps -p $TIKA_PID > /dev/null; then
    log_success "Tika server started successfully (PID: $TIKA_PID)"
else
    log_error "Tika server failed to start"
    cat "$OUTPUT_DIR/server.log"
    exit 1
fi

# Test 2: Server health check
log_info "Test 2: Checking server health..."
if curl -s http://localhost:9989/tika > /dev/null; then
    log_success "Server is responding to requests"
else
    log_error "Server is not responding"
fi

# Test 3: Test PUT request to server
log_info "Test 3: Sending test file to server via PUT..."
OUTPUT_FILE="$OUTPUT_DIR/server_output.txt"
if curl -s -T "$TEST_FILE" http://localhost:9989/tika > "$OUTPUT_FILE"; then
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        log_success "Server processed file successfully"
    else
        log_error "Server output is empty"
    fi
else
    log_error "Failed to send file to server"
fi

# Test 4: Test metadata endpoint
log_info "Test 4: Testing metadata endpoint..."
METADATA_FILE="$OUTPUT_DIR/server_metadata.txt"
if curl -s -T "$TEST_FILE" http://localhost:9989/meta > "$METADATA_FILE"; then
    if [ -f "$METADATA_FILE" ] && [ -s "$METADATA_FILE" ]; then
        log_success "Metadata endpoint working"
    else
        log_error "Metadata endpoint returned empty response"
    fi
else
    log_error "Metadata endpoint failed"
fi

# Test 5: Test MIME type detection endpoint
log_info "Test 5: Testing MIME detection endpoint..."
MIME_FILE="$OUTPUT_DIR/server_mime.txt"
if curl -s -T "$TEST_FILE" http://localhost:9989/detect/stream > "$MIME_FILE"; then
    if [ -f "$MIME_FILE" ] && [ -s "$MIME_FILE" ]; then
        log_success "MIME detection endpoint working"
    else
        log_error "MIME detection returned empty response"
    fi
else
    log_error "MIME detection endpoint failed"
fi

# Test 6: Test version endpoint
log_info "Test 6: Testing version endpoint..."
if curl -s http://localhost:9989/version 2>&1 | grep -q "Apache Tika"; then
    log_success "Version endpoint working"
else
    log_error "Version endpoint failed"
fi

# Test 7: Multiple concurrent requests
log_info "Test 7: Testing concurrent requests..."
for i in {1..5}; do
    curl -s -T "$TEST_FILE" http://localhost:9989/tika > "$OUTPUT_DIR/concurrent_$i.txt" &
done
wait

CONCURRENT_SUCCESS=0
for i in {1..5}; do
    if [ -f "$OUTPUT_DIR/concurrent_$i.txt" ] && [ -s "$OUTPUT_DIR/concurrent_$i.txt" ]; then
        ((CONCURRENT_SUCCESS++))
    fi
done

if [ $CONCURRENT_SUCCESS -eq 5 ]; then
    log_success "All concurrent requests succeeded"
else
    log_error "Only $CONCURRENT_SUCCESS/5 concurrent requests succeeded"
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
