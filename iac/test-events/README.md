# Lambda Test Events

This directory contains pre-made test events that can be pasted directly into the AWS Lambda console for testing Lambda functions in the development environment.

## Quick Start

1. Navigate to the AWS Lambda console
2. Select your Lambda function
3. Click on the "Test" tab
4. Click "Create new test event"
5. Copy and paste the JSON from any test event file in this repository
6. Give your test event a name and save it
7. Click "Test" to execute the Lambda function with the event

## Directory Structure

```
test-events/
├── api-gateway/         # API Gateway proxy events
├── dynamodb-streams/    # DynamoDB stream events
└── direct-invoke/       # Direct Lambda invocation events
```

## API Gateway Test Events

### Balance Endpoint Tests

#### Valid Address Request
**File**: `api-gateway/get-balance-valid.json`
- **Purpose**: Test successful balance retrieval for a valid Ethereum address
- **Expected Result**: HTTP 200 with balance in response body
- **Address Used**: `0x742d35Cc6634C0532925a3b844Bc9e7595f89590` (BitGo address)

#### Invalid Address Format
**File**: `api-gateway/get-balance-invalid-format.json`
- **Purpose**: Test error handling for invalid address format
- **Expected Result**: HTTP 400 with error message
- **Address Used**: `invalid_address_format`

#### Edge Cases
**File**: `api-gateway/get-balance-edge-cases.json`
- **Purpose**: Test handling of zero address
- **Expected Result**: HTTP 200 with balance (likely 0)
- **Address Used**: `0x0000000000000000000000000000000000000000`

#### Legacy API Format
**File**: `api-gateway/legacy-get-balance.json`
- **Purpose**: Test legacy API endpoint compatibility
- **Expected Result**: HTTP 200 with `{"balance": <value>}` format
- **Address Used**: `0xd8da6bf26964af9d7eed9e03e53415d37aa96045` (Vitalik's address)

### Health Check Tests

#### Modern Health Endpoint
**File**: `api-gateway/health-check.json`
- **Purpose**: Test `/health` endpoint
- **Expected Result**: HTTP 200 with health status JSON

#### Legacy Liveness Check
**File**: `api-gateway/legacy-healthz-live.json`
- **Purpose**: Test `/healthz/live` endpoint
- **Expected Result**: HTTP 200 with plain text "OK"

#### Legacy Readiness Check
**File**: `api-gateway/legacy-healthz-ready.json`
- **Purpose**: Test `/healthz/ready` endpoint
- **Expected Result**: HTTP 200 with plain text "OK"

### Error Scenarios

#### Missing Address
**File**: `api-gateway/error-missing-address.json`
- **Purpose**: Test when no address is provided
- **Expected Result**: HTTP 400 or appropriate error response

#### Short Address
**File**: `api-gateway/error-short-address.json`
- **Purpose**: Test with address too short to be valid
- **Expected Result**: HTTP 400 with "invalid address syntax" error
- **Address Used**: `0x123`

#### Missing 0x Prefix
**File**: `api-gateway/error-no-prefix.json`
- **Purpose**: Test address without 0x prefix
- **Expected Result**: HTTP 400 with "invalid address syntax" error
- **Address Used**: `742d35Cc6634C0532925a3b844Bc9e7595f89590`

#### Legacy Root Path
**File**: `api-gateway/legacy-root-path.json`
- **Purpose**: Test legacy root path `/`
- **Expected Result**: HTTP 200 with `{"error": "no address provided"}`

## Tips for Testing

1. **Modify Test Events**: Feel free to modify the test events to test different scenarios:
   - Change the `eth_address` parameter to test different addresses
   - Modify headers to test authentication or rate limiting
   - Add query parameters if needed

2. **Case Sensitivity**: The API supports case-insensitive Ethereum addresses. Test with:
   - All lowercase: `0x742d35cc6634c0532925a3b844bc9e7595f89590`
   - All uppercase: `0X742D35CC6634C0532925A3B844BC9E7595F89590`
   - Mixed case: `0x742d35Cc6634C0532925a3b844Bc9e7595f89590`

3. **Well-Known Test Addresses**: When using filesystem backend, these addresses have pre-configured balances:
   - `0xd8da6bf26964af9d7eed9e03e53415d37aa96045` - 325,159.5 ETH (Vitalik)
   - `0x00000000219ab540356cbb839cbe05303d7705fa` - 50,000,000 ETH (Beacon Deposit)
   - `0x742d35cc6634c0532925a3b844bc9e7595f89590` - 1,234,567.89 ETH (BitGo)
   - `0x0000000000000000000000000000000000000000` - 0 ETH (Zero address)

4. **Response Formats**:
   - Modern API: Returns detailed JSON with metadata
   - Legacy API: Returns simple `{"balance": <number>}` or `{"error": "<message>"}`

5. **HTTP Status Codes**:
   - Modern API: Uses proper HTTP status codes (200, 400, 500)
   - Legacy API: Always returns 200, even for errors

## Creating New Test Events

To create a new test event:

1. Copy an existing test event as a template
2. Modify the relevant fields:
   - `path`: The API path being tested
   - `pathParameters`: URL path parameters
   - `queryStringParameters`: Query string parameters (if any)
   - `headers`: HTTP headers
   - `body`: Request body (for POST/PUT requests)
3. Update the `requestId` to be unique
4. Save with a descriptive filename

## Integration with CI/CD

These test events can also be used in automated testing:

```bash
# Example: Using AWS CLI to test Lambda locally
aws lambda invoke \
  --function-name my-function \
  --payload file://test-events/api-gateway/get-balance-valid.json \
  response.json
```

## Notes

- All test events use `stage: "dev"` by default
- The `apiId` and `domainName` are placeholders and will be replaced by API Gateway
- User-Agent headers help identify test traffic in logs
- Source IPs use private ranges for test identification