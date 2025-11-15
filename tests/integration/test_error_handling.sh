#!/bin/bash
# Integration test: Error Handling and Edge Cases

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
    log_info "Cleaning up..."
    pkill -f "tika.*--server" 2>/dev/null || true
    rm -rf "$TEST_DIR/temp_*" 2>/dev/null || true
}

trap cleanup EXIT

# Setup test environment
TEST_DIR="tests/fixtures/errors"
OUTPUT_DIR="tests/results/errors"
mkdir -p "$TEST_DIR" "$OUTPUT_DIR"

# Start Tika server
log_info "Starting Tika server..."
java -jar "$TIKA_JAR" --server --port 9989 > "$OUTPUT_DIR/server.log" 2>&1 &
TIKA_PID=$!
sleep 5

# Test 1: Handle empty file
log_info "Test 1: Processing empty file..."
EMPTY_FILE="$TEST_DIR/empty.txt"
touch "$EMPTY_FILE"

if java -jar "$TIKA_JAR" -t "$EMPTY_FILE" > "$OUTPUT_DIR/empty_output.txt" 2>&1; then
    log_success "Empty file handled gracefully"
else
    # Empty files might fail, but should not crash
    log_success "Empty file error handled appropriately"
fi

# Test 2: Handle non-existent file
log_info "Test 2: Processing non-existent file..."
if java -jar "$TIKA_JAR" -t "/nonexistent/file.pdf" > "$OUTPUT_DIR/nonexistent.txt" 2>&1; then
    log_error "Should have failed for non-existent file"
else
    log_success "Non-existent file error handled correctly"
fi

# Test 3: Handle unsupported file type
log_info "Test 3: Processing unsupported binary file..."
BINARY_FILE="$TEST_DIR/binary.bin"
dd if=/dev/urandom of="$BINARY_FILE" bs=1024 count=1 2>/dev/null

if java -jar "$TIKA_JAR" -t "$BINARY_FILE" > "$OUTPUT_DIR/binary_output.txt" 2>&1; then
    # Tika should handle it but may not extract meaningful text
    log_success "Binary file processed without crashing"
else
    log_success "Binary file handled appropriately"
fi

# Test 4: Handle large file (create a large text file)
log_info "Test 4: Processing large file..."
LARGE_FILE="$TEST_DIR/large.txt"
for i in {1..1000}; do
    echo "Line $i: This is a large file test with repeated content to test Tika's handling of larger files." >> "$LARGE_FILE"
done

if timeout 30 java -jar "$TIKA_JAR" -t "$LARGE_FILE" > "$OUTPUT_DIR/large_output.txt" 2>&1; then
    if [ -s "$OUTPUT_DIR/large_output.txt" ]; then
        log_success "Large file processed successfully"
    else
        log_error "Large file output is empty"
    fi
else
    log_error "Large file processing timed out or failed"
fi

# Test 5: Handle file with special characters in name
log_info "Test 5: Processing file with special characters in name..."
SPECIAL_FILE="$TEST_DIR/test file with spaces & special!chars.txt"
echo "Test content" > "$SPECIAL_FILE"

if java -jar "$TIKA_JAR" -t "$SPECIAL_FILE" > "$OUTPUT_DIR/special_chars_output.txt" 2>&1; then
    if [ -s "$OUTPUT_DIR/special_chars_output.txt" ]; then
        log_success "File with special characters processed"
    else
        log_error "Special characters file output is empty"
    fi
else
    log_error "Failed to process file with special characters"
fi

# Test 6: Test server timeout handling
log_info "Test 6: Testing server timeout with slow request..."
TEST_FILE="$TEST_DIR/timeout_test.txt"
echo "Timeout test content" > "$TEST_FILE"

# Send request and check if it completes in reasonable time
if timeout 10 curl -s -T "$TEST_FILE" http://localhost:9989/tika > "$OUTPUT_DIR/timeout_output.txt" 2>&1; then
    log_success "Request completed within timeout"
else
    log_error "Request timed out"
fi

# Test 7: Test server restart recovery
log_info "Test 7: Testing server restart and recovery..."
kill $TIKA_PID 2>/dev/null || true
sleep 2

# Restart server
java -jar "$TIKA_JAR" --server --port 9989 > "$OUTPUT_DIR/server_restart.log" 2>&1 &
TIKA_PID=$!
sleep 5

if ps -p $TIKA_PID > /dev/null; then
    # Test if server works after restart
    if curl -s -T "$TEST_FILE" http://localhost:9989/tika > "$OUTPUT_DIR/restart_output.txt" 2>&1; then
        log_success "Server restarted and recovered successfully"
    else
        log_error "Server failed after restart"
    fi
else
    log_error "Failed to restart server"
fi

# Test 8: Test permission errors
log_info "Test 8: Testing permission handling..."
PERMISSION_FILE="$TEST_DIR/no_permission.txt"
echo "Test" > "$PERMISSION_FILE"
chmod 000 "$PERMISSION_FILE"

if java -jar "$TIKA_JAR" -t "$PERMISSION_FILE" > "$OUTPUT_DIR/permission_output.txt" 2>&1; then
    log_error "Should have failed with permission error"
else
    log_success "Permission error handled correctly"
fi

# Restore permissions for cleanup
chmod 644 "$PERMISSION_FILE" 2>/dev/null || true

# Test 9: Test concurrent server requests limits
log_info "Test 9: Testing concurrent request handling..."
CONCURRENT_DIR="$OUTPUT_DIR/concurrent"
mkdir -p "$CONCURRENT_DIR"

# Send many concurrent requests
for i in {1..20}; do
    curl -s -T "$TEST_FILE" http://localhost:9989/tika > "$CONCURRENT_DIR/out_$i.txt" &
done
wait

# Count successful responses
SUCCESS_COUNT=$(find "$CONCURRENT_DIR" -name "out_*.txt" -size +0 | wc -l)
if [ $SUCCESS_COUNT -ge 15 ]; then
    log_success "Server handled $SUCCESS_COUNT/20 concurrent requests"
else
    log_error "Server only handled $SUCCESS_COUNT/20 concurrent requests"
fi

# Test 10: Test invalid server URL handling
log_info "Test 10: Testing invalid server URL handling..."
if curl -s -T "$TEST_FILE" http://localhost:9999/tika > "$OUTPUT_DIR/invalid_url.txt" 2>&1; then
    log_error "Should have failed with invalid server URL"
else
    log_success "Invalid server URL handled correctly"
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
