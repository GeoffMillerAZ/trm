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
| [aws_cloudwatch_metric_alarm.lambda_duration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_throttles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_lambda_function.functions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function_url.function_urls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_environment_variables"></a> [default\_environment\_variables](#input\_default\_environment\_variables) | Default environment variables for all Lambda functions | `map(string)` | `{}` | no |
| <a name="input_enable_xray_tracing"></a> [enable\_xray\_tracing](#input\_enable\_xray\_tracing) | Enable X-Ray tracing for Lambda functions | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, prod) | `string` | n/a | yes |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | IAM role ARN for Lambda execution | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key ARN for environment variable encryption | `string` | `null` | no |
| <a name="input_lambda_functions"></a> [lambda\_functions](#input\_lambda\_functions) | Map of Lambda functions to create | <pre>map(object({<br/>    filename             = optional(string)<br/>    s3_bucket            = optional(string)<br/>    s3_key               = optional(string)<br/>    handler              = string<br/>    runtime              = optional(string, "python3.12")<br/>    memory_size          = optional(number, 1024)<br/>    timeout              = optional(number, 29)<br/>    reserved_concurrency = optional(number)<br/><br/>    environment_variables = optional(map(string), {})<br/><br/>    # VPC Configuration<br/>    vpc_config = optional(object({<br/>      subnet_ids         = list(string)<br/>      security_group_ids = list(string)<br/>    }))<br/><br/>    # Dead Letter Queue<br/>    dead_letter_config = optional(object({<br/>      target_arn = string<br/>    }))<br/><br/>    # Layers<br/>    layers = optional(list(string), [])<br/><br/>    # Tracing<br/>    tracing_mode = optional(string, "Active")<br/><br/>    # Log retention<br/>    log_retention_days = optional(number, 30)<br/>  }))</pre> | `{}` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_duration_alarm_arns"></a> [duration\_alarm\_arns](#output\_duration\_alarm\_arns) | Map of function names to duration alarm ARNs |
| <a name="output_error_alarm_arns"></a> [error\_alarm\_arns](#output\_error\_alarm\_arns) | Map of function names to error alarm ARNs |
| <a name="output_function_arns"></a> [function\_arns](#output\_function\_arns) | Map of logical names to Lambda function ARNs |
| <a name="output_function_invoke_arns"></a> [function\_invoke\_arns](#output\_function\_invoke\_arns) | Map of logical names to Lambda function invoke ARNs |
| <a name="output_function_names"></a> [function\_names](#output\_function\_names) | Map of logical names to Lambda function names |
| <a name="output_function_qualified_arns"></a> [function\_qualified\_arns](#output\_function\_qualified\_arns) | Map of logical names to Lambda function qualified ARNs |
| <a name="output_function_urls"></a> [function\_urls](#output\_function\_urls) | Map of logical names to Lambda function URLs |
| <a name="output_function_versions"></a> [function\_versions](#output\_function\_versions) | Map of logical names to Lambda function versions |
| <a name="output_health_function_arn"></a> [health\_function\_arn](#output\_health\_function\_arn) | Health check function ARN |
| <a name="output_health_function_invoke_arn"></a> [health\_function\_invoke\_arn](#output\_health\_function\_invoke\_arn) | Health check function invoke ARN |
| <a name="output_health_function_name"></a> [health\_function\_name](#output\_health\_function\_name) | Health check function name |
| <a name="output_lambda_configuration"></a> [lambda\_configuration](#output\_lambda\_configuration) | Summary of Lambda configuration |
| <a name="output_log_group_arns"></a> [log\_group\_arns](#output\_log\_group\_arns) | Map of logical names to CloudWatch log group ARNs |
| <a name="output_log_group_names"></a> [log\_group\_names](#output\_log\_group\_names) | Map of logical names to CloudWatch log group names |
| <a name="output_main_function_arn"></a> [main\_function\_arn](#output\_main\_function\_arn) | Main application function ARN |
| <a name="output_main_function_invoke_arn"></a> [main\_function\_invoke\_arn](#output\_main\_function\_invoke\_arn) | Main application function invoke ARN |
| <a name="output_main_function_name"></a> [main\_function\_name](#output\_main\_function\_name) | Main application function name |
| <a name="output_throttle_alarm_arns"></a> [throttle\_alarm\_arns](#output\_throttle\_alarm\_arns) | Map of function names to throttle alarm ARNs |
