"""
AWS Lambda function to export Software Bill of Materials (SBOM) from Inspector v2.

This function is triggered periodically to export SBOM data from AWS Inspector v2
and store it in an S3 bucket for compliance and auditing purposes.
"""
import json
import os
import boto3
from datetime import datetime
from typing import Dict, Any


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for SBOM export.
    
    Args:
        event: Lambda event data
        context: Lambda context object
        
    Returns:
        Response indicating success or failure
    """
    inspector_client = boto3.client('inspector2')
    s3_client = boto3.client('s3')
    
    bucket_name = os.environ.get('SBOM_BUCKET_NAME')
    if not bucket_name:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'SBOM_BUCKET_NAME environment variable not set'})
        }
    
    try:
        # List findings to export
        findings_response = inspector_client.list_findings(
            filterCriteria={
                'resourceType': [
                    {'comparison': 'EQUALS', 'value': 'AWS_LAMBDA_FUNCTION'}
                ]
            },
            maxResults=100
        )
        
        # Prepare SBOM data
        timestamp = datetime.utcnow().isoformat()
        sbom_data = {
            'exportTimestamp': timestamp,
            'findings': findings_response.get('findings', []),
            'totalFindings': len(findings_response.get('findings', []))
        }
        
        # Store in S3
        key = f"sbom-exports/{datetime.utcnow().strftime('%Y/%m/%d')}/sbom-{timestamp}.json"
        s3_client.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=json.dumps(sbom_data, indent=2),
            ContentType='application/json'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'SBOM export completed successfully',
                'location': f's3://{bucket_name}/{key}',
                'findingsCount': sbom_data['totalFindings']
            })
        }
        
    except Exception as e:
        print(f"Error exporting SBOM: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Failed to export SBOM',
                'details': str(e)
            })
        }