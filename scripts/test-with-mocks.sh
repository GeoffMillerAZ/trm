#!/bin/bash
# Automated test script for CI/CD with mock data
set -euo pipefail

# Configuration
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.test.yml}"
API_URL="${API_URL:-http://localhost:8000}"
TEST_TIMEOUT="${TEST_TIMEOUT:-30}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    docker-compose -f "$COMPOSE_FILE" down -v
    exit "${1:-0}"
}

# Set up trap for cleanup
trap 'cleanup $?' EXIT INT TERM

# Start services
start_services() {
    log_info "Starting test services..."
    docker-compose -f "$COMPOSE_FILE" up -d --build
    
    log_info "Waiting for services to be ready..."
    local count=0
    while [ $count -lt $TEST_TIMEOUT ]; do
        if curl -s -f "$API_URL/api/v1/health" > /dev/null 2>&1; then
            log_info "API is ready!"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    log_error "API failed to start within ${TEST_TIMEOUT} seconds"
    docker-compose -f "$COMPOSE_FILE" logs api
    return 1
}

# Run health checks
test_health() {
    log_info "Testing health endpoints..."
    
    # Basic health check
    if ! curl -s -f "$API_URL/api/v1/health" | jq . > /dev/null; then
        log_error "Basic health check failed"
        return 1
    fi
    
    # Detailed health check
    if ! curl -s -f "$API_URL/api/v1/health/detailed" | jq . > /dev/null; then
        log_warning "Detailed health check endpoint not available"
    fi
    
    log_info "Health checks passed ✓"
    return 0
}

# Test valid addresses
test_valid_addresses() {
    log_info "Testing valid addresses..."
    
    local addresses=(
        "0x00000000219ab540356cBB839Cbe05303d7705Fa:36668162.325"
        "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045:5234.567890123456789012"
        "0x742d35Cc6634C0532925a3b844Bc9e7595ED6fF5:1.5"
        "0x0000000000000000000000000000000000000000:0"
    )
    
    local failed=0
    for addr_balance in "${addresses[@]}"; do
        IFS=':' read -r address expected_balance <<< "$addr_balance"
        
        response=$(curl -s "$API_URL/api/v1/address/$address/balance")
        actual_balance=$(echo "$response" | jq -r '.balance_eth' 2>/dev/null || echo "null")
        
        if [ "$actual_balance" = "null" ]; then
            log_error "Failed to get balance for $address"
            echo "Response: $response"
            ((failed++))
        else
            # Compare balances (allowing small differences due to decimal precision)
            if python3 -c "import sys; exit(0 if abs(float('$actual_balance') - float('$expected_balance')) < 0.001 else 1)" 2>/dev/null; then
                log_info "✓ $address: $actual_balance ETH"
            else
                log_error "✗ $address: Expected $expected_balance ETH, got $actual_balance ETH"
                ((failed++))
            fi
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log_info "All valid address tests passed ✓"
        return 0
    else
        log_error "$failed valid address tests failed"
        return 1
    fi
}

# Test invalid addresses
test_invalid_addresses() {
    log_info "Testing invalid addresses..."
    
    local invalid_addresses=(
        "0xinvalid"
        "not-an-address"
        "0x123"
        "0x00000000219ab540356cBB839Cbe05303d7705FaTOOLONG"
        ""
    )
    
    local failed=0
    for address in "${invalid_addresses[@]}"; do
        response=$(curl -s -w "\n%{http_code}" "$API_URL/api/v1/address/$address/balance")
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | head -n-1)
        
        if [ "$http_code" = "400" ]; then
            log_info "✓ Invalid address '$address' correctly rejected"
        else
            log_error "✗ Invalid address '$address' returned HTTP $http_code (expected 400)"
            echo "Response: $body"
            ((failed++))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log_info "All invalid address tests passed ✓"
        return 0
    else
        log_error "$failed invalid address tests failed"
        return 1
    fi
}

# Test caching behavior
test_caching() {
    log_info "Testing caching behavior..."
    
    local test_address="0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
    
    # First request (cache miss)
    local start_time=$(date +%s%N)
    curl -s "$API_URL/api/v1/address/$test_address/balance" > /dev/null
    local first_time=$(($(date +%s%N) - start_time))
    
    # Second request (cache hit)
    start_time=$(date +%s%N)
    local response=$(curl -s "$API_URL/api/v1/address/$test_address/balance")
    local second_time=$(($(date +%s%N) - start_time))
    
    # Check if response indicates cache hit
    local source=$(echo "$response" | jq -r '.source' 2>/dev/null || echo "unknown")
    
    # Second request should be faster (rough check)
    if [ "$second_time" -lt "$first_time" ]; then
        log_info "✓ Cache appears to be working (second request faster)"
    else
        log_warning "Cache performance unclear (times: first=${first_time}ns, second=${second_time}ns)"
    fi
    
    if [ "$source" = "cache" ]; then
        log_info "✓ Response correctly indicates cache source"
    fi
    
    return 0
}

# Performance test
test_performance() {
    log_info "Running basic performance test..."
    
    local num_requests=50
    local test_address="0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
    local start_time=$(date +%s%N)
    
    for i in $(seq 1 $num_requests); do
        curl -s "$API_URL/api/v1/address/$test_address/balance" > /dev/null &
    done
    
    wait
    
    local end_time=$(date +%s%N)
    local total_time_ms=$(( (end_time - start_time) / 1000000 ))
    local avg_time_ms=$((total_time_ms / num_requests))
    
    log_info "Performance results:"
    log_info "  Total requests: $num_requests"
    log_info "  Total time: ${total_time_ms}ms"
    log_info "  Average time per request: ${avg_time_ms}ms"
    
    # Basic performance threshold (adjust as needed)
    if [ $avg_time_ms -lt 100 ]; then
        log_info "✓ Performance is acceptable"
        return 0
    else
        log_warning "Performance might be slow (avg ${avg_time_ms}ms per request)"
        return 0  # Don't fail on performance in mock mode
    fi
}

# Main test execution
main() {
    log_info "Starting API tests with mock data..."
    
    # Start services
    if ! start_services; then
        log_error "Failed to start services"
        exit 1
    fi
    
    # Run all tests
    local test_results=0
    
    test_health || ((test_results++))
    test_valid_addresses || ((test_results++))
    test_invalid_addresses || ((test_results++))
    test_caching || ((test_results++))
    test_performance || ((test_results++))
    
    # Summary
    if [ $test_results -eq 0 ]; then
        log_info "All tests passed! 🎉"
        exit 0
    else
        log_error "$test_results test suites failed"
        exit 1
    fi
}

# Run main function
main "$@"