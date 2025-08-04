# ECS Container Infrastructure Implementation Specification

## Overview

This specification details the implementation of Amazon ECS (Elastic Container Service) infrastructure for the TRM Block Explorer application, supporting multi-region deployment with containerized services, predictable performance, and automatic scaling.

## Goals

1. Deploy FastAPI application as containerized services on ECS Fargate
2. Enable multi-region active-active deployment (us-west-2, us-east-2)
3. Implement automatic scaling based on CPU, memory, and request metrics
4. Ensure consistent sub-200ms response times without cold starts
5. Provide comprehensive monitoring and observability via App Mesh
6. Support blue-green deployments through ECS deployment strategies

## Architecture Components

### ECS Task Definitions

```hcl
# ECS task definition configuration
task_definitions = {
  api = {
    family      = "trm-blockexplorer-api"
    cpu         = "512"    # 0.5 vCPU
    memory      = "1024"   # 1 GB
    
    container_definitions = [{
      name  = "api"
      image = "${var.ecr_repository_url}:${var.image_tag}"
      
      portMappings = [{
        containerPort = 8000
        protocol      = "tcp"
      }]
      
      environment = [
        { name = "ENVIRONMENT", value = var.environment },
        { name = "REGION", value = var.region },
        { name = "PORT", value = "8000" }
      ]
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }]
  }
}
```

### ECS Services

```hcl
# ECS service configuration
services = {
  api = {
    desired_count = 2  # Minimum for HA
    
    deployment_configuration = {
      maximum_percent         = 200
      minimum_healthy_percent = 100
    }
    
    network_configuration = {
      subnets          = var.private_subnet_ids
      security_groups  = [aws_security_group.ecs_service.id]
      assign_public_ip = false
    }
    
    load_balancer = {
      target_group_arn = aws_lb_target_group.api.arn
      container_name   = "api"
      container_port   = 8000
    }
    
    health_check_grace_period_seconds = 60
  }
}
```

### Application Load Balancer Integration

```hcl
# Application Load Balancer
resource "aws_lb" "api" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = true  # Internal-only, accessed via API Gateway
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  
  enable_deletion_protection = var.environment == "production"
  enable_http2              = true
}

# Target group for ECS service
resource "aws_lb_target_group" "api" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  target_type = "ip"  # Required for Fargate
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }
}

# API Gateway VPC Link to ALB
resource "aws_api_gateway_vpc_link" "main" {
  name        = "${var.project_name}-${var.environment}-vpclink"
  target_arns = [aws_lb.api.arn]
}
```

## Container Image

### Dockerfile

```dockerfile
# Multi-stage Dockerfile for production
FROM python:3.11-slim AS base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Dependencies layer
FROM base AS dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Application layer
FROM base AS application
WORKDIR /app
COPY --from=dependencies /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY src/ ./src/

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Production configuration
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
```

### Build Process

```yaml
# .github/workflows/build.yml
build:
  runs-on: ubuntu-latest
  steps:
    - name: Build and push to ECR
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: |
          ${{ steps.login-ecr.outputs.registry }}/trm-blockexplorer:${{ github.sha }}
          ${{ steps.login-ecr.outputs.registry }}/trm-blockexplorer:latest
        cache-from: type=gha
        cache-to: type=gha,mode=max
        platforms: linux/amd64
```

## Auto Scaling Configuration

### ECS Service Auto Scaling

```hcl
# ECS service auto scaling
resource "aws_appautoscaling_target" "ecs_service" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based scaling
resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.project_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    
    scale_out_cooldown = 60
    scale_in_cooldown  = 300
  }
}

# Memory-based scaling
resource "aws_appautoscaling_policy" "ecs_memory" {
  name               = "${var.project_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 80.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    
    scale_out_cooldown = 60
    scale_in_cooldown  = 300
  }
}

# Request count scaling via ALB metrics
resource "aws_appautoscaling_policy" "ecs_requests" {
  name               = "${var.project_name}-request-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 1000.0  # 1000 requests per minute per task

    customized_metric_specification {
      metric_name = "RequestCountPerTarget"
      namespace   = "AWS/ApplicationELB"
      statistic   = "Sum"
      unit        = "Count"

      dimensions {
        name  = "TargetGroup"
        value = aws_lb_target_group.api.arn_suffix
      }
    }
    
    scale_out_cooldown = 30
    scale_in_cooldown  = 300
  }
}
```

## Monitoring and Observability

### CloudWatch Alarms

```hcl
# ECS service health alarm
resource "aws_cloudwatch_metric_alarm" "ecs_service_health" {
  alarm_name          = "${var.project_name}-ecs-service-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "ECS service has unhealthy tasks"

  dimensions = {
    TargetGroup  = aws_lb_target_group.api.arn_suffix
    LoadBalancer = aws_lb.api.arn_suffix
  }
}

# Container CPU utilization alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "ECS service CPU utilization is high"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.api.name
  }
}

# ALB response time alarm
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  alarm_name          = "${var.project_name}-alb-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0.2"  # 200ms
  alarm_description   = "ALB response time exceeds 200ms"

  dimensions = {
    LoadBalancer = aws_lb.api.arn_suffix
  }
}
```

### AWS App Mesh Integration

```hcl
# App Mesh configuration for enhanced observability
resource "aws_appmesh_mesh" "main" {
  name = "${var.project_name}-${var.environment}"

  spec {
    egress_filter {
      type = "ALLOW_ALL"
    }
  }
}

resource "aws_appmesh_virtual_node" "api" {
  name      = "api-vn"
  mesh_name = aws_appmesh_mesh.main.name

  spec {
    listener {
      port_mapping {
        port     = 8000
        protocol = "http"
      }
    }

    service_discovery {
      aws_cloud_map {
        namespace_name = aws_service_discovery_private_dns_namespace.main.name
        service_name   = "api"
      }
    }
    
    logging {
      access_log {
        file {
          path = "/dev/stdout"
        }
      }
    }
  }
}
```

## Security Configuration

### IAM Roles and Policies

```hcl
# ECS task execution role (managed by ECS module)
resource "aws_iam_role_policy" "ecs_task_execution_ecr" {
  name = "${var.project_name}-ecs-ecr-access"
  role = module.ecs.task_execution_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
      Resource = "*"
    }]
  })
}

# ECS task role for application permissions
resource "aws_iam_role_policy" "ecs_task_app" {
  name = "${var.project_name}-ecs-app-permissions"
  role = module.ecs.task_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeCacheNodes"
        ]
        Resource = "*"
      }
    ]
  })
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-ecs-service"
  description = "Security group for ECS service tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-service"
  })
}
```

## Deployment Strategy

### Blue-Green Deployment with ECS

```hcl
# ECS deployment configuration
resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_configuration {
    deployment_circuit_breaker {
      enable   = true
      rollback = true
    }

    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.api.arn
  }

  depends_on = [aws_lb_listener.api]
}

# CodeDeploy for blue-green deployments (optional)
resource "aws_codedeploy_deployment_group" "ecs" {
  app_name               = aws_codedeploy_app.ecs.name
  deployment_group_name  = "${var.project_name}-ecs"
  service_role_arn       = aws_iam_role.codedeploy.arn

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                                          = "TERMINATE"
      termination_wait_time_in_minutes               = 5
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.api.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.api.arn]
      }

      target_group {
        name = aws_lb_target_group.api.name
      }

      target_group {
        name = aws_lb_target_group.api_canary.name
      }
    }
  }
}
```

## Testing Strategy

### Container Integration Tests

```python
# tests/integration/test_container.py
import pytest
import httpx
import docker

@pytest.fixture(scope="session")
def container():
    client = docker.from_env()
    container = client.containers.run(
        "trm-blockexplorer:test",
        detach=True,
        ports={"8000/tcp": 8000},
        environment={
            "ENVIRONMENT": "test",
            "DYNAMODB_ENDPOINT": "http://dynamodb-local:8000"
        },
        network="test-network"
    )
    yield container
    container.stop()
    container.remove()

def test_health_endpoint(container):
    response = httpx.get("http://localhost:8000/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
```

### Load Testing with K6

```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 },  // Ramp up
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '2m', target: 200 },  // Ramp up more
    { duration: '5m', target: 200 },  // Stay at 200 users
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],  // 95% of requests must complete below 200ms
    http_req_failed: ['rate<0.01'],    // Error rate must be below 1%
  },
};

export default function() {
  let response = http.get('https://api.trm-blockexplorer.com/api/v1/health');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });
  sleep(1);
}
```

## Cost Optimization

### Fargate Spot Usage

```hcl
# Use Fargate Spot for non-critical workloads
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 2
    base              = 0
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 2  # Always run at least 2 tasks on regular Fargate
  }
}

# Right-size containers based on metrics
variable "container_insights_metrics" {
  description = "Container resource utilization for right-sizing"
  default = {
    cpu_p95_utilization    = 65  # Target 65% CPU utilization at P95
    memory_p95_utilization = 75  # Target 75% memory utilization at P95
  }
}
```

## Implementation Checklist

- [ ] Update ECS module for container orchestration
- [ ] Create optimized multi-stage Dockerfile
- [ ] Configure ECR repositories for container images
- [ ] Set up Application Load Balancer with health checks
- [ ] Configure ECS services with auto-scaling policies
- [ ] Implement App Mesh for observability
- [ ] Update API Gateway to use VPC Link to ALB
- [ ] Configure CloudWatch Container Insights
- [ ] Implement blue-green deployment strategy
- [ ] Create container-based integration tests
- [ ] Document container build and deployment procedures
- [ ] Configure Fargate Spot for cost optimization
- [ ] Multi-region ECS cluster deployment