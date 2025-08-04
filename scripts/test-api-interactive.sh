#!/bin/bash
# Interactive API testing script using Gum
# Requires: gum, jq, curl, docker

set -euo pipefail

# Colors and styling
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# API Configuration
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
API_VERSION="v1"

# Test addresses from config - using parallel arrays for compatibility
TEST_NAMES=(
    "ETH2 Deposit Contract"
    "Vitalik Buterin"
    "Regular User"
    "Empty Wallet"
    "Dust Amount"
    "Whale Address"
    "Small Holder"
    "Medium Holder"
)

TEST_ADDRESSES=(
    "0x00000000219ab540356cBB839Cbe05303d7705Fa"
    "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
    "0x742d35Cc6634C0532925a3b844Bc9e7595ED6fF5"
    "0x0000000000000000000000000000000000000000"
    "0x1234567890123456789012345678901234567890"
    "0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF"
    "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    "0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
)

# Ensure dependencies are installed
check_dependencies() {
    local deps=("gum" "jq" "curl" "docker")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing dependencies: ${missing[*]}${NC}"
        echo "Please install missing dependencies:"
        echo "  brew install gum jq curl"
        echo "  Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
}

# Check if API is running
check_api_health() {
    local health_url="$API_BASE_URL/api/$API_VERSION/health"
    
    gum spin --spinner dot --title "Checking API health..." -- \
        curl -s -f "$health_url" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ API is healthy${NC}"
        return 0
    else
        echo -e "${RED}✗ API is not responding${NC}"
        return 1
    fi
}

# Start Docker containers if not running
ensure_containers_running() {
    if ! docker ps | grep -q "trm1-api-1"; then
        gum confirm "Docker containers are not running. Start them?" && {
            gum spin --spinner dot --title "Starting Docker containers..." -- \
                docker-compose -f docker-compose.test.yml up -d
            
            echo "Waiting for API to be ready..."
            sleep 5
        }
    fi
}

# Make API request and format response
make_api_request() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    
    local curl_opts=(-s -X "$method" -H "Content-Type: application/json")
    
    if [ -n "$data" ]; then
        curl_opts+=(-d "$data")
    fi
    
    local response
    response=$(curl "${curl_opts[@]}" "$API_BASE_URL$endpoint" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "$response" | jq . 2>/dev/null || echo "$response"
    else
        echo -e "${RED}Request failed: $response${NC}"
    fi
}

# Test address balance
test_address_balance() {
    local name="$1"
    local address="$2"
    
    echo -e "\n${BLUE}Testing: $name${NC}"
    echo "Address: $address"
    echo "---"
    
    local endpoint="/api/$API_VERSION/address/$address/balance"
    
    gum spin --spinner dot --title "Fetching balance..." -- sleep 0.5
    
    local response
    response=$(make_api_request "$endpoint")
    
    echo "$response" | gum format -t code --language json
}

# Test custom address
test_custom_address() {
    local address
    address=$(gum input --placeholder "Enter Ethereum address (0x...)")
    
    if [ -z "$address" ]; then
        echo -e "${YELLOW}No address entered${NC}"
        return
    fi
    
    test_address_balance "Custom Address" "$address"
}

# Run test suite
run_test_suite() {
    echo -e "${BLUE}Running full test suite...${NC}\n"
    
    # Test all predefined addresses
    for i in "${!TEST_NAMES[@]}"; do
        test_address_balance "${TEST_NAMES[$i]}" "${TEST_ADDRESSES[$i]}"
        echo ""
    done
    
    # Test invalid addresses
    echo -e "\n${BLUE}Testing invalid addresses...${NC}"
    local invalid_addresses=(
        "0xinvalid"
        "not-an-address"
        "0x123"
        ""
    )
    
    for addr in "${invalid_addresses[@]}"; do
        echo -e "\nTesting invalid: '$addr'"
        local response
        response=$(make_api_request "/api/$API_VERSION/address/$addr/balance" 2>&1 || true)
        echo "$response" | gum format -t code --language json
    done
}

# View recent results
view_recent_results() {
    local results_dir="./test-results"
    
    if [ ! -d "$results_dir" ]; then
        echo -e "${YELLOW}No test results found${NC}"
        return
    fi
    
    local result_file
    result_file=$(find "$results_dir" -name "*.json" -type f | \
        gum choose --header "Select a result file to view")
    
    if [ -n "$result_file" ]; then
        gum pager < "$result_file"
    fi
}

# Save test result
save_test_result() {
    local result="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local results_dir="./test-results"
    
    mkdir -p "$results_dir"
    
    local filename="$results_dir/test_result_$timestamp.json"
    echo "$result" > "$filename"
    echo -e "${GREEN}Result saved to: $filename${NC}"
}

# Configure environment
configure_environment() {
    echo -e "${BLUE}Current Configuration:${NC}"
    echo "API URL: $API_BASE_URL"
    echo ""
    
    local choice
    choice=$(gum choose "Change API URL" "Back to main menu")
    
    case "$choice" in
        "Change API URL")
            local new_url
            new_url=$(gum input --placeholder "Enter API URL" --value "$API_BASE_URL")
            if [ -n "$new_url" ]; then
                export API_BASE_URL="$new_url"
                echo -e "${GREEN}API URL updated to: $new_url${NC}"
            fi
            ;;
    esac
}

# Performance test
performance_test() {
    local num_requests
    num_requests=$(gum input --placeholder "Number of requests" --value "100")
    
    if [ -z "$num_requests" ] || ! [[ "$num_requests" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid number of requests${NC}"
        return
    fi
    
    echo -e "${BLUE}Running performance test with $num_requests requests...${NC}"
    
    # Use Vitalik's address for performance test (index 1)
    local address="${TEST_ADDRESSES[1]}"
    local endpoint="/api/$API_VERSION/address/$address/balance"
    
    local start_time=$(date +%s.%N)
    
    for i in $(seq 1 "$num_requests"); do
        gum spin --spinner dot --title "Request $i/$num_requests" -- \
            curl -s -f "$API_BASE_URL$endpoint" > /dev/null
    done
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    local avg_time=$(echo "scale=3; $duration / $num_requests" | bc)
    
    echo -e "\n${GREEN}Performance Test Results:${NC}"
    echo "Total requests: $num_requests"
    echo "Total time: ${duration}s"
    echo "Average time per request: ${avg_time}s"
    echo "Requests per second: $(echo "scale=2; $num_requests / $duration" | bc)"
}

# Main menu
main_menu() {
    while true; do
        echo -e "\n${BLUE}🧪 TRM Block Explorer API Tester${NC}"
        echo "================================"
        
        local choice
        choice=$(gum choose \
            "Check API Health" \
            "Test Address Balance (Predefined)" \
            "Test Custom Address" \
            "Run Test Suite" \
            "Performance Test" \
            "View Recent Results" \
            "Configure Environment" \
            "Exit")
        
        case "$choice" in
            "Check API Health")
                check_api_health
                ;;
            "Test Address Balance (Predefined)")
                local name
                name=$(printf '%s\n' "${TEST_NAMES[@]}" | gum choose --header "Select an address")
                if [ -n "$name" ]; then
                    # Find index of selected name
                    for i in "${!TEST_NAMES[@]}"; do
                        if [ "${TEST_NAMES[$i]}" = "$name" ]; then
                            test_address_balance "$name" "${TEST_ADDRESSES[$i]}"
                            break
                        fi
                    done
                fi
                ;;
            "Test Custom Address")
                test_custom_address
                ;;
            "Run Test Suite")
                run_test_suite
                ;;
            "Performance Test")
                performance_test
                ;;
            "View Recent Results")
                view_recent_results
                ;;
            "Configure Environment")
                configure_environment
                ;;
            "Exit")
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
        esac
    done
}

# Main execution
main() {
    check_dependencies
    ensure_containers_running
    
    if ! check_api_health; then
        gum confirm "API is not healthy. Continue anyway?" || exit 1
    fi
    
    main_menu
}

# Run main function
main "$@"