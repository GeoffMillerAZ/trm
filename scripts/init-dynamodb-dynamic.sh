#!/bin/bash
set -e

# Use TABLE_NAME from environment or default
TABLE_NAME="${TABLE_NAME:-trm-blockexplorer}"

echo "Checking if DynamoDB table ${TABLE_NAME} exists..."

# Check if table exists
if aws dynamodb describe-table \
    --table-name "${TABLE_NAME}" \
    --endpoint-url http://dynamodb:8000 \
    --region us-east-1 2>/dev/null; then
    echo "Table ${TABLE_NAME} already exists"
    exit 0
fi

echo "Creating DynamoDB table ${TABLE_NAME}..."

# Create table
aws dynamodb create-table \
    --endpoint-url http://dynamodb:8000 \
    --table-name "${TABLE_NAME}" \
    --attribute-definitions \
        AttributeName=PK,AttributeType=S \
        AttributeName=SK,AttributeType=S \
    --key-schema \
        AttributeName=PK,KeyType=HASH \
        AttributeName=SK,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --no-cli-pager

echo "Table ${TABLE_NAME} created successfully"