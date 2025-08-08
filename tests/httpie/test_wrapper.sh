#!/bin/bash

# Test wrapper script that provides formatted output and summaries
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Arrays to store test results
declare -a TEST_NAMES
declare -a TEST_RESULTS
declare -a TEST_DETAILS

# Function to print test configuration summary
print_test_configuration() {
    local mode="$1"
    
    echo -e "\n${CYAN}=== Test Configuration ===${NC}"
    echo -e "${BLUE}Mode:${NC} $mode"
    
    case "$mode" in
        "mock")
            echo -e "${BLUE}API Endpoint:${NC} http://localhost:8000"
            echo -e "${BLUE}Blockchain:${NC} In-memory mock"
            echo -e "${BLUE}Database:${NC} In-memory mock"
            echo -e "${BLUE}Cache:${NC} In-memory mock"
            echo -e "${BLUE}Infrastructure:${NC} No external dependencies"
            ;;
        "file-based")
            echo -e "${BLUE}API Endpoint:${NC} http://localhost:8000"
            echo -e "${BLUE}Blockchain:${NC} File-based mock with test data"
            echo -e "${BLUE}Database:${NC} File-based storage"
            echo -e "${BLUE}Cache:${NC} File-based storage"
            echo -e "${BLUE}Infrastructure:${NC} Local filesystem only"
            ;;
        "services")
            echo -e "${BLUE}API Endpoint:${NC} http://localhost:8000"
            echo -e "${BLUE}Blockchain:${NC} In-memory mock"
            echo -e "${BLUE}Database:${NC} DynamoDB (Docker container)"
            echo -e "${BLUE}Cache:${NC} Redis (Docker container)"
            echo -e "${BLUE}Infrastructure:${NC} Docker services"
            ;;
        "wan")
            echo -e "${BLUE}API Endpoint:${NC} http://localhost:8000"
            echo -e "${BLUE}Blockchain:${NC} Infura API (${INFURA_NETWORK:-mainnet})"
            echo -e "${BLUE}Database:${NC} DynamoDB (Docker container)"
            echo -e "${BLUE}Cache:${NC} Redis (Docker container)"
            echo -e "${BLUE}Infrastructure:${NC} Docker services + Infura"
            if [[ -n "$INFURA_API_KEY" ]]; then
                echo -e "${BLUE}Infura API Key:${NC} ${INFURA_API_KEY:0:8}...${INFURA_API_KEY: -4}"
            fi
            ;;
        "dev")
            echo -e "${BLUE}API Endpoint:${NC} https://api.trm.geoffmiller.cloud"
            echo -e "${BLUE}Environment:${NC} AWS Development"
            echo -e "${BLUE}Infrastructure:${NC} Remote AWS services"
            ;;
    esac
    echo -e "${CYAN}===========================${NC}\n"
}

# Function to run a single test and capture results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "\n${YELLOW}Test #$TOTAL_TESTS: $test_name${NC}"
    echo -e "${BLUE}Command:${NC} $test_command"
    echo -e "${BLUE}Expected:${NC} $expected_result"
    
    # Run the test and capture output
    set +e
    output=$(eval "$test_command" 2>&1)
    exit_code=$?
    set -e
    
    # Extract actual result from output
    actual_result="[See output]"
    if [[ $output =~ \"balance\":\"([0-9.]+)\" ]]; then
        actual_result="${BASH_REMATCH[1]} ETH"
    elif [[ $output =~ \"hash\":\"(0x[a-fA-F0-9]+)\" ]]; then
        actual_result="${BASH_REMATCH[1]:0:16}..."
    elif [[ $output =~ \"number\":([0-9]+) ]]; then
        actual_result="Block #${BASH_REMATCH[1]}"
    elif [[ $output =~ "404" ]] || [[ $output =~ "Not Found" ]]; then
        actual_result="404 Not Found"
    elif [[ $output =~ "422" ]] || [[ $output =~ "Validation Error" ]]; then
        actual_result="422 Validation Error"
    elif [[ $output =~ "Expected 404" ]]; then
        actual_result="404 Not Found"
    elif [[ $output =~ "Expected 422" ]]; then
        actual_result="422 Validation Error"
    fi
    
    echo -e "${BLUE}Actual:${NC} $actual_result"
    
    # Store test info
    TEST_NAMES+=("$test_name")
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}Result: ✓ PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("PASS")
        TEST_DETAILS+=("Expected: $expected_result, Actual: $actual_result")
    else
        echo -e "${RED}Result: ✗ FAIL${NC}"
        echo -e "${RED}Error:${NC} $output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("FAIL")
        TEST_DETAILS+=("Expected: $expected_result, Error: ${output:0:100}...")
    fi
}

# Function to print final summary
print_summary() {
    echo -e "\n${CYAN}=== Test Summary ===${NC}"
    echo -e "${BLUE}Total Tests:${NC} $TOTAL_TESTS"
    echo -e "${GREEN}Passed:${NC} $PASSED_TESTS"
    echo -e "${RED}Failed:${NC} $FAILED_TESTS"
    
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$(echo "scale=1; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)
        echo -e "${BLUE}Success Rate:${NC} ${success_rate}%"
    fi
    
    echo -e "\n${CYAN}=== Detailed Results ===${NC}"
    for i in "${!TEST_NAMES[@]}"; do
        if [[ "${TEST_RESULTS[$i]}" == "PASS" ]]; then
            echo -e "${GREEN}✓${NC} ${TEST_NAMES[$i]}"
        else
            echo -e "${RED}✗${NC} ${TEST_NAMES[$i]}"
        fi
        echo -e "  ${TEST_DETAILS[$i]}"
    done
    
    echo -e "${CYAN}=====================${NC}\n"
    
    # Exit with appropriate code
    if [[ $FAILED_TESTS -gt 0 ]]; then
        exit 1
    fi
}

# Export functions for use in test scripts
export -f print_test_configuration
export -f run_test
export -f print_summary