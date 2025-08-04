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
| [aws_api_gateway_api_key.keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_api_key) | resource |
| [aws_api_gateway_base_path_mapping.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_domain_name.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |
| [aws_api_gateway_integration.address_balance_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.address_balance_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.health_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.health_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.watchlist_addresses_get_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.watchlist_addresses_get_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.watchlist_addresses_post_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.watchlist_addresses_post_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration_response.options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_method.address_balance_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.health_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.watchlist_addresses_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.watchlist_addresses_post](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_response.options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_resource.address](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.address_balance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.address_param](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.health](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.watchlist](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.watchlist_addresses](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_api_gateway_usage_plan.plans](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan) | resource |
| [aws_api_gateway_usage_plan_key.plan_keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan_key) | resource |
| [aws_api_gateway_vpc_link.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_vpc_link) | resource |
| [aws_lambda_permission.api_gateway_health_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.api_gateway_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_route53_record.custom_domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_arn"></a> [alb\_arn](#input\_alb\_arn) | ALB ARN for VPC Link target (required for HTTP integrations) | `string` | `null` | no |
| <a name="input_alb_dns_name"></a> [alb\_dns\_name](#input\_alb\_dns\_name) | DNS name of the Application Load Balancer for HTTP integrations | `string` | `null` | no |
| <a name="input_alb_listener_port"></a> [alb\_listener\_port](#input\_alb\_listener\_port) | Port of the ALB listener for HTTP integrations | `number` | `80` | no |
| <a name="input_api_description"></a> [api\_description](#input\_api\_description) | Description of the API Gateway | `string` | `"Blockchain Explorer API"` | no |
| <a name="input_api_key_source"></a> [api\_key\_source](#input\_api\_key\_source) | Source of API key for requests | `string` | `"HEADER"` | no |
| <a name="input_api_keys"></a> [api\_keys](#input\_api\_keys) | Map of API keys to create | <pre>map(object({<br/>    description = string<br/>    usage_plan  = string<br/>  }))</pre> | `{}` | no |
| <a name="input_api_name"></a> [api\_name](#input\_api\_name) | Name of the API Gateway | `string` | `null` | no |
| <a name="input_cache_cluster_size"></a> [cache\_cluster\_size](#input\_cache\_cluster\_size) | API Gateway cache cluster size | `string` | `"0.5"` | no |
| <a name="input_cache_ttl_seconds"></a> [cache\_ttl\_seconds](#input\_cache\_ttl\_seconds) | Cache TTL in seconds | `number` | `300` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ACM certificate ARN for custom domain | `string` | `null` | no |
| <a name="input_cors_configuration"></a> [cors\_configuration](#input\_cors\_configuration) | CORS configuration for API Gateway | <pre>object({<br/>    allow_origins     = list(string)<br/>    allow_methods     = list(string)<br/>    allow_headers     = list(string)<br/>    expose_headers    = list(string)<br/>    allow_credentials = bool<br/>    max_age           = number<br/>  })</pre> | <pre>{<br/>  "allow_credentials": false,<br/>  "allow_headers": [<br/>    "Content-Type",<br/>    "X-Amz-Date",<br/>    "Authorization",<br/>    "X-Api-Key",<br/>    "X-Amz-Security-Token"<br/>  ],<br/>  "allow_methods": [<br/>    "GET",<br/>    "POST",<br/>    "PUT",<br/>    "DELETE",<br/>    "OPTIONS"<br/>  ],<br/>  "allow_origins": [<br/>    "*"<br/>  ],<br/>  "expose_headers": [<br/>    "X-Amz-Request-Id"<br/>  ],<br/>  "max_age": 86400<br/>}</pre> | no |
| <a name="input_custom_domain_name"></a> [custom\_domain\_name](#input\_custom\_domain\_name) | Custom domain name for API Gateway | `string` | `null` | no |
| <a name="input_enable_access_logs"></a> [enable\_access\_logs](#input\_enable\_access\_logs) | Enable access logging for API Gateway | `bool` | `true` | no |
| <a name="input_enable_caching"></a> [enable\_caching](#input\_enable\_caching) | Enable API Gateway caching | `bool` | `true` | no |
| <a name="input_enable_xray_tracing"></a> [enable\_xray\_tracing](#input\_enable\_xray\_tracing) | Enable X-Ray tracing for API Gateway | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, prod) | `string` | n/a | yes |
| <a name="input_health_lambda_function_name"></a> [health\_lambda\_function\_name](#input\_health\_lambda\_function\_name) | Health check Lambda function name (legacy) | `string` | `null` | no |
| <a name="input_health_lambda_invoke_arn"></a> [health\_lambda\_invoke\_arn](#input\_health\_lambda\_invoke\_arn) | Health check Lambda function invoke ARN (legacy) | `string` | `null` | no |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | Route 53 hosted zone ID for custom domain | `string` | `null` | no |
| <a name="input_integration_type"></a> [integration\_type](#input\_integration\_type) | Integration type: 'lambda' for Lambda functions, 'http' for ECS services | `string` | `"lambda"` | no |
| <a name="input_lambda_function_invoke_arn"></a> [lambda\_function\_invoke\_arn](#input\_lambda\_function\_invoke\_arn) | Lambda function invoke ARN for API integration (legacy) | `string` | `null` | no |
| <a name="input_lambda_function_name"></a> [lambda\_function\_name](#input\_lambda\_function\_name) | Lambda function name for permissions (legacy) | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | Stage name for API deployment | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for resources | `map(string)` | `{}` | no |
| <a name="input_throttle_burst_limit"></a> [throttle\_burst\_limit](#input\_throttle\_burst\_limit) | API Gateway throttle burst limit | `number` | `1000` | no |
| <a name="input_throttle_rate_limit"></a> [throttle\_rate\_limit](#input\_throttle\_rate\_limit) | API Gateway throttle rate limit | `number` | `500` | no |
| <a name="input_usage_plans"></a> [usage\_plans](#input\_usage\_plans) | Map of usage plans to create | <pre>map(object({<br/>    description = string<br/>    quota = optional(object({<br/>      limit  = number<br/>      period = string<br/>    }))<br/>    throttle = optional(object({<br/>      burst_limit = number<br/>      rate_limit  = number<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_log_group_arn"></a> [access\_log\_group\_arn](#output\_access\_log\_group\_arn) | CloudWatch log group ARN for API Gateway access logs |
| <a name="output_access_log_group_name"></a> [access\_log\_group\_name](#output\_access\_log\_group\_name) | CloudWatch log group name for API Gateway access logs |
| <a name="output_address_balance_resource_id"></a> [address\_balance\_resource\_id](#output\_address\_balance\_resource\_id) | Resource ID for address balance endpoint |
| <a name="output_api_gateway_configuration"></a> [api\_gateway\_configuration](#output\_api\_gateway\_configuration) | Summary of API Gateway configuration |
| <a name="output_api_key_ids"></a> [api\_key\_ids](#output\_api\_key\_ids) | Map of API key names to IDs |
| <a name="output_api_key_values"></a> [api\_key\_values](#output\_api\_key\_values) | Map of API key names to values |
| <a name="output_custom_domain_name"></a> [custom\_domain\_name](#output\_custom\_domain\_name) | Custom domain name for the API |
| <a name="output_custom_domain_target"></a> [custom\_domain\_target](#output\_custom\_domain\_target) | Target domain name for the custom domain |
| <a name="output_custom_domain_zone_id"></a> [custom\_domain\_zone\_id](#output\_custom\_domain\_zone\_id) | Zone ID for the custom domain |
| <a name="output_deployment_id"></a> [deployment\_id](#output\_deployment\_id) | ID of the API Gateway deployment |
| <a name="output_execution_log_group_arn"></a> [execution\_log\_group\_arn](#output\_execution\_log\_group\_arn) | CloudWatch log group ARN for API Gateway execution logs |
| <a name="output_execution_log_group_name"></a> [execution\_log\_group\_name](#output\_execution\_log\_group\_name) | CloudWatch log group name for API Gateway execution logs |
| <a name="output_health_resource_id"></a> [health\_resource\_id](#output\_health\_resource\_id) | Resource ID for health endpoint |
| <a name="output_integration_type"></a> [integration\_type](#output\_integration\_type) | Type of integration used (lambda or http) |
| <a name="output_rest_api_execution_arn"></a> [rest\_api\_execution\_arn](#output\_rest\_api\_execution\_arn) | Execution ARN of the REST API |
| <a name="output_rest_api_id"></a> [rest\_api\_id](#output\_rest\_api\_id) | ID of the REST API |
| <a name="output_rest_api_root_resource_id"></a> [rest\_api\_root\_resource\_id](#output\_rest\_api\_root\_resource\_id) | Root resource ID of the REST API |
| <a name="output_stage_execution_arn"></a> [stage\_execution\_arn](#output\_stage\_execution\_arn) | Execution ARN of the API Gateway stage |
| <a name="output_stage_invoke_url"></a> [stage\_invoke\_url](#output\_stage\_invoke\_url) | Invoke URL of the API Gateway stage |
| <a name="output_stage_name"></a> [stage\_name](#output\_stage\_name) | Name of the API Gateway stage |
| <a name="output_usage_plan_ids"></a> [usage\_plan\_ids](#output\_usage\_plan\_ids) | Map of usage plan names to IDs |
| <a name="output_vpc_link_id"></a> [vpc\_link\_id](#output\_vpc\_link\_id) | ID of the VPC Link (for HTTP integrations) |
| <a name="output_vpc_link_name"></a> [vpc\_link\_name](#output\_vpc\_link\_name) | Name of the VPC Link (for HTTP integrations) |
| <a name="output_watchlist_addresses_resource_id"></a> [watchlist\_addresses\_resource\_id](#output\_watchlist\_addresses\_resource\_id) | Resource ID for watchlist addresses endpoint |
