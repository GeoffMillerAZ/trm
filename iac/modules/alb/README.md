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
| [aws_lb.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs_config"></a> [access\_logs\_config](#input\_access\_logs\_config) | Access logs configuration | <pre>object({<br/>    bucket  = string<br/>    prefix  = string<br/>    enabled = bool<br/>  })</pre> | `null` | no |
| <a name="input_additional_target_groups"></a> [additional\_target\_groups](#input\_additional\_target\_groups) | Additional target groups for blue-green deployments or multiple services | <pre>map(object({<br/>    port                 = number<br/>    protocol             = string<br/>    target_type          = string<br/>    deregistration_delay = number<br/><br/>    health_check = object({<br/>      enabled             = bool<br/>      healthy_threshold   = number<br/>      unhealthy_threshold = number<br/>      timeout             = number<br/>      interval            = number<br/>      path                = string<br/>      matcher             = string<br/>      port                = string<br/>      protocol            = string<br/>    })<br/><br/>    stickiness = optional(object({<br/>      type            = string<br/>      cookie_duration = number<br/>      enabled         = bool<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ACM certificate ARN for HTTPS listener | `string` | `null` | no |
| <a name="input_create_http_listener"></a> [create\_http\_listener](#input\_create\_http\_listener) | Create HTTP listener | `bool` | `true` | no |
| <a name="input_create_https_listener"></a> [create\_https\_listener](#input\_create\_https\_listener) | Create HTTPS listener | `bool` | `false` | no |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable\_cross\_zone\_load\_balancing](#input\_enable\_cross\_zone\_load\_balancing) | Enable cross-zone load balancing | `bool` | `true` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | Enable deletion protection for the ALB | `bool` | `false` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | Enable HTTP/2 for the ALB | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_http_redirect_to_https"></a> [http\_redirect\_to\_https](#input\_http\_redirect\_to\_https) | Redirect HTTP traffic to HTTPS | `bool` | `false` | no |
| <a name="input_internal"></a> [internal](#input\_internal) | Whether the ALB is internal (true) or internet-facing (false) | `bool` | `true` | no |
| <a name="input_listener_rules"></a> [listener\_rules](#input\_listener\_rules) | Listener rules for advanced routing | <pre>map(object({<br/>    priority = number<br/><br/>    action = object({<br/>      type         = string<br/>      target_group = optional(string)<br/><br/>      redirect = optional(object({<br/>        port        = string<br/>        protocol    = string<br/>        status_code = string<br/>        host        = optional(string)<br/>        path        = optional(string)<br/>        query       = optional(string)<br/>      }))<br/><br/>      fixed_response = optional(object({<br/>        content_type = string<br/>        message_body = optional(string)<br/>        status_code  = string<br/>      }))<br/>    })<br/><br/>    # Conditions<br/>    path_pattern        = optional(string)<br/>    host_header         = optional(string)<br/>    http_request_method = optional(list(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_name_suffix"></a> [name\_suffix](#input\_name\_suffix) | Suffix for ALB name (e.g., 'api', 'internal') | `string` | `"alb"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security group IDs for the ALB | `list(string)` | n/a | yes |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | SSL policy for HTTPS listener | `string` | `"ELBSecurityPolicy-TLS-1-2-2017-01"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the ALB | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_target_group_config"></a> [target\_group\_config](#input\_target\_group\_config) | Default target group configuration | <pre>object({<br/>    port                 = number<br/>    protocol             = string<br/>    target_type          = string<br/>    deregistration_delay = number<br/><br/>    health_check = object({<br/>      enabled             = bool<br/>      healthy_threshold   = number<br/>      unhealthy_threshold = number<br/>      timeout             = number<br/>      interval            = number<br/>      path                = string<br/>      matcher             = string<br/>      port                = string<br/>      protocol            = string<br/>    })<br/><br/>    stickiness = optional(object({<br/>      type            = string<br/>      cookie_duration = number<br/>      enabled         = bool<br/>    }))<br/>  })</pre> | <pre>{<br/>  "deregistration_delay": 300,<br/>  "health_check": {<br/>    "enabled": true,<br/>    "healthy_threshold": 2,<br/>    "interval": 30,<br/>    "matcher": "200",<br/>    "path": "/health",<br/>    "port": "traffic-port",<br/>    "protocol": "HTTP",<br/>    "timeout": 5,<br/>    "unhealthy_threshold": 2<br/>  },<br/>  "port": 8000,<br/>  "protocol": "HTTP",<br/>  "target_type": "ip"<br/>}</pre> | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the ALB will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_additional_target_group_arns"></a> [additional\_target\_group\_arns](#output\_additional\_target\_group\_arns) | ARNs of additional target groups |
| <a name="output_additional_target_group_names"></a> [additional\_target\_group\_names](#output\_additional\_target\_group\_names) | Names of additional target groups |
| <a name="output_http_listener_arn"></a> [http\_listener\_arn](#output\_http\_listener\_arn) | ARN of the HTTP listener |
| <a name="output_https_listener_arn"></a> [https\_listener\_arn](#output\_https\_listener\_arn) | ARN of the HTTPS listener |
| <a name="output_load_balancer_arn"></a> [load\_balancer\_arn](#output\_load\_balancer\_arn) | ARN of the load balancer |
| <a name="output_load_balancer_dns_name"></a> [load\_balancer\_dns\_name](#output\_load\_balancer\_dns\_name) | DNS name of the load balancer |
| <a name="output_load_balancer_id"></a> [load\_balancer\_id](#output\_load\_balancer\_id) | ID of the load balancer |
| <a name="output_load_balancer_zone_id"></a> [load\_balancer\_zone\_id](#output\_load\_balancer\_zone\_id) | Canonical hosted zone ID of the load balancer |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | ARN of the default target group |
| <a name="output_target_group_name"></a> [target\_group\_name](#output\_target\_group\_name) | Name of the default target group |
| <a name="output_vpc_link_target_arns"></a> [vpc\_link\_target\_arns](#output\_vpc\_link\_target\_arns) | Target ARNs for VPC Link (load balancer ARN) |
