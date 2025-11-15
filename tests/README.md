# Apache Tika Integration Tests

Comprehensive integration test suite for the Apache Tika PDF processing workflows.

## Overview

This test suite validates the complete Apache Tika processing pipeline, including:
- Installation and setup verification
- Single file conversion workflows
- Tika server functionality
- Parallel processing with GNU Parallel
- Error handling and edge cases

## Directory Structure

```
tests/
├── README.md                          # This file
├── run_integration_tests.sh           # Main test runner
├── integration/                       # Integration test suites
│   ├── test_tika_setup.sh            # Setup and installation tests
│   ├── test_single_file_conversion.sh # Single file processing tests
│   ├── test_tika_server.sh           # Server workflow tests
│   ├── test_parallel_processing.sh   # Parallel processing tests
│   └── test_error_handling.sh        # Error handling tests
├── fixtures/                          # Test input files
│   ├── parallel/                     # Files for parallel processing tests
│   └── errors/                       # Files for error handling tests
└── results/                           # Test output and logs
    ├── test_report.txt               # Consolidated test report
    └── *.log                         # Individual test suite logs
```

## Prerequisites

Before running the tests, ensure you have:

1. **Java Runtime Environment (JRE) 8 or higher**
   ```bash
   java -version
   ```

2. **Apache Tika JAR file**
   - Download from: https://archive.apache.org/dist/tika/2.9.1/tika-app-2.9.1.jar
   - Set `TIKA_JAR` environment variable or place in common location

3. **GNU Parallel**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install parallel

   # macOS
   brew install parallel
   ```

4. **curl**
   ```bash
   # Usually pre-installed on most systems
   curl --version
   ```

## Running the Tests

### Run All Tests

```bash
# Set TIKA_JAR environment variable
export TIKA_JAR=/path/to/tika-app-2.9.1.jar

# Run all integration tests
./tests/run_integration_tests.sh
```

### Run Individual Test Suites

```bash
# Run specific test suite
export TIKA_JAR=/path/to/tika-app-2.9.1.jar

# Setup tests
./tests/integration/test_tika_setup.sh

# Single file conversion tests
./tests/integration/test_single_file_conversion.sh

# Server workflow tests
./tests/integration/test_tika_server.sh

# Parallel processing tests
./tests/integration/test_parallel_processing.sh

# Error handling tests
./tests/integration/test_error_handling.sh
```

## Test Suites

### 1. Tika Setup and Installation Tests
**File:** `integration/test_tika_setup.sh`

Validates the testing environment and dependencies:
- Java installation and version
- Tika JAR availability and version
- Supported file types (PDF)
- GNU Parallel installation
- curl installation

**Expected Output:** All prerequisite checks pass

### 2. Single File Conversion Tests
**File:** `integration/test_single_file_conversion.sh`

Tests basic Tika functionality:
- Text extraction from documents
- Metadata extraction
- JSON output format
- MIME type detection
- Language detection
- Output content verification

**Expected Output:** All conversion operations succeed

### 3. Tika Server Workflow Tests
**File:** `integration/test_tika_server.sh`

Validates Tika server mode:
- Server startup and health checks
- PUT request handling
- Metadata endpoint
- MIME detection endpoint
- Version endpoint
- Concurrent request handling

**Expected Output:** Server starts and handles all requests correctly

### 4. Parallel Processing Tests
**File:** `integration/test_parallel_processing.sh`

Tests parallel processing capabilities:
- GNU Parallel with Tika server
- Performance comparison (parallel vs sequential)
- Output integrity verification
- Different parallel job counts (1, 2, 4)
- Progress monitoring
- Error recovery during parallel execution

**Expected Output:** Parallel processing works and shows performance improvements

### 5. Error Handling and Edge Cases Tests
**File:** `integration/test_error_handling.sh`

Validates error handling:
- Empty files
- Non-existent files
- Unsupported file types
- Large files
- Files with special characters in names
- Server timeout handling
- Server restart and recovery
- Permission errors
- Concurrent request limits
- Invalid server URLs

**Expected Output:** All errors are handled gracefully without crashes

## Test Results

Test results are stored in the `results/` directory:

- **Individual logs:** `results/<test_name>.log` - Detailed output from each test suite
- **Status files:** `results/<test_name>.status` - PASSED/FAILED status
- **Test report:** `results/test_report.txt` - Consolidated summary report

### Interpreting Results

Each test prints colored output:
- 🟢 **Green [PASS]** - Test passed successfully
- 🔴 **Red [FAIL]** - Test failed
- 🟡 **Yellow [INFO]** - Informational message

The final summary shows:
```
Test Summary:
  Passed: X
  Failed: Y
```

## CI/CD Integration

These tests are automatically run by GitHub Actions on:
- Push to `main` or `claude/**` branches
- Pull requests to `main`
- Manual workflow dispatch

See `.github/workflows/ci-tests.yml` for the CI configuration.

### Platforms Tested

- **Ubuntu (latest)** - Primary platform
- **macOS (latest)** - Secondary platform
- **Script validation** - ShellCheck linting
- **Documentation** - Markdown validation

## Troubleshooting

### TIKA_JAR not found

```bash
# Set the environment variable
export TIKA_JAR=/path/to/tika-app-2.9.1.jar

# Or download Tika
wget https://archive.apache.org/dist/tika/2.9.1/tika-app-2.9.1.jar
export TIKA_JAR=$(pwd)/tika-app-2.9.1.jar
```

### Server tests fail

If Tika server tests fail, check:
1. Port 9989 is not in use: `lsof -i :9989`
2. Kill any existing Tika servers: `pkill -f "tika.*--server"`
3. Check server logs in `results/server.log`

### Parallel tests fail

If parallel processing tests fail:
1. Verify GNU Parallel is installed: `parallel --version`
2. Check system resources: `htop` or `top`
3. Reduce parallel job count if system is resource-constrained

### Permission errors

If you encounter permission errors:
```bash
# Make test scripts executable
chmod +x tests/run_integration_tests.sh
chmod +x tests/integration/*.sh

# Fix test directory permissions
chmod -R 755 tests/
```

## Contributing

When adding new tests:

1. Create test script in `integration/` directory
2. Follow naming convention: `test_<feature>.sh`
3. Use the standard test format:
   - Set up test environment
   - Run tests with pass/fail tracking
   - Clean up resources
   - Print summary
4. Add test suite to `run_integration_tests.sh`
5. Update this README with test description

### Test Script Template

```bash
#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; ((TESTS_PASSED++)); }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; ((TESTS_FAILED++)); }

# Your tests here

# Summary
echo "Test Summary:"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"

[ $TESTS_FAILED -eq 0 ] && exit 0 || exit 1
```

## License

These tests are part of the GPT Apache Tika project and follow the same license.

## Additional Resources

- [Apache Tika Documentation](https://tika.apache.org/)
- [GNU Parallel Tutorial](https://www.gnu.org/software/parallel/parallel_tutorial.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
