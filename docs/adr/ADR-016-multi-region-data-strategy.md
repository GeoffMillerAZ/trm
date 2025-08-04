# ADR-016: Multi-Region Data Strategy for Global Compliance Operations

## Status

Accepted

## Context

TRM's Block Explorer serves global compliance operations with analysts working across multiple time zones and regions. Anti-money laundering (AML) compliance requires real-time access to watchlist data, suspicious transaction records, and investigation notes from any location to enable coordinated threat response.

**Business Requirements:**
- **Global Team Collaboration**: Analysts in NYC, London, Singapore must collaborate on same investigations
- **24/7 Operations**: Compliance monitoring continues across time zones without handoff delays
- **Regulatory Reporting**: Audit trails must capture all changes regardless of origin region
- **Business Continuity**: Regional outages cannot halt compliance operations
- **Data Sovereignty**: Some data may have regional residency requirements

**Technical Challenges:**
- **Network Latency**: Cross-region database calls can introduce 100-200ms latency
- **Data Consistency**: Multiple regions writing to same records creates conflict scenarios  
- **Failover Complexity**: Automatic failover must preserve data integrity
- **Cost Optimization**: Multi-region replication can significantly increase costs
- **Monitoring Complexity**: Need visibility into replication lag and conflicts

**Current State:**
- Single-region deployment in us-west-2
- PostgreSQL database with local backup strategy
- No cross-region replication capabilities
- Manual disaster recovery procedures

## Decision

Implement **DynamoDB Global Tables** with active-active multi-region replication across three primary regions: **us-west-2** (primary), **us-east-1** (secondary), and **eu-west-1** (European operations).

**Architecture:**
- All compliance data (watchlists, transactions, investigations) replicated across all three regions
- Applications deployed in each region connect to local DynamoDB endpoints
- Cross-region replication handled automatically by DynamoDB Global Tables
- Regional failover managed by DNS and load balancer routing

## Alternatives Considered

### 1. Single Region with Cross-Region Application Calls
- **Pros**: Simple architecture, single source of truth, no replication complexity
- **Cons**: High latency for distant regions, single point of failure, poor user experience
- **Verdict**: Unacceptable for global 24/7 operations

### 2. Read Replicas with Primary-Secondary Pattern
- **Pros**: Fast reads globally, simpler conflict resolution, lower cost
- **Cons**: Writes still go to primary region, complex failover, uneven user experience
- **Verdict**: Doesn't meet active-active requirement for compliance writes

### 3. Regional Data Partitioning
- **Pros**: No replication conflicts, clear data ownership, regulatory compliance
- **Cons**: Cannot collaborate on cross-regional investigations, data silos
- **Verdict**: Conflicts with global collaboration requirements

### 4. Event Sourcing with Regional Aggregates
- **Pros**: Strong audit trail, eventual consistency, complex event handling
- **Cons**: High implementation complexity, difficult debugging, steep learning curve
- **Verdict**: Over-engineered for current requirements

### 5. DynamoDB Global Tables with Active-Active (Chosen)
- **Pros**: True multi-region writes, automatic replication, managed service, audit trails
- **Cons**: Eventual consistency, conflict resolution complexity, higher cost
- **Verdict**: Best balance of features and operational simplicity

### 6. Multi-Master PostgreSQL with Logical Replication
- **Pros**: SQL interface, ACID transactions, complex queries
- **Cons**: Conflict resolution challenges, operational complexity, limited AWS support
- **Verdict**: High operational overhead, not managed service

## Multi-Region Architecture

### Region Selection and Roles

**Primary Region: us-west-2 (US West - Oregon)**
- **Role**: Primary development and operations hub
- **Justification**: TRM headquarters, existing infrastructure, low latency to Pacific operations
- **Services**: Full application stack, monitoring, CI/CD infrastructure

**Secondary Region: us-east-1 (US East - Virginia)**
- **Role**: Business continuity and East Coast operations
- **Justification**: Disaster recovery for us-west-2, low latency for East Coast analysts
- **Services**: Full application stack, automated failover target

**European Region: eu-west-1 (Europe - Ireland)**
- **Role**: European operations and GDPR compliance
- **Justification**: Data residency requirements, London office operations, regulatory compliance
- **Services**: Full application stack, GDPR-compliant operations

### DynamoDB Global Tables Configuration

```yaml
# DynamoDB Global Tables Setup
Tables:
  AddressWatchlist:
    Regions: [us-west-2, us-east-1, eu-west-1]
    BillingMode: PAY_PER_REQUEST
    StreamSpecification:
      StreamEnabled: true
      StreamViewType: NEW_AND_OLD_IMAGES
    PointInTimeRecovery: true
    
  SuspiciousTransactions:
    Regions: [us-west-2, us-east-1, eu-west-1] 
    BillingMode: PAY_PER_REQUEST
    StreamSpecification:
      StreamEnabled: true
      StreamViewType: NEW_AND_OLD_IMAGES
    PointInTimeRecovery: true
    
  InvestigationNotes:
    Regions: [us-west-2, us-east-1, eu-west-1]
    BillingMode: PAY_PER_REQUEST
    StreamSpecification:
      StreamEnabled: true
      StreamViewType: NEW_AND_OLD_IMAGES
    PointInTimeRecovery: true
```

### Conflict Resolution Strategy

**DynamoDB Global Tables Behavior:**
- **Last Writer Wins**: Conflicts resolved based on timestamp
- **Item-Level Resolution**: Conflicts resolved per item, not per transaction
- **Automatic Resolution**: No manual intervention required for conflicts

**Application-Level Conflict Handling:**
```python
# Optimistic locking for critical updates
@dataclass
class WatchlistedAddress:
    version: int = field(default=1)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    
    def update_risk_level(self, new_risk_level: RiskLevel, updated_by: str):
        # Increment version for optimistic locking
        self.version += 1
        self.updated_at = datetime.utcnow()
        self.risk_level = new_risk_level
        
# Repository implements version checking
class DynamoDbWatchlistRepository:
    async def save(self, address: WatchlistedAddress) -> None:
        try:
            await self.connection.put_item(
                table_name=self.table_name,
                item=self._to_dynamodb_item(address),
                condition_expression="version = :expected_version",
                expression_attribute_values={":expected_version": address.version - 1}
            )
        except ConditionalCheckFailedException:
            raise OptimisticLockException("Address was modified by another user")
```

### Regional Deployment Strategy

**Application Deployment:**
- Identical application stacks deployed in all three regions
- Regional DynamoDB endpoints configured per region
- Application connects to local DynamoDB for optimal performance
- Cross-region calls only for blockchain APIs (Infura)

**DNS and Load Balancing:**
```yaml
# Route 53 configuration for regional routing
DNS:
  trm-api.example.com:
    Type: Latency-based routing
    Records:
      - Region: us-west-2
        Endpoint: us-west-2-lb.example.com
        Weight: 100
      - Region: us-east-1  
        Endpoint: us-east-1-lb.example.com
        Weight: 100
      - Region: eu-west-1
        Endpoint: eu-west-1-lb.example.com
        Weight: 100
    HealthChecks: Enabled
    Failover: Automatic
```

## Consequences

### Positive
- **Global Performance**: < 50ms database response times from any region
- **Business Continuity**: Automatic failover with no data loss
- **Regulatory Compliance**: EU data residency requirements met
- **Team Collaboration**: Real-time collaboration across all regions
- **Operational Simplicity**: AWS manages replication, failover, and conflict resolution
- **Audit Compliance**: DynamoDB Streams provide complete audit trail across regions
- **Scalability**: Automatic scaling handles traffic from all regions

### Negative
- **Cost Impact**: ~3x database costs due to multi-region replication
- **Eventual Consistency**: Brief periods where regions may have different data
- **Conflict Scenarios**: Race conditions require application-level handling
- **Operational Complexity**: Monitoring and debugging across multiple regions
- **Network Dependencies**: Cross-region replication depends on AWS network reliability
- **Data Transfer Costs**: Replication traffic incurs cross-region data transfer charges

### Neutral
- **Consistency Model**: Shift from strong consistency to eventual consistency
- **Monitoring Strategy**: Need region-aware dashboards and alerting
- **Testing Complexity**: Multi-region integration testing required
- **Disaster Recovery**: Simplified DR due to active-active architecture

## Implementation Strategy

### Phase 1: Infrastructure Setup (Week 1-2)
- Configure DynamoDB Global Tables across three regions
- Set up VPCs and networking in us-east-1 and eu-west-1
- Deploy monitoring and logging infrastructure in all regions
- Configure Route 53 for latency-based routing

### Phase 2: Application Deployment (Week 3-4)
- Deploy identical application stacks in us-east-1 and eu-west-1
- Configure regional DynamoDB endpoints
- Implement health checks and failover testing
- Set up region-aware monitoring dashboards

### Phase 3: Data Migration and Testing (Week 5-6)
- Migrate existing data to DynamoDB Global Tables
- Test cross-region replication and conflict resolution
- Validate failover scenarios and recovery procedures
- Performance test from all regions

### Phase 4: Progressive Rollout (Week 7-8)
- Enable latency-based routing for EU traffic first
- Monitor performance and error rates
- Gradually enable US East routing
- Full multi-region operations

### Monitoring and Alerting

**Key Metrics:**
- DynamoDB replication lag between regions
- Cross-region API response times
- Regional error rates and availability
- DynamoDB consumed capacity per region
- Application deployment health across regions

**Alerting Thresholds:**
- Replication lag > 1 second
- Regional response time > 200ms  
- Error rate > 1% in any region
- Health check failures > 5% of requests

**Dashboards:**
- Global overview with all regions
- Per-region detailed metrics
- DynamoDB Global Tables replication status
- Cost tracking per region

### Data Residency and Compliance

**GDPR Compliance (EU Region):**
- EU customer data processed only in eu-west-1
- Right to erasure implemented across all regions
- Data transfer logs maintained for audit
- Regional data isolation for sensitive operations

**Audit Trail Strategy:**
- DynamoDB Streams in all regions feed centralized audit system
- Cross-region correlation IDs for tracing operations
- Regulatory reporting aggregates data from all regions
- Region-specific compliance controls where required

This multi-region strategy enables TRM's global compliance operations while maintaining data consistency, regulatory compliance, and operational excellence across all regions.