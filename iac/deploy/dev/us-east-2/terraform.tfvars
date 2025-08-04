# Development Environment - US East 2 Variables
# This file contains the required variables for terraform plan/apply

# Terraform state bucket for accessing global state
terraform_state_bucket = "trm-blockexplorer-terraform-state-754419183698-us-west-2"

# ECS Configuration from Global Resources  
ecs_cluster_name             = "trm-blockexplorer-dev-cluster"
ecs_task_execution_role_arn  = "arn:aws:iam::754419183698:role/trm-blockexplorer-dev-ecs-task-execution-role"
ecs_task_role_arn           = "arn:aws:iam::754419183698:role/trm-blockexplorer-dev-ecs-task-role"

# Container Configuration (different ECR repo per region)
container_image_uri = "754419183698.dkr.ecr.us-east-2.amazonaws.com/trm-blockexplorer:latest"

# ECS Service Configuration for Development (secondary region)
ecs_service_config = {
  cpu                    = 256
  memory                 = 512
  desired_count          = 1
  container_port         = 8000
  enable_autoscaling     = false  # Disabled for dev cost optimization
  min_capacity           = 1
  max_capacity           = 2
  target_cpu_utilization = 70
  enable_logging         = true
}

# API Gateway Integration Type (ECS-only)
api_gateway_config = {
  enable_caching       = false # Disabled for dev
  cache_cluster_size   = "0.5"
  cache_ttl_seconds    = 60    # Shorter for dev
  throttle_burst_limit = 100   # Lower for dev
  throttle_rate_limit  = 50    # Lower for dev  
  api_key_source       = "HEADER"
}
