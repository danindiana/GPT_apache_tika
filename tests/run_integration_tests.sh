#!/bin/bash
# Main test runner for Apache Tika integration tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Apache Tika Integration Test Suite  ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if TIKA_JAR is set
if [ -z "$TIKA_JAR" ]; then
    echo -e "${YELLOW}TIKA_JAR not set, attempting to find Tika...${NC}"

    # Try to find Tika in common locations
    COMMON_LOCATIONS=(
        "$HOME/tika/tika-app-2.9.1.jar"
        "/opt/tika/tika-app-2.9.1.jar"
        "./tika-app-2.9.1.jar"
        "$(find /usr -name "tika-app*.jar" 2>/dev/null | head -n 1)"
    )

    for location in "${COMMON_LOCATIONS[@]}"; do
        if [ -f "$location" ]; then
            export TIKA_JAR="$location"
            echo -e "${GREEN}Found Tika at: $TIKA_JAR${NC}"
            break
        fi
    done

    if [ -z "$TIKA_JAR" ]; then
        echo -e "${RED}ERROR: Could not find Tika JAR file${NC}"
        echo "Please set TIKA_JAR environment variable or install Tika"
        exit 1
    fi
fi

echo "Using Tika JAR: $TIKA_JAR"
echo ""

# Create results directory
RESULTS_DIR="tests/results"
mkdir -p "$RESULTS_DIR"

# Initialize test tracking
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
START_TIME=$(date +%s)

# Function to run a test suite
run_test_suite() {
    local test_script=$1
    local test_name=$2

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Running: $test_name${NC}"
    echo -e "${BLUE}========================================${NC}"

    ((TOTAL_SUITES++))

    # Make script executable
    chmod +x "$test_script"

    # Run the test and capture output
    if bash "$test_script" 2>&1 | tee "$RESULTS_DIR/${test_name}.log"; then
        echo -e "${GREEN}✓ PASSED: $test_name${NC}"
        ((PASSED_SUITES++))
        echo "PASSED" > "$RESULTS_DIR/${test_name}.status"
    else
        echo -e "${RED}✗ FAILED: $test_name${NC}"
        ((FAILED_SUITES++))
        echo "FAILED" > "$RESULTS_DIR/${test_name}.status"
    fi

    echo ""
}

# Run all test suites
echo -e "${YELLOW}Starting integration test execution...${NC}"
echo ""

# Test Suite 1: Tika Setup and Installation
run_test_suite "tests/integration/test_tika_setup.sh" "Tika Setup and Installation"

# Test Suite 2: Single File Conversion
run_test_suite "tests/integration/test_single_file_conversion.sh" "Single File Conversion"

# Test Suite 3: Tika Server
run_test_suite "tests/integration/test_tika_server.sh" "Tika Server Workflow"

# Test Suite 4: Parallel Processing
run_test_suite "tests/integration/test_parallel_processing.sh" "Parallel Processing"

# Test Suite 5: Error Handling
run_test_suite "tests/integration/test_error_handling.sh" "Error Handling and Edge Cases"

# Calculate total execution time
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

# Print final summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Execution Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Total Test Suites: $TOTAL_SUITES"
echo -e "${GREEN}Passed: $PASSED_SUITES${NC}"
if [ $FAILED_SUITES -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED_SUITES${NC}"
else
    echo "Failed: $FAILED_SUITES"
fi
echo "Total Time: ${TOTAL_TIME}s"
echo ""

# Generate test report
REPORT_FILE="$RESULTS_DIR/test_report.txt"
{
    echo "Apache Tika Integration Test Report"
    echo "===================================="
    echo ""
    echo "Execution Date: $(date)"
    echo "Tika JAR: $TIKA_JAR"
    echo ""
    echo "Summary:"
    echo "  Total Test Suites: $TOTAL_SUITES"
    echo "  Passed: $PASSED_SUITES"
    echo "  Failed: $FAILED_SUITES"
    echo "  Total Time: ${TOTAL_TIME}s"
    echo ""
    echo "Test Suite Results:"
    for status_file in "$RESULTS_DIR"/*.status; do
        if [ -f "$status_file" ]; then
            suite_name=$(basename "$status_file" .status)
            status=$(cat "$status_file")
            echo "  [$status] $suite_name"
        fi
    done
} > "$REPORT_FILE"

echo "Test report saved to: $REPORT_FILE"
echo ""

# Cleanup
echo "Cleaning up test processes..."
pkill -f "tika.*--server" 2>/dev/null || true

# Exit with appropriate code
if [ $FAILED_SUITES -gt 0 ]; then
    echo -e "${RED}Some tests failed. Please check the logs in $RESULTS_DIR${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed successfully!${NC}"
    exit 0
fi
