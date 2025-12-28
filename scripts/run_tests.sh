#!/bin/bash
#
# Test runner script for the GitHub Actions workflow tests
#
# This script runs all bats tests and provides coverage information.
#
# Prerequisites:
#   - bats-core: https://github.com/bats-core/bats-core
#   - jq: For JSON parsing in scripts
#
# Installation:
#   macOS: brew install bats-core jq
#   Ubuntu: apt-get install bats jq
#   Or: npm install -g bats
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TESTS_DIR="$PROJECT_ROOT/tests"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  GitHub Actions Workflow Unit Tests"
echo "=========================================="
echo ""

# Check for bats
if ! command -v bats &> /dev/null; then
    echo -e "${RED}Error: bats-core is not installed${NC}"
    echo ""
    echo "Install bats-core using one of the following methods:"
    echo "  macOS:  brew install bats-core"
    echo "  Ubuntu: apt-get install bats"
    echo "  npm:    npm install -g bats"
    echo ""
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq is not installed. Some tests may fail.${NC}"
    echo "Install jq using: brew install jq (macOS) or apt-get install jq (Ubuntu)"
    echo ""
fi

# Run tests
echo "Running tests..."
echo ""

# Count test files
test_files=("$TESTS_DIR"/*.bats)
num_files=${#test_files[@]}

if [ "$num_files" -eq 0 ] || [ ! -f "${test_files[0]}" ]; then
    echo -e "${YELLOW}No test files found in $TESTS_DIR${NC}"
    exit 0
fi

echo "Found $num_files test file(s)"
echo ""

# Run bats with tap output for parsing, or pretty output for humans
if [ "$1" = "--tap" ]; then
    bats --tap "$TESTS_DIR"/*.bats
else
    bats "$TESTS_DIR"/*.bats
fi

exit_code=$?

echo ""
if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
else
    echo -e "${RED}Some tests failed${NC}"
fi

exit $exit_code
