# ECS Module

This module creates an Amazon ECS (Elastic Container Service) cluster with support for both Fargate and EC2 launch types.

## Features

- **Multi-launch type support**: Fargate, Fargate Spot, and EC2
- **Container Insights**: CloudWatch Container Insights for monitoring
- **Service Discovery**: AWS Cloud Map integration
- **Auto-scaling**: Built-in auto-scaling policies for services
- **Security**: IAM roles and security groups pre-configured
- **Logging**: CloudWatch Logs integration with KMS encryption

## Usage

```hcl
module "ecs" {
  source = "../../modules/ecs"

  project_name = "trm-blockexplorer"
  environment  = "prod"
  region       = "us-west-2"
  vpc_id       = module.networking.vpc_id

  # Enable both Fargate and EC2
  enable_fargate = true
  enable_ec2     = true
  ec2_asg_arn    = aws_autoscaling_group.ecs_instances.arn

  # Container Insights for monitoring
  enable_container_insights = true

  # Service Discovery
  enable_service_discovery    = true
  service_discovery_namespace = "internal"

  # Security
  kms_key_arn           = module.security.kms_logs_key_arn
  alb_security_group_id = module.alb.security_group_id

  # Auto-scaling configuration for services
  service_autoscaling_configs = {
    "api-service" = {
      min_capacity               = 2
      max_capacity               = 10
      enable_cpu_scaling         = true
      cpu_target_value           = 70
      enable_alb_request_scaling = true
      alb_target_group_arn       = module.alb.target_group_arn
      alb_request_target_value   = 1000
      
      scheduled_actions = {
        "scale-up-morning" = {
          schedule     = "cron(0 8 * * ? *)"
          min_capacity = 4
        }
        "scale-down-night" = {
          schedule     = "cron(0 22 * * ? *)"
          min_capacity = 2
        }
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Capacity Provider Strategy

The module supports flexible capacity provider strategies:

```hcl
default_capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE_SPOT"
    weight            = 2
  },
  {
    capacity_provider = "FARGATE"
    weight            = 1
  }
]
```

## Task Definition Example

When creating task definitions to run on this cluster:

```hcl
resource "aws_ecs_task_definition" "app" {
  family                   = "my-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = module.ecs.task_execution_role_arn
  task_role_arn      = module.ecs.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "my-app:latest"
      
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = module.ecs.cloudwatch_log_group_name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "app"
        }
      }
      
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]
      
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "arn:aws:secretsmanager:region:account:secret:db-password"
        }
      ]
    }
  ])
}
```

## Service Example

```hcl
resource "aws_ecs_service" "app" {
  name            = "app-service"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2

  launch_type = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [module.ecs.service_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.app.arn
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
```

## Auto-scaling

The module provides built-in auto-scaling support:

1. **CPU-based scaling**: Scales based on average CPU utilization
2. **Memory-based scaling**: Scales based on average memory utilization  
3. **ALB request-based scaling**: Scales based on requests per target
4. **Scheduled scaling**: Scale up/down at specific times

## Security Considerations

- Task execution role has access to pull images and write logs
- Task role is minimal by default - add policies as needed
- Security group allows outbound traffic only by default
- Secrets are accessed via Secrets Manager with KMS encryption

## Outputs

The module exports:
- Cluster ID, ARN, and name
- Task execution and task role ARNs
- Security group ID for services
- CloudWatch log group details
- Service discovery namespace details

## Migration from Lambda

When migrating from Lambda to ECS:

1. Use the task role ARN for permissions (similar to Lambda execution role)
2. Configure memory/CPU based on Lambda settings
3. Use environment variables and secrets for configuration
4. Set up service auto-scaling to match Lambda concurrency
5. Use ALB for HTTP triggers (replacing API Gateway)