package test_simple

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.main

# Simple test to verify OPA is working
test_basic_policy_loading if {
    # Just test that we can load and execute policies
    result := main.deny with input as {
        "variables": {"environment": {"value": "prod"}},
        "resource_changes": []
    }
    
    # With no resources, there should be no denials
    count(result) == 0
}

# Test that S3 encryption policy triggers
test_s3_encryption_denial if {
    result := main.deny with input as {
        "variables": {"environment": {"value": "prod"}},
        "resource_changes": [{
            "type": "aws_s3_bucket",
            "address": "aws_s3_bucket.test",
            "change": {"actions": ["create"]},
            "values": {
                "bucket": "test-bucket",
                "tags": {
                    "Environment": "prod",
                    "Project": "test",
                    "ManagedBy": "terraform",
                    "Owner": "team",
                    "CostCenter": "eng",
                    "BackupSchedule": "daily"
                }
            }
        }]
    }
    
    # Should have some denials (encryption, versioning, public access block)
    count(result) > 0
}