# ADR-014: Database Technology Selection for TRM Block Explorer

## Status

Accepted

## Context

The TRM Block Explorer requires a database solution that supports global compliance operations across multiple regions. TRM's core mission involves anti-money laundering (AML) compliance, which requires real-time access to watchlist data, suspicious transaction records, and investigation notes from any global office.

**Business Requirements:**
- **Global Accessibility**: Analysts in NYC, London, Singapore must have instant access to the same compliance data
- **Business Continuity**: If one region fails, other regions must continue operations with full data access
- **Compliance Auditing**: All changes must be tracked for regulatory requirements
- **Real-time Operations**: New suspicious addresses must be visible globally within seconds
- **Scale Requirements**: Handle 100K+ watchlisted addresses, millions of transaction records

**Technical Requirements:**
- Multi-region active-active replication
- Low latency reads/writes (< 100ms)
- Strong consistency for critical operations
- Automatic failover capabilities
- Comprehensive audit trails
- Integration with existing AWS infrastructure

**Current Architecture:**
- Template uses PostgreSQL with SQLAlchemy ORM
- Single-region deployment model
- ACID transactions for data consistency
- Relational data modeling approach

## Decision

Replace PostgreSQL with **Amazon DynamoDB Global Tables** for all compliance-related data storage (watchlists, suspicious transactions, investigation notes).

Retain PostgreSQL for non-compliance data that doesn't require multi-region replication (user management, application configuration).

## Alternatives Considered

### 1. PostgreSQL with Read Replicas
- **Pros**: Maintains existing ORM patterns, ACID guarantees, familiar SQL interface
- **Cons**: Read replicas don't support active-active writes, complex failover, replication lag issues
- **Verdict**: Insufficient for real-time global compliance operations

### 2. PostgreSQL with Multi-Master Replication (BDR/Citus)
- **Pros**: True multi-master capabilities, SQL interface, ACID transactions
- **Cons**: Complex setup, conflict resolution challenges, limited AWS managed service support
- **Verdict**: High operational overhead, not AWS-native

### 3. Amazon RDS Global Database
- **Pros**: Managed PostgreSQL, cross-region replication, AWS-native
- **Cons**: Primary-replica model (not active-active), failover complexity, cost at scale
- **Verdict**: Doesn't meet active-active requirement

### 4. Amazon Aurora Global Database
- **Pros**: Fast replication (< 1 second), managed service, SQL interface
- **Cons**: Primary-replica model, complex failover for writes, higher cost
- **Verdict**: Still not true active-active for compliance writes

### 5. DynamoDB Global Tables (Chosen)
- **Pros**: True active-active multi-region, < 1 second replication, managed service, scales automatically
- **Cons**: NoSQL learning curve, eventual consistency model, limited querying patterns
- **Verdict**: Best fit for global compliance requirements

### 6. Hybrid Approach: DynamoDB + PostgreSQL
- **Pros**: DynamoDB for compliance data, PostgreSQL for relational needs
- **Cons**: Multiple database technologies, increased complexity
- **Verdict**: Acceptable trade-off for business requirements

## Consequences

### Positive
- **Global Active-Active**: Analysts can write to watchlists from any region instantly
- **Automatic Scaling**: DynamoDB handles traffic spikes during compliance investigations
- **Managed Service**: AWS handles infrastructure, patching, backups, monitoring
- **Cost Efficiency**: Pay-per-request model scales with actual usage
- **Audit Trails**: DynamoDB Streams provide comprehensive change logs
- **Business Continuity**: Automatic failover across regions without data loss

### Negative
- **Learning Curve**: Team must learn NoSQL patterns and DynamoDB-specific concepts
- **Query Limitations**: No SQL joins, limited filtering requires careful data modeling
- **Eventual Consistency**: Must handle scenarios where Global Tables haven't synchronized
- **Migration Complexity**: Existing PostgreSQL patterns need redesign for NoSQL
- **Dual Database Management**: Operating both DynamoDB and PostgreSQL increases complexity

### Neutral
- **Data Modeling**: Shift from normalized relational to denormalized NoSQL patterns
- **Repository Pattern**: Maintain clean architecture boundaries regardless of underlying storage
- **Cost Model**: Fixed PostgreSQL costs become variable DynamoDB costs
- **Monitoring**: Different monitoring strategies for NoSQL vs SQL databases

## Implementation Strategy

### Phase 1: DynamoDB Infrastructure
- Set up DynamoDB Global Tables in primary regions (us-west-2, us-east-1)
- Implement DynamoDB repository pattern following existing DDD architecture
- Create table schemas for watchlists, suspicious transactions, investigation notes
- Establish monitoring and alerting for DynamoDB operations

### Phase 2: Data Migration
- Migrate watchlist data from any existing PostgreSQL tables to DynamoDB
- Implement dual-write pattern during transition period
- Validate data consistency between old and new systems
- Cutover API endpoints to use DynamoDB repositories

### Phase 3: PostgreSQL Rationalization
- Identify remaining PostgreSQL use cases (user management, application config)
- Simplify PostgreSQL schema by removing compliance-related tables
- Optimize PostgreSQL for remaining single-region operations

### Table Design Strategy

```python
# DynamoDB Table Schemas (Primary Keys and GSIs)

# Address Watchlist Table
PK: address (Ethereum address)
SK: "METADATA" 
GSI1: risk_level + created_at (query by risk level)
GSI2: added_by + created_at (query by analyst)

# Suspicious Transactions Table  
PK: address (Ethereum address)
SK: "TX#" + transaction_hash
GSI1: flagged_by + created_at (query by analyst)
GSI2: transaction_type + amount_eth (query by type/amount)

# Investigation Notes Table
PK: address (Ethereum address) 
SK: "NOTE#" + timestamp + note_id
GSI1: analyst_id + created_at (query by analyst)
GSI2: priority + created_at (query high priority notes)
```

### Repository Pattern Preservation
```python
# Domain repository interfaces remain unchanged
class WatchlistRepository(ABC):
    @abstractmethod
    async def save(self, watchlisted_address: WatchlistedAddress) -> None: ...
    
    @abstractmethod
    async def get_by_address(self, address: EthereumAddress) -> Optional[WatchlistedAddress]: ...

# Infrastructure implementation changes to DynamoDB
class DynamoDbWatchlistRepository(WatchlistRepository):
    # Implementation uses boto3/aioboto3 instead of SQLAlchemy
```

### Consistency Handling
- **Strong Consistency**: Use DynamoDB consistent reads for critical lookups
- **Eventual Consistency**: Handle cases where Global Tables are replicating
- **Conflict Resolution**: DynamoDB uses last-writer-wins with timestamp resolution
- **Version Control**: Implement optimistic locking for concurrent updates

### Migration Timeline
- **Week 1-2**: DynamoDB infrastructure setup and Global Tables configuration
- **Week 3-4**: Repository implementation and unit testing
- **Week 5-6**: Integration testing and dual-write implementation  
- **Week 7-8**: Data migration and validation
- **Week 9-10**: API cutover and PostgreSQL cleanup

This database technology selection enables TRM's global compliance operations while maintaining clean architecture principles and providing the scalability needed for anti-money laundering operations at scale.