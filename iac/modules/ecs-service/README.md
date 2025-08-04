## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.alb_request_count](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_scheduled_action.scheduled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_scheduled_action) | resource |
| [aws_appautoscaling_target.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_ecs_service.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign public IP to tasks | `bool` | `false` | no |
| <a name="input_autoscaling_config"></a> [autoscaling\_config](#input\_autoscaling\_config) | Auto-scaling configuration for the ECS service | <pre>object({<br/>    min_capacity               = number<br/>    max_capacity               = number<br/>    enable_cpu_scaling         = optional(bool, true)<br/>    cpu_target_value           = optional(number, 70)<br/>    enable_memory_scaling      = optional(bool, false)<br/>    memory_target_value        = optional(number, 80)<br/>    enable_alb_request_scaling = optional(bool, false)<br/>    alb_resource_label         = optional(string)<br/>    alb_request_target_value   = optional(number, 1000)<br/>    scale_in_cooldown          = optional(number, 300)<br/>    scale_out_cooldown         = optional(number, 60)<br/>    scheduled_actions = optional(map(object({<br/>      schedule     = string<br/>      min_capacity = optional(number)<br/>      max_capacity = optional(number)<br/>    })), {})<br/>  })</pre> | <pre>{<br/>  "cpu_target_value": 70,<br/>  "max_capacity": 10,<br/>  "min_capacity": 2<br/>}</pre> | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | ECS cluster ID where the service will be deployed | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | ECS cluster name (used for auto-scaling resource ID) | `string` | n/a | yes |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | Container image URI (without tag) | `string` | n/a | yes |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Port exposed by the container | `number` | `8000` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | CPU units for the task (256, 512, 1024, 2048, 4096) | `string` | `"512"` | no |
| <a name="input_deployment_configuration"></a> [deployment\_configuration](#input\_deployment\_configuration) | ECS service deployment configuration | <pre>object({<br/>    maximum_percent         = number<br/>    minimum_healthy_percent = number<br/>    enable_circuit_breaker  = bool<br/>    enable_rollback         = bool<br/>  })</pre> | <pre>{<br/>  "enable_circuit_breaker": true,<br/>  "enable_rollback": true,<br/>  "maximum_percent": 200,<br/>  "minimum_healthy_percent": 100<br/>}</pre> | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Desired number of tasks | `number` | `2` | no |
| <a name="input_enable_autoscaling"></a> [enable\_autoscaling](#input\_enable\_autoscaling) | Enable auto-scaling for the ECS service | `bool` | `true` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Enable ECS Exec for debugging | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables for the container | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_force_new_deployment"></a> [force\_new\_deployment](#input\_force\_new\_deployment) | Force new deployment when task definition changes | `bool` | `false` | no |
| <a name="input_health_check"></a> [health\_check](#input\_health\_check) | Container health check configuration | <pre>object({<br/>    command     = list(string)<br/>    interval    = number<br/>    timeout     = number<br/>    retries     = number<br/>    startPeriod = number<br/>  })</pre> | <pre>{<br/>  "command": [<br/>    "CMD-SHELL",<br/>    "curl -f http://localhost:8080/api/v1/health || exit 1"<br/>  ],<br/>  "interval": 30,<br/>  "retries": 3,<br/>  "startPeriod": 60,<br/>  "timeout": 5<br/>}</pre> | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Grace period for health checks when load balancer is configured | `number` | `60` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Container image tag | `string` | `"latest"` | no |
| <a name="input_load_balancer_config"></a> [load\_balancer\_config](#input\_load\_balancer\_config) | Load balancer configuration for the service | <pre>object({<br/>    target_group_arn = string<br/>  })</pre> | `null` | no |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | CloudWatch log group name for container logs | `string` | n/a | yes |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory for the task in MB | `string` | `"1024"` | no |
| <a name="input_platform_version"></a> [platform\_version](#input\_platform\_version) | Fargate platform version | `string` | `"LATEST"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Secrets from AWS Secrets Manager or SSM Parameter Store | <pre>list(object({<br/>    name      = string<br/>    valueFrom = string<br/>  }))</pre> | `[]` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security group IDs for the service | `list(string)` | n/a | yes |
| <a name="input_service_discovery_config"></a> [service\_discovery\_config](#input\_service\_discovery\_config) | Service discovery configuration | <pre>object({<br/>    registry_arn = string<br/>  })</pre> | `null` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | Name of the ECS service | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the service | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_task_execution_role_arn"></a> [task\_execution\_role\_arn](#input\_task\_execution\_role\_arn) | ARN of the task execution role | `string` | n/a | yes |
| <a name="input_task_role_arn"></a> [task\_role\_arn](#input\_task\_role\_arn) | ARN of the task role | `string` | n/a | yes |
| <a name="input_wait_for_steady_state"></a> [wait\_for\_steady\_state](#input\_wait\_for\_steady\_state) | Wait for service to reach steady state after deployment | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_target_resource_id"></a> [autoscaling\_target\_resource\_id](#output\_autoscaling\_target\_resource\_id) | Resource ID of the auto-scaling target |
| <a name="output_container_name"></a> [container\_name](#output\_container\_name) | Name of the container |
| <a name="output_container_port"></a> [container\_port](#output\_container\_port) | Port exposed by the container |
| <a name="output_service_arn"></a> [service\_arn](#output\_service\_arn) | ARN of the ECS service |
| <a name="output_service_discovery_arn"></a> [service\_discovery\_arn](#output\_service\_discovery\_arn) | ARN of the service discovery service |
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | ID of the ECS service |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the ECS service |
| <a name="output_task_definition_arn"></a> [task\_definition\_arn](#output\_task\_definition\_arn) | ARN of the task definition |
| <a name="output_task_definition_family"></a> [task\_definition\_family](#output\_task\_definition\_family) | Family of the task definition |
| <a name="output_task_definition_revision"></a> [task\_definition\_revision](#output\_task\_definition\_revision) | Revision of the task definition |
