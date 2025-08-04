# ADR-018: ECS Container Architecture for TRM Block Explorer

## Status

Accepted (Supersedes ADR-017)

## Context

After implementing the Lambda-based serverless architecture outlined in ADR-017, we encountered several operational challenges that necessitate a shift to container-based architecture:

**Challenges with Lambda Architecture:**
- **Deployment Complexity**: Lambda deployment package size constraints (50MB unzipped) require complex dependency management
- **Cold Start Impact**: P95 latency spikes of 500-1000ms affect compliance analyst user experience
- **Debugging Difficulty**: Distributed Lambda debugging requires specialized tooling and increases MTTR
- **Local Development Parity**: Significant differences between local FastAPI development and Lambda runtime
- **Connection Pooling**: Stateless Lambda prevents efficient database connection pooling for DynamoDB

**New Requirements:**
- **Predictable Performance**: Compliance workflows require consistent sub-200ms response times
- **Enhanced Observability**: Deep application profiling and debugging capabilities
- **Development Velocity**: Faster iteration cycles with better local-to-production parity
- **Cost Predictability**: Fixed baseline costs preferred over variable serverless pricing
- **Container Ecosystem**: Leverage existing container tooling and practices

## Decision

Migrate from AWS Lambda to **Amazon ECS with Fargate** for container orchestration while maintaining the multi-region active-active architecture:

### Core Architecture Components

1. **Container Orchestration**: Amazon ECS with Fargate launch type
2. **Container Registry**: Amazon ECR for production images, GitHub Container Registry for CI/CD
3. **Service Mesh**: AWS App Mesh for traffic management and observability
4. **Load Balancing**: Application Load Balancer (ALB) with path-based routing
5. **API Gateway Integration**: Retain API Gateway as edge service routing to ECS
6. **Auto Scaling**: ECS Service Auto Scaling based on CPU/memory metrics

### Container Strategy

**Production Service Container:**
- Base image: `python:3.11-slim`
- Multi-stage build with dependency caching
- No development tools or debugging utilities
- Optimized for size (~150MB) and security
- Non-root user execution

**CI/CD Workflow Containers:**
- Specialized containers matching Devbox tool versions
- Separate containers for different workflow stages
- GitHub Actions native tools preferred where available

## Architecture Details

### ECS Cluster Configuration

**Account Bootstrap Level:**
```hcl
# One cluster per environment per region
Clusters:
  - trm-dev-us-west-2    # Development cluster in primary region
  - trm-dev-us-east-2    # Development cluster in secondary region
  - trm-prod-us-west-2   # Production cluster in primary region
  - trm-prod-us-east-2   # Production cluster in secondary region
```

### Container Build Strategy

**Multi-Stage Dockerfile Architecture:**
```dockerfile
# Base dependencies layer (cached)
FROM python:3.11-slim AS dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Application layer
FROM dependencies AS application
COPY src/ ./src/
RUN python -m compileall src/

# Production image
FROM python:3.11-slim AS production
WORKDIR /app
COPY --from=dependencies /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=application /app/src ./src
USER 1000:1000
EXPOSE 8000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Service Deployment Architecture

**ECS Service Configuration:**
```yaml
Service:
  DesiredCount: 2  # Minimum for high availability
  DeploymentConfiguration:
    MaximumPercent: 200
    MinimumHealthyPercent: 100
  HealthCheckGracePeriod: 60 seconds
  
TaskDefinition:
  CPU: 512      # 0.5 vCPU
  Memory: 1024  # 1 GB
  NetworkMode: awsvpc
  
Container:
  Port: 8000
  HealthCheck:
    Command: ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
    Interval: 30 seconds
    Timeout: 5 seconds
    Retries: 3
```

### Networking Architecture

**Security Model:**
```yaml
API Gateway -> ALB (public subnet) -> ECS Service (private subnet) -> DynamoDB/MemoryDB

Security Groups:
  ALB:
    - Ingress: HTTPS (443) from API Gateway
    - Egress: HTTP (8000) to ECS service
  
  ECS Service:
    - Ingress: HTTP (8000) from ALB only
    - Egress: HTTPS (443) to AWS services
```

**Service Discovery:**
- AWS Cloud Map for internal service discovery
- Service namespace: `{environment}.internal`
- Service naming: `{service-name}.{environment}.internal`

### Auto Scaling Strategy

**Target Tracking Policies:**
```yaml
CPU Utilization:
  Target: 70%
  ScaleOutCooldown: 60 seconds
  ScaleInCooldown: 300 seconds

Memory Utilization:  
  Target: 80%
  ScaleOutCooldown: 60 seconds
  ScaleInCooldown: 300 seconds

Request Count (via ALB):
  Target: 1000 requests/minute/task
  ScaleOutCooldown: 30 seconds
  ScaleInCooldown: 300 seconds
```

### CI/CD Pipeline Updates

**Container Build Pipeline:**
```yaml
Build Stage:
  - Build base dependencies layer (cached)
  - Build application layer
  - Run security scanning (Trivy/Snyk)
  - Push to ECR with semantic versioning

Deploy Stage:
  - Update ECS task definition
  - Perform blue-green deployment via ECS
  - Validate health checks
  - Update Route53 weighted routing
```

**GitHub Actions Optimization:**
- Use native actions where available (terraform, aws-cli)
- Custom containers only for Python/UV operations
- Leverage GitHub's container cache
- BuildKit with cache mounts for faster builds

## Migration Strategy

### Phase 1: ECS Infrastructure (Week 1)
- Update Terraform modules for ECS clusters
- Deploy ECS clusters in all regions/environments
- Configure ALB and target groups
- Set up ECR repositories

### Phase 2: Container Development (Week 2)
- Create optimized Dockerfiles
- Build CI/CD container images
- Update GitHub Actions workflows
- Implement container security scanning

### Phase 3: Service Deployment (Week 3)
- Deploy ECS services to development
- Configure service auto-scaling
- Integrate with existing API Gateway
- Validate end-to-end connectivity

### Phase 4: Production Migration (Week 4)
- Blue-green deployment to production
- Monitor performance metrics
- Gradual traffic shift via Route53
- Decommission Lambda functions

## Consequences

### Positive

**Performance Improvements:**
- Eliminated cold start latency (0ms vs 500-1000ms)
- Consistent response times through connection pooling
- Better resource utilization with long-running containers
- Predictable scaling behavior

**Operational Benefits:**
- Simplified debugging with container exec access
- Better local development parity
- Unified deployment model across environments
- Enhanced observability with App Mesh

**Cost Benefits:**
- Predictable baseline costs with Fargate pricing
- Efficient resource utilization with auto-scaling
- Reduced AWS service overhead (fewer Lambda invocations)
- Better cost allocation with container-level metrics

### Negative

**Operational Overhead:**
- Container image management and versioning
- More complex deployment rollbacks
- Additional security scanning requirements
- ECS service management complexity

**Infrastructure Costs:**
- Higher baseline costs (minimum 2 tasks per service)
- ALB costs per region ($16/month minimum)
- NAT Gateway costs for private subnet egress
- Container registry storage costs

### Neutral

**Architectural Changes:**
- Shift from event-driven to request-driven model
- Different scaling characteristics
- New monitoring and alerting patterns
- Container-specific security considerations

## Security Considerations

**Container Security:**
- Non-root user execution
- Read-only root filesystem where possible
- No shell or debugging tools in production
- Regular base image updates
- Vulnerability scanning in CI/CD

**Network Security:**
- Private subnet deployment
- Security group isolation
- AWS PrivateLink for AWS service access
- TLS termination at ALB
- API Gateway for DDoS protection

## Monitoring and Observability

**Key Metrics:**
- Container CPU/Memory utilization
- Task health and count
- ALB response times and error rates
- ECS service events
- Container restart frequency

**Logging Strategy:**
- CloudWatch Logs with FireLens
- Structured JSON logging
- Correlation IDs for request tracing
- Log aggregation to S3 for analysis

This architecture provides predictable performance, enhanced operability, and maintains the global scale required for TRM's compliance operations while addressing the limitations discovered in the serverless implementation.