#!/bin/bash
# Quick smoke test for API
set -euo pipefail

API_URL="${API_URL:-http://localhost:8000}"

echo "Running smoke tests against $API_URL..."

# Health check
echo -n "Health check: "
if curl -s -f "$API_URL/api/v1/health" > /dev/null; then
    echo "✓"
else
    echo "✗"
    exit 1
fi

# Valid address test
echo -n "Valid address test: "
response=$(curl -s "$API_URL/api/v1/address/0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045/balance")
if echo "$response" | jq -e '.balance_eth' > /dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
    echo "Response: $response"
    exit 1
fi

# Invalid address test
echo -n "Invalid address test: "
http_code=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/v1/address/invalid/balance")
if [ "$http_code" = "400" ]; then
    echo "✓"
else
    echo "✗ (expected 400, got $http_code)"
    exit 1
fi

echo "All smoke tests passed! 🎉"