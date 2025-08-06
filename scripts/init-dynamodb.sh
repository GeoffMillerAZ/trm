#!/bin/bash
set -e

echo "Checking if DynamoDB table exists..."

# Check if table exists
if aws dynamodb describe-table \
    --table-name trm-blockexplorer-local-wan \
    --endpoint-url http://dynamodb:8000 \
    --region us-east-1 2>/dev/null; then
    echo "Table trm-blockexplorer-local-wan already exists"
    exit 0
fi

echo "Creating DynamoDB table..."

# Create table
aws dynamodb create-table \
    --endpoint-url http://dynamodb:8000 \
    --table-name trm-blockexplorer-local-wan \
    --attribute-definitions \
        AttributeName=PK,AttributeType=S \
        AttributeName=SK,AttributeType=S \
    --key-schema \
        AttributeName=PK,KeyType=HASH \
        AttributeName=SK,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --no-cli-pager

echo "Table created successfully"