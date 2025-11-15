#!/bin/bash
# Integration test: Parallel Processing Workflow

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
}

trap cleanup EXIT

# Setup test environment
TEST_DIR="tests/fixtures/parallel"
OUTPUT_DIR="tests/results/parallel"
mkdir -p "$TEST_DIR" "$OUTPUT_DIR"

# Create multiple test files
log_info "Creating test files..."
for i in {1..10}; do
    echo "Test document $i - This is a test file for parallel processing with Apache Tika.
Line 2: More content for testing
Line 3: Additional test data
Line 4: Document number $i" > "$TEST_DIR/test_file_$i.txt"
done

# Start Tika server for parallel processing
log_info "Starting Tika server for parallel processing..."
java -jar "$TIKA_JAR" --server --port 9989 > "$OUTPUT_DIR/server.log" 2>&1 &
TIKA_PID=$!
sleep 5

if ! ps -p $TIKA_PID > /dev/null; then
    log_error "Failed to start Tika server"
    exit 1
fi

# Test 1: GNU Parallel with Tika server
log_info "Test 1: Processing files with GNU Parallel (2 jobs)..."
START_TIME=$(date +%s)

find "$TEST_DIR" -name "*.txt" | \
    parallel -j 2 "curl -s -T {} http://localhost:9989/tika > $OUTPUT_DIR/{/.}_output.txt"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Check if all files were processed
PROCESSED_COUNT=$(find "$OUTPUT_DIR" -name "*_output.txt" | wc -l)
if [ $PROCESSED_COUNT -eq 10 ]; then
    log_success "All 10 files processed in parallel (${DURATION}s)"
else
    log_error "Only $PROCESSED_COUNT/10 files were processed"
fi

# Test 2: Verify parallel processing performance
log_info "Test 2: Comparing parallel vs sequential performance..."

# Sequential processing
rm -f "$OUTPUT_DIR"/*_sequential.txt
SEQUENTIAL_START=$(date +%s)

for file in "$TEST_DIR"/*.txt; do
    filename=$(basename "$file" .txt)
    curl -s -T "$file" http://localhost:9989/tika > "$OUTPUT_DIR/${filename}_sequential.txt"
done

SEQUENTIAL_END=$(date +%s)
SEQUENTIAL_DURATION=$((SEQUENTIAL_END - SEQUENTIAL_START))

if [ $SEQUENTIAL_DURATION -gt $DURATION ]; then
    SPEEDUP=$(echo "scale=2; $SEQUENTIAL_DURATION / $DURATION" | bc)
    log_success "Parallel processing is faster (${SPEEDUP}x speedup)"
else
    log_error "Parallel processing is not faster than sequential"
fi

# Test 3: Verify output integrity
log_info "Test 3: Verifying output file integrity..."
VALID_OUTPUTS=0

for i in {1..10}; do
    OUTPUT_FILE="$OUTPUT_DIR/test_file_${i}_output.txt"
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        # Check if output contains expected content
        if grep -q "Test document $i" "$OUTPUT_FILE" 2>/dev/null; then
            ((VALID_OUTPUTS++))
        fi
    fi
done

if [ $VALID_OUTPUTS -eq 10 ]; then
    log_success "All output files contain expected content"
else
    log_error "Only $VALID_OUTPUTS/10 output files are valid"
fi

# Test 4: Test with different parallel job counts
log_info "Test 4: Testing different parallel job counts..."

for jobs in 1 2 4; do
    TEMP_OUTPUT="$OUTPUT_DIR/jobs_$jobs"
    mkdir -p "$TEMP_OUTPUT"

    JOB_START=$(date +%s)
    find "$TEST_DIR" -name "*.txt" | \
        parallel -j $jobs "curl -s -T {} http://localhost:9989/tika > $TEMP_OUTPUT/{/.}.txt" 2>/dev/null
    JOB_END=$(date +%s)
    JOB_DURATION=$((JOB_END - JOB_START))

    PROCESSED=$(find "$TEMP_OUTPUT" -name "*.txt" | wc -l)
    if [ $PROCESSED -eq 10 ]; then
        log_success "Successfully processed with $jobs parallel jobs (${JOB_DURATION}s)"
    else
        log_error "Failed with $jobs parallel jobs (only $PROCESSED/10 processed)"
    fi
done

# Test 5: Test progress monitoring
log_info "Test 5: Testing progress monitoring..."
PROGRESS_OUTPUT="$OUTPUT_DIR/progress_test"
mkdir -p "$PROGRESS_OUTPUT"

# Use parallel with progress bar
find "$TEST_DIR" -name "*.txt" | \
    parallel --bar -j 2 "curl -s -T {} http://localhost:9989/tika > $PROGRESS_OUTPUT/{/.}.txt" 2>&1 | \
    grep -q "100%" && log_success "Progress monitoring working" || log_error "Progress monitoring failed"

# Test 6: Test error handling in parallel processing
log_info "Test 6: Testing error handling with non-existent files..."
ERROR_OUTPUT="$OUTPUT_DIR/error_test"
mkdir -p "$ERROR_OUTPUT"

# Create a list with some non-existent files
echo -e "$TEST_DIR/test_file_1.txt\n/nonexistent/file.txt\n$TEST_DIR/test_file_2.txt" | \
    parallel -j 2 "curl -s -T {} http://localhost:9989/tika > $ERROR_OUTPUT/{/.}.txt" 2>/dev/null || true

# Check that valid files were still processed
VALID_PROCESSED=$(find "$ERROR_OUTPUT" -name "*.txt" -size +0 | wc -l)
if [ $VALID_PROCESSED -ge 1 ]; then
    log_success "Error handling allows continuation after failures"
else
    log_error "Error handling failed"
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
