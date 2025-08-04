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
| [aws_cloudwatch_dashboard.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_metric_alarm.api_gateway_4xx_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.api_gateway_5xx_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.api_gateway_latency](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.custom_metrics](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.dynamodb_read_throttles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.dynamodb_write_throttles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_duration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_throttles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_sns_topic.alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email_alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_email_endpoints"></a> [alarm\_email\_endpoints](#input\_alarm\_email\_endpoints) | List of email addresses for alarm notifications | `list(string)` | `[]` | no |
| <a name="input_api_gateway_id"></a> [api\_gateway\_id](#input\_api\_gateway\_id) | API Gateway ID to monitor | `string` | `null` | no |
| <a name="input_api_gateway_stage_name"></a> [api\_gateway\_stage\_name](#input\_api\_gateway\_stage\_name) | API Gateway stage name to monitor | `string` | `null` | no |
| <a name="input_create_dashboard"></a> [create\_dashboard](#input\_create\_dashboard) | Whether to create CloudWatch dashboard | `bool` | `true` | no |
| <a name="input_custom_metrics"></a> [custom\_metrics](#input\_custom\_metrics) | Map of custom metrics to create alarms for | <pre>map(object({<br/>    metric_name         = string<br/>    namespace           = string<br/>    statistic           = string<br/>    comparison_operator = string<br/>    threshold           = number<br/>    evaluation_periods  = number<br/>    period              = number<br/>    alarm_description   = string<br/>    dimensions          = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_dashboard_name"></a> [dashboard\_name](#input\_dashboard\_name) | Name of the CloudWatch dashboard | `string` | `null` | no |
| <a name="input_dynamodb_table_names"></a> [dynamodb\_table\_names](#input\_dynamodb\_table\_names) | List of DynamoDB table names to monitor | `list(string)` | `[]` | no |
| <a name="input_enable_api_gateway_monitoring"></a> [enable\_api\_gateway\_monitoring](#input\_enable\_api\_gateway\_monitoring) | Whether to enable API Gateway monitoring | `bool` | `true` | no |
| <a name="input_enable_detailed_monitoring"></a> [enable\_detailed\_monitoring](#input\_enable\_detailed\_monitoring) | Enable detailed monitoring metrics | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, prod) | `string` | n/a | yes |
| <a name="input_lambda_function_names"></a> [lambda\_function\_names](#input\_lambda\_function\_names) | List of Lambda function names to monitor | `list(string)` | `[]` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention days | `number` | `30` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_sns_topic_arns"></a> [sns\_topic\_arns](#input\_sns\_topic\_arns) | List of SNS topic ARNs for alarm notifications | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_all_alarm_arns"></a> [all\_alarm\_arns](#output\_all\_alarm\_arns) | List of all alarm ARNs created by this module |
| <a name="output_api_gateway_4xx_alarm_arn"></a> [api\_gateway\_4xx\_alarm\_arn](#output\_api\_gateway\_4xx\_alarm\_arn) | API Gateway 4XX error alarm ARN |
| <a name="output_api_gateway_5xx_alarm_arn"></a> [api\_gateway\_5xx\_alarm\_arn](#output\_api\_gateway\_5xx\_alarm\_arn) | API Gateway 5XX error alarm ARN |
| <a name="output_api_gateway_latency_alarm_arn"></a> [api\_gateway\_latency\_alarm\_arn](#output\_api\_gateway\_latency\_alarm\_arn) | API Gateway latency alarm ARN |
| <a name="output_custom_metric_alarm_arns"></a> [custom\_metric\_alarm\_arns](#output\_custom\_metric\_alarm\_arns) | Map of custom metric names to alarm ARNs |
| <a name="output_dashboard_name"></a> [dashboard\_name](#output\_dashboard\_name) | CloudWatch dashboard name |
| <a name="output_dashboard_url"></a> [dashboard\_url](#output\_dashboard\_url) | CloudWatch dashboard URL |
| <a name="output_dynamodb_read_throttle_alarm_arns"></a> [dynamodb\_read\_throttle\_alarm\_arns](#output\_dynamodb\_read\_throttle\_alarm\_arns) | Map of DynamoDB table names to read throttle alarm ARNs |
| <a name="output_dynamodb_write_throttle_alarm_arns"></a> [dynamodb\_write\_throttle\_alarm\_arns](#output\_dynamodb\_write\_throttle\_alarm\_arns) | Map of DynamoDB table names to write throttle alarm ARNs |
| <a name="output_lambda_duration_alarm_arns"></a> [lambda\_duration\_alarm\_arns](#output\_lambda\_duration\_alarm\_arns) | Map of Lambda function names to duration alarm ARNs |
| <a name="output_lambda_error_alarm_arns"></a> [lambda\_error\_alarm\_arns](#output\_lambda\_error\_alarm\_arns) | Map of Lambda function names to error alarm ARNs |
| <a name="output_lambda_throttle_alarm_arns"></a> [lambda\_throttle\_alarm\_arns](#output\_lambda\_throttle\_alarm\_arns) | Map of Lambda function names to throttle alarm ARNs |
| <a name="output_monitoring_configuration"></a> [monitoring\_configuration](#output\_monitoring\_configuration) | Summary of monitoring configuration |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | SNS topic ARN for alarm notifications |
