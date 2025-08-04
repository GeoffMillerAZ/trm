# ADR-017: AWS Serverless Infrastructure Architecture for TRM Block Explorer

## Status

Accepted

## Context

The TRM Block Explorer requires a robust, scalable, and cost-effective infrastructure architecture to support global compliance operations. The application must serve anti-money laundering (AML) analysts across multiple regions while maintaining high availability, low latency, and comprehensive audit capabilities.

**Business Requirements:**
- **Global Operations**: Support analysts in NYC, London, Singapore with consistent performance
- **24/7 Availability**: Compliance monitoring cannot tolerate extended downtime
- **Regulatory Compliance**: Audit trails, data sovereignty, and business continuity requirements
- **Cost Efficiency**: Optimize infrastructure costs while maintaining performance and reliability
- **Scalability**: Handle variable workloads from compliance investigations and blockchain data processing

**Technical Requirements:**
- Multi-region active-active deployment for business continuity
- Low-latency API responses (< 200ms) for compliance workflows
- Automatic scaling for variable compliance investigation workloads
- Comprehensive observability and monitoring across all regions
- Infrastructure as Code for consistent deployments and change management
- Secure handling of sensitive compliance data

**Current Architecture Context:**
- Domain-Driven Design (DDD) Python application using FastAPI
- Clean architecture with separated domain, application, infrastructure, and presentation layers
- Multi-region data strategy using DynamoDB Global Tables (ADR-016)
- Environment separation between development and production workloads

## Decision

Implement **AWS Serverless Architecture** with multi-region active-active deployment using:

1. **Compute Layer**: AWS Lambda with FastAPI application
2. **API Gateway**: Amazon API Gateway for request routing and management
3. **Database**: DynamoDB Global Tables for compliance data (established in ADR-014/016)
4. **Caching**: Amazon MemoryDB for Redis for performance optimization
5. **DNS and Load Balancing**: Route 53 with latency-based routing
6. **Infrastructure**: Terraform with modular structure for multi-region deployment
7. **Environment Strategy**: Separate dev/prod environments with region-specific deployments

**Regional Architecture:**
- **Primary Region**: us-west-2 (US West - Oregon)
- **Secondary Region**: us-east-2 (US East - Ohio)
- **Future Expansion**: eu-west-1 (Europe - Ireland) for GDPR compliance

## Alternatives Considered

### 1. Container-Based Architecture (ECS/EKS)
- **Pros**: More control over runtime environment, easier local development parity, traditional deployment model
- **Cons**: Higher operational overhead, constant compute costs, more complex scaling, container management complexity
- **Verdict**: Over-engineered for API workloads with variable traffic patterns

### 2. EC2-Based Auto Scaling Groups
- **Pros**: Full control over instances, predictable costs for sustained workloads, familiar deployment model
- **Cons**: Higher management overhead, slower cold start scaling, higher minimum costs, patching responsibilities
- **Verdict**: Insufficient cost efficiency for variable compliance workloads

### 3. AWS App Runner
- **Pros**: Simple container deployment, automatic scaling, minimal configuration
- **Cons**: Limited multi-region capabilities, less control over infrastructure, newer service with fewer features
- **Verdict**: Insufficient for complex multi-region compliance requirements

### 4. Hybrid Architecture (Lambda + ECS)
- **Pros**: Lambda for variable workloads, ECS for sustained processes, flexible resource allocation
- **Cons**: Increased complexity, multiple deployment pipelines, operational overhead of managing both
- **Verdict**: Unnecessary complexity for current requirements

### 5. AWS Serverless (Chosen)
- **Pros**: Automatic scaling, pay-per-use pricing, minimal operational overhead, excellent multi-region support
- **Cons**: Cold start latency, function timeout limits, vendor lock-in
- **Verdict**: Best fit for variable compliance workloads with global requirements

## Architecture Components

### Compute and API Layer

**AWS Lambda Configuration:**
- **Runtime**: Python 3.11 with FastAPI application
- **Memory**: 1024MB (optimized for DDD application with dependency injection)
- **Timeout**: 29 seconds (API Gateway maximum)
- **Concurrency**: Reserved concurrency per region to prevent resource exhaustion
- **Environment Variables**: Region-specific DynamoDB endpoints, cache clusters, API keys

**Amazon API Gateway:**
- **Type**: REST API (vs HTTP API for advanced features)
- **Caching**: Enabled for blockchain data queries (TTL: 5 minutes)
- **Throttling**: 1000 requests/second per region with burst capacity
- **Authentication**: API key authentication with usage plans
- **CORS**: Configured for web application integration
- **Logging**: CloudWatch integration for request/response logging

### Data Layer

**DynamoDB Global Tables (Established in ADR-014/016):**
- Tables: AddressWatchlist, SuspiciousTransactions, InvestigationNotes
- Replication: Active-active across us-west-2 and us-east-2
- Billing: Pay-per-request for variable compliance workloads
- Backup: Point-in-time recovery enabled in all regions

**Amazon MemoryDB for Redis:**
- **Purpose**: Cache blockchain API responses, session data, computed results
- **Configuration**: Cluster mode with 2 shards per region
- **Memory**: 1GB per shard (2GB total per region)
- **Availability**: Multi-AZ deployment within each region
- **Backup**: Daily snapshots with 7-day retention

### Network and Routing

**Route 53 Configuration:**
```yaml
DNS:
  api.trm-blockexplorer.com:
    Type: Latency-based routing
    Health Checks: Enabled
    Records:
      - Region: us-west-2
        Target: API Gateway regional endpoint
        Latency Threshold: 100ms
      - Region: us-east-2  
        Target: API Gateway regional endpoint
        Latency Threshold: 100ms
```

**Regional Failover Strategy:**
- Health checks monitor API Gateway endpoints every 30 seconds
- Automatic failover when regional health check fails
- 60-second TTL for DNS records to enable rapid failover
- Cross-region replication ensures data consistency during failover

### Infrastructure as Code

**Terraform Structure:**
```
iac/terraform/
├── modules/                    # Reusable Terraform modules
│   ├── lambda/                # Lambda function module
│   ├── api-gateway/          # API Gateway configuration
│   ├── dynamodb/             # DynamoDB table management
│   ├── memorydb/             # MemoryDB cluster setup
│   ├── route53/              # DNS and health checks
│   └── iam/                  # IAM roles and policies
├── projects/                  # Project-specific configurations
│   └── trm-blockexplorer/    # TRM Block Explorer project
│       ├── global/           # Global resources (Route53, IAM)
│       ├── us-west-2/        # Primary region deployment
│       └── us-east-2/        # Secondary region deployment
└── deploy/                   # Deployment configurations
    ├── backend-config/       # Terraform backend configurations
    ├── dev.tfvars           # Development environment variables
    └── prod.tfvars          # Production environment variables
```

**Module Design Principles:**
- **Reusability**: Modules support multiple environments and regions
- **Composition**: Complex infrastructure built from simple, focused modules
- **Parameterization**: Environment-specific values externalized to tfvars files
- **Validation**: Input validation and type constraints for safety
- **Documentation**: Comprehensive module documentation and examples

### Environment and Region Strategy

**Environment Separation:**
- **Development**: Single region (us-west-2) for cost optimization
- **Production**: Multi-region (us-west-2 + us-east-2) for business continuity
- **Resource Naming**: `trm-blockexplorer-{env}-{region}-{resource}`
- **Tagging Strategy**: Environment, Project, Region, CostCenter tags on all resources

**Global vs Regional Resources:**
```yaml
Global Resources (us-west-2 only):
  - Route 53 hosted zone and DNS records
  - IAM roles and policies  
  - KMS keys for cross-region encryption
  - CloudWatch dashboards for global monitoring

Regional Resources (both us-west-2 and us-east-2):
  - Lambda functions and layers
  - API Gateway regional endpoints
  - DynamoDB tables (with Global Tables replication)
  - MemoryDB clusters
  - VPC and networking components
  - Regional CloudWatch alarms
```

### Security Architecture

**IAM Strategy:**
- **Principle of Least Privilege**: Each Lambda function has minimal required permissions
- **Cross-Account Access**: Separate roles for different environments
- **Resource-Based Policies**: DynamoDB and MemoryDB access controlled at resource level
- **Temporary Credentials**: Lambda execution roles use temporary credentials

**Network Security:**
- **VPC Isolation**: Lambda functions deployed in private subnets
- **Security Groups**: Restrictive ingress/egress rules for MemoryDB access
- **API Gateway**: Rate limiting and API key requirements
- **Encryption**: All data encrypted in transit and at rest

**Compliance and Audit:**
- **AWS CloudTrail**: API call logging across all regions
- **VPC Flow Logs**: Network traffic monitoring
- **DynamoDB Streams**: Data change audit trails
- **CloudWatch Logs**: Application logging with structured JSON

## Consequences

### Positive

**Operational Benefits:**
- **Reduced Management Overhead**: AWS manages server provisioning, patching, and scaling automatically
- **Cost Optimization**: Pay-per-use model significantly reduces costs during low-traffic periods
- **Automatic Scaling**: Handles traffic spikes during compliance investigations without intervention
- **Multi-Region Resilience**: Automatic failover ensures business continuity during regional outages
- **Fast Deployment**: Serverless deployments complete in minutes vs. hours for traditional infrastructure

**Performance Benefits:**
- **Low Latency**: Regional deployments ensure < 50ms database response times globally
- **Caching Layer**: MemoryDB reduces blockchain API calls and improves response times
- **Global Availability**: 99.99% uptime target achievable with multi-region active-active setup
- **Elastic Capacity**: Automatic scaling handles variable compliance workloads efficiently

**Development Benefits:**
- **Infrastructure as Code**: Terraform modules enable consistent, repeatable deployments
- **Environment Parity**: Identical infrastructure across dev/prod environments
- **Rapid Iteration**: Serverless deployment enables faster development cycles
- **Observability**: Comprehensive monitoring and logging built into AWS services

### Negative

**Operational Challenges:**
- **Vendor Lock-in**: Deep integration with AWS services makes migration complex and costly
- **Cold Start Latency**: Initial Lambda invocations may experience 100-500ms cold start delays
- **Debugging Complexity**: Distributed serverless debugging requires specialized tools and practices
- **Timeout Limitations**: 29-second API Gateway timeout may constrain complex blockchain operations

**Cost Implications:**
- **Variable Costs**: Difficult to predict monthly costs due to usage-based pricing model
- **Multi-Region Overhead**: Running identical infrastructure in multiple regions increases baseline costs
- **Data Transfer Costs**: Cross-region DynamoDB replication and failover incur data transfer charges
- **Monitoring Costs**: Comprehensive CloudWatch logging and metrics can become expensive at scale

**Technical Constraints:**
- **Function Size Limits**: Lambda deployment packages limited to 50MB (unzipped), 250MB (zipped)
- **Memory Constraints**: Maximum 10GB memory per Lambda function may limit resource-intensive operations
- **Eventual Consistency**: DynamoDB Global Tables provide eventual consistency, not strong consistency
- **Connection Pooling**: Lambda's stateless nature prevents traditional database connection pooling

### Neutral

**Architectural Trade-offs:**
- **Stateless Design**: Forces good architectural practices but requires careful session management
- **Microservices Alignment**: Serverless naturally encourages microservices patterns
- **Observability Requirements**: Distributed tracing becomes essential for troubleshooting
- **Testing Complexity**: Integration testing requires sophisticated mocking or cloud resources

## Implementation Strategy

### Phase 1: Foundation Infrastructure (Weeks 1-2)
- Set up Terraform modules for core AWS services
- Deploy CloudFormation stack for Terraform prerequisites (S3, DynamoDB, IAM)
- Configure Terraform backend with state locking and encryption
- Implement base networking (VPC, subnets, security groups) in primary region

### Phase 2: Core Services Deployment (Weeks 3-4)
- Deploy Lambda functions with FastAPI application in us-west-2
- Configure API Gateway with proper throttling and caching
- Set up DynamoDB tables and MemoryDB cluster in primary region
- Implement comprehensive monitoring and alerting

### Phase 3: Multi-Region Expansion (Weeks 5-6)
- Replicate infrastructure in us-east-2 secondary region
- Enable DynamoDB Global Tables replication
- Configure Route 53 with latency-based routing and health checks
- Test cross-region failover scenarios

### Phase 4: Production Hardening (Weeks 7-8)
- Implement comprehensive security policies and IAM roles
- Set up production monitoring dashboards and alerts
- Conduct performance testing and load testing
- Document operational procedures and troubleshooting guides

### Phase 5: Environment Automation (Weeks 9-10)
- Create CI/CD pipeline for infrastructure deployments
- Implement automated testing for Terraform configurations  
- Set up development environment with simplified single-region deployment
- Create disaster recovery procedures and runbooks

## Monitoring and Observability

### Key Performance Indicators (KPIs)
- **API Response Time**: P95 < 200ms, P99 < 500ms
- **Availability**: 99.99% uptime across all regions
- **Error Rate**: < 0.1% for all API endpoints
- **Cold Start Impact**: < 5% of requests experience cold starts
- **DynamoDB Performance**: Single-digit millisecond response times

### Alerting Strategy
```yaml
Critical Alerts (PagerDuty):
  - API Gateway 5XX errors > 1%
  - Lambda function errors > 0.5%
  - DynamoDB throttling events
  - Regional health check failures
  - MemoryDB cluster failures

Warning Alerts (Slack):
  - API response time P95 > 300ms
  - Lambda cold start rate > 10%
  - DynamoDB consumed capacity > 80%
  - Unusual traffic patterns
```

### Dashboard Structure
- **Executive Dashboard**: High-level business metrics and regional status
- **Operational Dashboard**: Technical metrics for on-call engineers
- **Regional Dashboards**: Region-specific performance and health metrics
- **Cost Dashboard**: Real-time cost tracking and optimization opportunities

## Cost Optimization Strategy

### Cost Monitoring
- **AWS Cost Explorer**: Track costs by service, region, and environment
- **Budget Alerts**: Automated alerts when costs exceed thresholds
- **Reserved Capacity**: Evaluate DynamoDB reserved capacity for predictable workloads
- **Right-sizing**: Regular review of Lambda memory allocation and timeout settings

### Optimization Techniques
- **Lambda Provisioned Concurrency**: For endpoints requiring consistent low latency
- **API Gateway Caching**: Reduce Lambda invocations for cacheable responses
- **DynamoDB On-Demand**: Cost-effective for variable compliance workloads
- **Log Retention**: Aggressive log retention policies to control CloudWatch costs

This serverless infrastructure architecture provides TRM with a scalable, resilient, and cost-effective foundation for global compliance operations while maintaining the flexibility to adapt to evolving business requirements and regulatory changes.