# Implement DynamoDB Infrastructure Layer

## Goal
Implement DynamoDB infrastructure adapters and repository patterns to support TRM's multi-region watchlist, transaction tracking, and investigation workflows.

## Dependencies
- **Lambda Infrastructure**: See `specs/implement-lambda-infrastructure.md` for Lambda function access patterns
- **API Gateway Infrastructure**: See `specs/implement-api-gateway-infrastructure.md` for API integration
- **Multi-Region Data Strategy**: See `docs/adr/ADR-016-multi-region-data-strategy.md` for data replication approach
- **Database Technology Selection**: See `docs/adr/ADR-014-database-technology-selection.md` for DynamoDB choice rationale
- **AWS Serverless Architecture**: See `docs/adr/ADR-017-aws-serverless-infrastructure-architecture.md`

## Context
TRM requires global active-active database capabilities for compliance data that must be accessible instantly across multiple regions. The current template uses PostgreSQL/SQLAlchemy, but we need DynamoDB Global Tables for multi-region synchronization.

**Business Requirements:**
- Analysts in NYC add suspicious address → London team sees it immediately
- Transaction flagged in US-East appears instantly in US-West
- Business continuity: if US-East fails, US-West continues with full data access
- Audit trail: All changes captured for compliance reporting

**Technical Requirements:**
- DynamoDB Global Tables configuration for multi-region replication
- Repository pattern maintaining clean architecture boundaries
- Connection management and session handling
- Error handling for eventual consistency scenarios

## Requirements

### Functional Requirements
- **Repository interfaces**: Define domain repository contracts independent of DynamoDB
- **DynamoDB adapters**: Implement repositories using boto3/aioboto3
- **Connection management**: Handle DynamoDB client lifecycle and configuration
- **Data mapping**: Convert between domain entities and DynamoDB items
- **Query patterns**: Support GSI queries for different access patterns
- **Pagination**: Handle DynamoDB pagination for large result sets

### Non-Functional Requirements
- **Performance**: Queries complete within 100ms for single-item operations
- **Reliability**: Handle DynamoDB throttling and transient errors with retries
- **Consistency**: Understand and handle eventual consistency in Global Tables
- **Observability**: Comprehensive logging of DynamoDB operations
- **Configuration**: Environment-based endpoint and region configuration

### DDD Architecture Requirements
- **Repository interfaces in domain**: Pure interfaces with no infrastructure dependencies
- **Infrastructure implementations**: DynamoDB-specific repository implementations  
- **Dependency injection**: Repositories injected into application services
- **Error translation**: Convert DynamoDB exceptions to domain exceptions
- **Unit testability**: Mock-friendly interfaces for testing

## Acceptance Tests

### Repository Interface Tests
- Domain repository interfaces have no boto3 or DynamoDB dependencies
- Repository methods return domain entities, not DynamoDB items
- Repository interfaces are properly abstract (cannot be instantiated directly)

### DynamoDB Adapter Tests  
- `DynamoDbWatchlistRepository.save()` persists `WatchlistedAddress` entity correctly
- `DynamoDbWatchlistRepository.get_by_address()` returns proper domain entity
- Repositories handle DynamoDB exceptions and convert to domain exceptions
- Connection failures result in appropriate infrastructure exceptions

### Integration Tests
- End-to-end test: Save domain entity → retrieve from different DynamoDB client
- Multi-region test: Write to one region → verify replication in another region
- Pagination test: Large result sets properly paginated with continuation tokens
- Query patterns: GSI queries work for risk level, analyst, and date filtering

### Performance Tests
- Single item operations complete within 100ms
- Batch operations handle up to 25 items efficiently  
- Query operations with GSI complete within 200ms
- Memory usage remains constant during large result set iteration

## Out of Scope
- **Application Logic**: Domain-specific business rules and use cases
- **API Layer**: FastAPI route handlers and presentation layer
- **Authentication**: User authentication and authorization mechanisms
- **Advanced Cost Optimization**: Reserved capacity planning and advanced optimization strategies
- **Data Migration**: Moving existing data from other database systems
- **Backup Strategy**: Advanced backup and disaster recovery procedures beyond point-in-time recovery

## Implementation Hints

### Domain Repository Interfaces
```python
# src/domain/repositories/watchlist_repository.py
from abc import ABC, abstractmethod
from typing import List, Optional
from src.domain.entities.watchlisted_address import WatchlistedAddress
from src.domain.value_objects.ethereum_address import EthereumAddress

class WatchlistRepository(ABC):
    @abstractmethod
    async def save(self, address: WatchlistedAddress) -> None:
        pass
    
    @abstractmethod 
    async def get_by_address(self, address: EthereumAddress) -> Optional[WatchlistedAddress]:
        pass
        
    @abstractmethod
    async def list_by_risk_level(self, risk_level: RiskLevel, limit: int = 50) -> List[WatchlistedAddress]:
        pass
```

### DynamoDB Infrastructure Implementation
```python
# src/infrastructure/repositories/dynamodb_watchlist_repository.py
import boto3
from typing import Dict, Any
from src.domain.repositories.watchlist_repository import WatchlistRepository
from src.infrastructure.database.dynamodb_connection import DynamoDbConnection

class DynamoDbWatchlistRepository(WatchlistRepository):
    def __init__(self, connection: DynamoDbConnection):
        self.connection = connection
        self.table_name = "AddressWatchlist"
    
    async def save(self, address: WatchlistedAddress) -> None:
        item = self._to_dynamodb_item(address)
        await self.connection.put_item(self.table_name, item)
    
    def _to_dynamodb_item(self, address: WatchlistedAddress) -> Dict[str, Any]:
        # Convert domain entity to DynamoDB item format
        pass
        
    def _to_domain_entity(self, item: Dict[str, Any]) -> WatchlistedAddress:
        # Convert DynamoDB item to domain entity  
        pass
```

### Connection Management
```python  
# src/infrastructure/database/dynamodb_connection.py
import aioboto3
from typing import Dict, Any, Optional
import structlog

class DynamoDbConnection:
    def __init__(self, region: str, endpoint_url: Optional[str] = None):
        self.region = region
        self.endpoint_url = endpoint_url
        self.logger = structlog.get_logger(__name__)
        self._session = None
        self._client = None
    
    async def connect(self) -> None:
        self._session = aioboto3.Session()
        self._client = self._session.client(
            'dynamodb',
            region_name=self.region,
            endpoint_url=self.endpoint_url
        )
        
    async def put_item(self, table_name: str, item: Dict[str, Any]) -> None:
        try:
            response = await self._client.put_item(
                TableName=table_name,
                Item=item
            )
            self.logger.info("DynamoDB put_item successful", 
                           table=table_name, 
                           consumed_capacity=response.get('ConsumedCapacity'))
        except Exception as e:
            self.logger.error("DynamoDB put_item failed", 
                            table=table_name, 
                            error=str(e))
            raise
```

### Terraform Infrastructure Module
```hcl
# iac/terraform/modules/dynamodb/main.tf
resource "aws_dynamodb_table" "address_watchlist" {
  name             = "${var.table_prefix}-AddressWatchlist"
  billing_mode     = "ON_DEMAND"
  hash_key         = "address"
  range_key        = "sort_key"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "address"
    type = "S"
  }

  attribute {
    name = "sort_key"
    type = "S"
  }

  attribute {
    name = "risk_level"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "added_by"
    type = "S"
  }

  # GSI for querying by risk level
  global_secondary_index {
    name     = "risk-level-index"
    hash_key = "risk_level"
    range_key = "created_at"
    projection_type = "ALL"
  }

  # GSI for querying by analyst
  global_secondary_index {
    name     = "added-by-index"
    hash_key = "added_by"
    range_key = "created_at"
    projection_type = "ALL"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled     = true
    kms_key_id  = var.kms_key_id
  }

  tags = merge(var.tags, {
    Name        = "${var.table_prefix}-AddressWatchlist"
    TableType   = "watchlist"
    Environment = var.environment
  })
}

# Similar configuration for SuspiciousTransactions table
resource "aws_dynamodb_table" "suspicious_transactions" {
  name             = "${var.table_prefix}-SuspiciousTransactions"
  billing_mode     = "ON_DEMAND"
  hash_key         = "transaction_hash"
  range_key        = "block_number"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "transaction_hash"
    type = "S"
  }

  attribute {
    name = "block_number"
    type = "N"
  }

  attribute {
    name = "risk_score"
    type = "N"
  }

  attribute {
    name = "flagged_at"
    type = "S"
  }

  # GSI for querying by risk score
  global_secondary_index {
    name     = "risk-score-index"
    hash_key = "risk_score"
    range_key = "flagged_at"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_id  = var.kms_key_id
  }

  tags = merge(var.tags, {
    Name        = "${var.table_prefix}-SuspiciousTransactions"
    TableType   = "transactions"
    Environment = var.environment
  })
}

# Investigation Notes table
resource "aws_dynamodb_table" "investigation_notes" {
  name             = "${var.table_prefix}-InvestigationNotes"
  billing_mode     = "ON_DEMAND"
  hash_key         = "investigation_id"
  range_key        = "note_id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "investigation_id"
    type = "S"
  }

  attribute {
    name = "note_id"
    type = "S"
  }

  attribute {
    name = "analyst_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  # GSI for querying by analyst
  global_secondary_index {
    name     = "analyst-index"
    hash_key = "analyst_id"
    range_key = "created_at"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_id  = var.kms_key_id
  }

  tags = merge(var.tags, {
    Name        = "${var.table_prefix}-InvestigationNotes"
    TableType   = "notes"
    Environment = var.environment
  })
}
```

### Global Tables Configuration
```hcl
# iac/terraform/modules/dynamodb/global-tables.tf
resource "aws_dynamodb_global_table" "address_watchlist" {
  count = var.enable_global_tables ? 1 : 0
  
  name = aws_dynamodb_table.address_watchlist.name

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value
    }
  }

  depends_on = [aws_dynamodb_table.address_watchlist]
}

resource "aws_dynamodb_global_table" "suspicious_transactions" {
  count = var.enable_global_tables ? 1 : 0
  
  name = aws_dynamodb_table.suspicious_transactions.name

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value
    }
  }

  depends_on = [aws_dynamodb_table.suspicious_transactions]
}

resource "aws_dynamodb_global_table" "investigation_notes" {
  count = var.enable_global_tables ? 1 : 0
  
  name = aws_dynamodb_table.investigation_notes.name

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value
    }
  }

  depends_on = [aws_dynamodb_table.investigation_notes]
}
```

### Environment Configuration
```python
# src/infrastructure/config/dynamodb_config.py
from pydantic import BaseSettings

class DynamoDbConfig(BaseSettings):
    aws_region: str = "us-west-2"
    dynamodb_endpoint_url: Optional[str] = None  # For local development
    table_prefix: str = "trm-blockexplorer"
    
    class Config:
        env_file = ".env"
        env_prefix = "DYNAMODB_"
```

### Directory Structure
```
src/infrastructure/
├── database/
│   ├── dynamodb_connection.py    # Connection and client management
│   └── dynamodb_models.py        # Item mapping utilities
├── repositories/
│   ├── dynamodb_watchlist_repository.py
│   ├── dynamodb_transactions_repository.py
│   └── dynamodb_investigations_repository.py
└── config/
    └── dynamodb_config.py        # Configuration management
```

### Module Variables and Outputs
```hcl
# iac/terraform/modules/dynamodb/variables.tf
variable "table_prefix" {
  description = "Prefix for DynamoDB table names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = "alias/aws/dynamodb"
}

variable "enable_global_tables" {
  description = "Enable Global Tables replication"
  type        = bool
  default     = false
}

variable "replica_regions" {
  description = "List of regions for Global Tables replication"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# iac/terraform/modules/dynamodb/outputs.tf
output "address_watchlist_table_name" {
  description = "Name of the Address Watchlist table"
  value       = aws_dynamodb_table.address_watchlist.name
}

output "address_watchlist_table_arn" {
  description = "ARN of the Address Watchlist table"
  value       = aws_dynamodb_table.address_watchlist.arn
}

output "suspicious_transactions_table_name" {
  description = "Name of the Suspicious Transactions table"
  value       = aws_dynamodb_table.suspicious_transactions.name
}

output "suspicious_transactions_table_arn" {
  description = "ARN of the Suspicious Transactions table"
  value       = aws_dynamodb_table.suspicious_transactions.arn
}

output "investigation_notes_table_name" {
  description = "Name of the Investigation Notes table"
  value       = aws_dynamodb_table.investigation_notes.name
}

output "investigation_notes_table_arn" {
  description = "ARN of the Investigation Notes table"
  value       = aws_dynamodb_table.investigation_notes.arn
}

output "table_arns" {
  description = "List of all table ARNs"
  value = [
    aws_dynamodb_table.address_watchlist.arn,
    aws_dynamodb_table.suspicious_transactions.arn, 
    aws_dynamodb_table.investigation_notes.arn
  ]
}
```

### Regional Deployment Configuration
```hcl
# iac/terraform/projects/trm-blockexplorer/us-west-2/dynamodb.tf
module "dynamodb_tables" {
  source = "../../../modules/dynamodb"
  
  table_prefix = "trm-blockexplorer-${var.environment}"
  environment  = var.environment
  
  # Enable Global Tables for production only
  enable_global_tables = var.environment == "prod"
  replica_regions = var.environment == "prod" ? [
    "us-west-2",
    "us-east-2"
  ] : []
  
  # Use customer-managed KMS key for production
  kms_key_id = var.environment == "prod" ? aws_kms_key.dynamodb[0].arn : "alias/aws/dynamodb"
  
  tags = local.common_tags
}

# Customer-managed KMS key for production encryption
resource "aws_kms_key" "dynamodb" {
  count = var.environment == "prod" ? 1 : 0
  
  description             = "TRM Block Explorer DynamoDB encryption key"
  deletion_window_in_days = 7
  
  tags = merge(local.common_tags, {
    Name = "trm-blockexplorer-${var.environment}-dynamodb-key"
  })
}

resource "aws_kms_alias" "dynamodb" {
  count = var.environment == "prod" ? 1 : 0
  
  name          = "alias/trm-blockexplorer-${var.environment}-dynamodb"
  target_key_id = aws_kms_key.dynamodb[0].key_id
}
```

### Dependencies to Add
```toml
# Add to pyproject.toml
[tool.uv.dependencies]
aioboto3 = "^12.0.0"
boto3 = "^1.34.0"  
botocore = "^1.34.0"
```

### Enhanced Connection Management with Global Tables Support
```python
# src/infrastructure/database/dynamodb_connection.py
import aioboto3
from typing import Dict, Any, Optional, List
import structlog
from botocore.exceptions import ClientError
import asyncio
from datetime import datetime, timezone

class DynamoDbConnection:
    def __init__(self, 
                 region: str, 
                 endpoint_url: Optional[str] = None,
                 retry_config: Optional[Dict] = None):
        self.region = region
        self.endpoint_url = endpoint_url
        self.logger = structlog.get_logger(__name__)
        self._session = None
        self._client = None
        self._retry_config = retry_config or {
            'max_attempts': 3,
            'mode': 'adaptive'
        }
    
    async def connect(self) -> None:
        """Initialize DynamoDB client with retry configuration"""
        self._session = aioboto3.Session()
        self._client = self._session.client(
            'dynamodb',
            region_name=self.region,
            endpoint_url=self.endpoint_url,
            config=self._retry_config
        )
        
        # Test connection
        try:
            await self._client.list_tables(Limit=1)
            self.logger.info("DynamoDB connection established", region=self.region)
        except Exception as e:
            self.logger.error("Failed to connect to DynamoDB", 
                            region=self.region, error=str(e))
            raise
    
    async def put_item_with_metadata(self, table_name: str, item: Dict[str, Any]) -> None:
        """Put item with automatic metadata injection"""
        # Add metadata for audit trail
        enhanced_item = {
            **item,
            'updated_at': {'S': datetime.now(timezone.utc).isoformat()},
            'region': {'S': self.region}
        }
        
        try:
            response = await self._client.put_item(
                TableName=table_name,
                Item=enhanced_item,
                ReturnConsumedCapacity='TOTAL'
            )
            
            self.logger.info("DynamoDB put_item successful", 
                           table=table_name,
                           region=self.region,
                           consumed_capacity=response.get('ConsumedCapacity', {}).get('CapacityUnits'))
                           
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == 'ProvisionedThroughputExceededException':
                self.logger.warning("DynamoDB throttling detected", 
                                  table=table_name, region=self.region)
                # Implement exponential backoff
                await asyncio.sleep(0.1 * (2 ** 1))  # Start with 200ms delay
                raise
            else:
                self.logger.error("DynamoDB put_item failed", 
                                table=table_name, 
                                region=self.region,
                                error_code=error_code,
                                error_message=e.response['Error']['Message'])
                raise
    
    async def get_item_with_consistency(self, 
                                      table_name: str, 
                                      key: Dict[str, Any],
                                      consistent_read: bool = False) -> Optional[Dict[str, Any]]:
        """Get item with configurable consistency for Global Tables"""
        try:
            response = await self._client.get_item(
                TableName=table_name,
                Key=key,
                ConsistentRead=consistent_read,
                ReturnConsumedCapacity='TOTAL'
            )
            
            item = response.get('Item')
            if item:
                self.logger.debug("DynamoDB get_item successful",
                                table=table_name,
                                region=self.region,
                                consistent_read=consistent_read,
                                consumed_capacity=response.get('ConsumedCapacity', {}).get('CapacityUnits'))
            
            return item
            
        except ClientError as e:
            self.logger.error("DynamoDB get_item failed",
                            table=table_name,
                            region=self.region,
                            error=str(e))
            raise
    
    async def query_gsi_with_pagination(self, 
                                       table_name: str,
                                       index_name: str,
                                       key_condition: str,
                                       expression_values: Dict[str, Any],
                                       limit: int = 50,
                                       last_evaluated_key: Optional[Dict] = None) -> Dict[str, Any]:
        """Query GSI with pagination support"""
        query_params = {
            'TableName': table_name,
            'IndexName': index_name,
            'KeyConditionExpression': key_condition,
            'ExpressionAttributeValues': expression_values,
            'Limit': limit,
            'ReturnConsumedCapacity': 'TOTAL'
        }
        
        if last_evaluated_key:
            query_params['ExclusiveStartKey'] = last_evaluated_key
        
        try:
            response = await self._client.query(**query_params)
            
            self.logger.info("DynamoDB query successful",
                           table=table_name,
                           index=index_name,
                           region=self.region,
                           item_count=response['Count'],
                           consumed_capacity=response.get('ConsumedCapacity', {}).get('CapacityUnits'))
            
            return response
            
        except ClientError as e:
            self.logger.error("DynamoDB query failed",
                            table=table_name,
                            index=index_name,
                            region=self.region,
                            error=str(e))
            raise
```

### Multi-Region Repository Implementation
```python
# src/infrastructure/repositories/multi_region_watchlist_repository.py
from typing import List, Optional
from src.domain.repositories.watchlist_repository import WatchlistRepository
from src.domain.entities.watchlisted_address import WatchlistedAddress
from src.domain.value_objects.ethereum_address import EthereumAddress
from src.infrastructure.database.dynamodb_connection import DynamoDbConnection
import structlog

class MultiRegionWatchlistRepository(WatchlistRepository):
    """Multi-region aware DynamoDB watchlist repository"""
    
    def __init__(self, primary_connection: DynamoDbConnection, 
                 secondary_connection: Optional[DynamoDbConnection] = None):
        self.primary_connection = primary_connection
        self.secondary_connection = secondary_connection
        self.table_name = "trm-blockexplorer-AddressWatchlist"
        self.logger = structlog.get_logger(__name__)
    
    async def save(self, address: WatchlistedAddress) -> None:
        """Save to primary region with Global Tables replication"""
        item = self._to_dynamodb_item(address)
        
        try:
            await self.primary_connection.put_item_with_metadata(
                self.table_name, item
            )
            self.logger.info("Address saved to watchlist", 
                           address=address.address.value,
                           risk_level=address.risk_level)
                           
        except Exception as e:
            self.logger.error("Failed to save address to watchlist",
                            address=address.address.value,
                            error=str(e))
            
            # Fallback to secondary region if available
            if self.secondary_connection:
                try:
                    await self.secondary_connection.put_item_with_metadata(
                        self.table_name, item
                    )
                    self.logger.info("Address saved to secondary region",
                                   address=address.address.value)
                except Exception as secondary_error:
                    self.logger.error("Failed to save to secondary region",
                                    address=address.address.value,
                                    error=str(secondary_error))
                    raise
            else:
                raise
    
    async def get_by_address(self, address: EthereumAddress) -> Optional[WatchlistedAddress]:
        """Get address with eventual consistency handling"""
        key = {
            'address': {'S': address.value},
            'sort_key': {'S': 'METADATA'}
        }
        
        # Try primary region first with eventual consistency
        try:
            item = await self.primary_connection.get_item_with_consistency(
                self.table_name, key, consistent_read=False
            )
            
            if item:
                return self._to_domain_entity(item)
                
        except Exception as e:
            self.logger.warning("Primary region unavailable, trying secondary",
                              address=address.value, error=str(e))
            
            # Fallback to secondary region
            if self.secondary_connection:
                try:
                    item = await self.secondary_connection.get_item_with_consistency(
                        self.table_name, key, consistent_read=False
                    )
                    
                    if item:
                        return self._to_domain_entity(item)
                        
                except Exception as secondary_error:
                    self.logger.error("Both regions unavailable",
                                    address=address.value,
                                    secondary_error=str(secondary_error))
                    raise
        
        return None
    
    async def list_by_risk_level(self, risk_level: str, limit: int = 50) -> List[WatchlistedAddress]:
        """Query by risk level using GSI with pagination"""
        try:
            response = await self.primary_connection.query_gsi_with_pagination(
                table_name=self.table_name,
                index_name="risk-level-index",
                key_condition="risk_level = :risk_level",
                expression_values={
                    ':risk_level': {'S': risk_level}
                },
                limit=limit
            )
            
            addresses = []
            for item in response.get('Items', []):
                entity = self._to_domain_entity(item)
                if entity:
                    addresses.append(entity)
            
            return addresses
            
        except Exception as e:
            self.logger.error("Failed to query by risk level",
                            risk_level=risk_level, error=str(e))
            raise
    
    def _to_dynamodb_item(self, address: WatchlistedAddress) -> Dict[str, Any]:
        """Convert domain entity to DynamoDB item format"""
        return {
            'address': {'S': address.address.value},
            'sort_key': {'S': 'METADATA'},
            'risk_level': {'S': address.risk_level},
            'reason': {'S': address.reason},
            'added_by': {'S': address.added_by},
            'created_at': {'S': address.created_at.isoformat()},
            'notes': {'S': address.notes or ''}
        }
    
    def _to_domain_entity(self, item: Dict[str, Any]) -> Optional[WatchlistedAddress]:
        """Convert DynamoDB item to domain entity"""
        try:
            return WatchlistedAddress(
                address=EthereumAddress(item['address']['S']),
                risk_level=item['risk_level']['S'],
                reason=item['reason']['S'],
                added_by=item['added_by']['S'],
                created_at=datetime.fromisoformat(item['created_at']['S']),
                notes=item.get('notes', {}).get('S')
            )
        except (KeyError, ValueError) as e:
            self.logger.error("Failed to convert DynamoDB item to entity",
                            item=item, error=str(e))
            return None
```

### Testing Strategy
- **Unit Tests**: Mock DynamoDB client, test entity mapping and error handling
- **Integration Tests**: Use DynamoDB Local container for testing repository implementations
- **Multi-Region Tests**: Deploy to actual AWS regions and test Global Tables replication
- **Performance Tests**: Measure operation latencies and throughput under load
- **Consistency Tests**: Verify eventual consistency behavior and conflict resolution
- **Failover Tests**: Test automatic failover to secondary regions during outages

### Monitoring and Observability
```hcl
# iac/terraform/modules/dynamodb/monitoring.tf
resource "aws_cloudwatch_dashboard" "dynamodb" {
  dashboard_name = "${var.table_prefix}-dynamodb-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.address_watchlist.name],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", aws_dynamodb_table.address_watchlist.name],
            ["AWS/DynamoDB", "ThrottledRequests", "TableName", aws_dynamodb_table.address_watchlist.name]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB Capacity and Throttling"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttling" {
  alarm_name          = "${var.table_prefix}-dynamodb-throttling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "DynamoDB throttling detected"
  alarm_actions       = [var.sns_topic_arn]
  
  dimensions = {
    TableName = aws_dynamodb_table.address_watchlist.name
  }
}
```

This enhanced DynamoDB infrastructure specification provides comprehensive support for TRM's global compliance operations with multi-region active-active capabilities, robust error handling, and production-ready monitoring.