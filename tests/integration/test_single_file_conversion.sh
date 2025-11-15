#!/bin/bash
# Integration test: Single File Conversion Workflow

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

# Setup test environment
TEST_DIR="tests/fixtures"
OUTPUT_DIR="tests/results/single_file"
mkdir -p "$OUTPUT_DIR"

# Create test PDF using available tools
log_info "Creating test PDF file..."
TEST_PDF="$TEST_DIR/test_sample.pdf"

# Create a simple PDF using groff/ps2pdf if available, otherwise use a text file
if command -v ps2pdf &> /dev/null; then
    echo "This is a test PDF document for Apache Tika integration testing.
It contains multiple lines of text to ensure proper text extraction.

Test Content:
- Line 1: Basic ASCII text
- Line 2: Numbers 1234567890
- Line 3: Special characters !@#$%^&*()

End of test document." | groff -Tps > "$TEST_DIR/temp.ps" 2>/dev/null || true
    if [ -f "$TEST_DIR/temp.ps" ]; then
        ps2pdf "$TEST_DIR/temp.ps" "$TEST_PDF" 2>/dev/null || true
        rm -f "$TEST_DIR/temp.ps"
    fi
fi

# If PDF creation failed, create a simple text file for basic testing
if [ ! -f "$TEST_PDF" ]; then
    log_info "PDF creation tools not available, using text file for basic testing"
    TEST_FILE="$TEST_DIR/test_sample.txt"
    echo "This is a test text document for Apache Tika integration testing." > "$TEST_FILE"
else
    TEST_FILE="$TEST_PDF"
fi

# Test 1: Simple text extraction
log_info "Test 1: Extract text from test file..."
OUTPUT_FILE="$OUTPUT_DIR/test_output.txt"
if java -jar "$TIKA_JAR" -t "$TEST_FILE" > "$OUTPUT_FILE" 2>&1; then
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        log_success "Text extraction successful ($(wc -l < "$OUTPUT_FILE") lines)"
    else
        log_error "Output file is empty"
    fi
else
    log_error "Text extraction failed"
fi

# Test 2: Metadata extraction
log_info "Test 2: Extract metadata from test file..."
METADATA_FILE="$OUTPUT_DIR/test_metadata.txt"
if java -jar "$TIKA_JAR" -m "$TEST_FILE" > "$METADATA_FILE" 2>&1; then
    if [ -f "$METADATA_FILE" ] && [ -s "$METADATA_FILE" ]; then
        log_success "Metadata extraction successful"
    else
        log_error "Metadata file is empty"
    fi
else
    log_error "Metadata extraction failed"
fi

# Test 3: JSON output format
log_info "Test 3: Extract content in JSON format..."
JSON_FILE="$OUTPUT_DIR/test_output.json"
if java -jar "$TIKA_JAR" -j "$TEST_FILE" > "$JSON_FILE" 2>&1; then
    if [ -f "$JSON_FILE" ] && [ -s "$JSON_FILE" ]; then
        # Simple JSON validation
        if grep -q "{" "$JSON_FILE" && grep -q "}" "$JSON_FILE"; then
            log_success "JSON extraction successful"
        else
            log_error "JSON output is malformed"
        fi
    else
        log_error "JSON output file is empty"
    fi
else
    log_error "JSON extraction failed"
fi

# Test 4: MIME type detection
log_info "Test 4: Detect MIME type..."
MIME_FILE="$OUTPUT_DIR/test_mime.txt"
if java -jar "$TIKA_JAR" -d "$TEST_FILE" > "$MIME_FILE" 2>&1; then
    if [ -f "$MIME_FILE" ] && [ -s "$MIME_FILE" ]; then
        MIME_TYPE=$(cat "$MIME_FILE")
        log_success "MIME type detected: $MIME_TYPE"
    else
        log_error "MIME detection file is empty"
    fi
else
    log_error "MIME type detection failed"
fi

# Test 5: Language detection
log_info "Test 5: Detect language..."
LANG_FILE="$OUTPUT_DIR/test_language.txt"
if java -jar "$TIKA_JAR" -l "$TEST_FILE" > "$LANG_FILE" 2>&1; then
    if [ -f "$LANG_FILE" ] && [ -s "$LANG_FILE" ]; then
        LANGUAGE=$(cat "$LANG_FILE")
        log_success "Language detected: $LANGUAGE"
    else
        log_error "Language detection file is empty"
    fi
else
    log_error "Language detection failed"
fi

# Test 6: Verify output content
log_info "Test 6: Verify extracted text content..."
if [ -f "$OUTPUT_FILE" ]; then
    # Check if the output contains expected test content
    if grep -q "test" "$OUTPUT_FILE" 2>/dev/null; then
        log_success "Output contains expected test content"
    else
        log_error "Output does not contain expected content"
    fi
else
    log_error "Output file does not exist"
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
