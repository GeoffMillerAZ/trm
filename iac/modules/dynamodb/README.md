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
| [aws_cloudwatch_metric_alarm.consumed_read_capacity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.consumed_write_capacity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.read_throttled_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.write_throttled_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_dynamodb_table.tables](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | Enable deletion protection for tables | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, prod) | `string` | n/a | yes |
| <a name="input_is_primary_region"></a> [is\_primary\_region](#input\_is\_primary\_region) | Whether this is the primary region for Global Tables | `bool` | `true` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key ARN for encryption | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_replica_regions"></a> [replica\_regions](#input\_replica\_regions) | List of replica regions for Global Tables | `list(string)` | `[]` | no |
| <a name="input_tables"></a> [tables](#input\_tables) | Map of DynamoDB tables to create | <pre>map(object({<br/>    hash_key               = string<br/>    range_key              = optional(string)<br/>    billing_mode           = optional(string, "PAY_PER_REQUEST")<br/>    read_capacity          = optional(number, 5)<br/>    write_capacity         = optional(number, 5)<br/>    stream_enabled         = optional(bool, true)<br/>    stream_view_type       = optional(string, "NEW_AND_OLD_IMAGES")<br/>    point_in_time_recovery = optional(bool, true)<br/><br/>    attributes = list(object({<br/>      name = string<br/>      type = string<br/>    }))<br/><br/>    global_secondary_indexes = optional(list(object({<br/>      name            = string<br/>      hash_key        = string<br/>      range_key       = optional(string)<br/>      projection_type = optional(string, "ALL")<br/>      read_capacity   = optional(number, 5)<br/>      write_capacity  = optional(number, 5)<br/>    })), [])<br/><br/>    local_secondary_indexes = optional(list(object({<br/>      name            = string<br/>      range_key       = string<br/>      projection_type = optional(string, "ALL")<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address_watchlist_table_arn"></a> [address\_watchlist\_table\_arn](#output\_address\_watchlist\_table\_arn) | Address watchlist table ARN |
| <a name="output_address_watchlist_table_name"></a> [address\_watchlist\_table\_name](#output\_address\_watchlist\_table\_name) | Address watchlist table name |
| <a name="output_dynamodb_configuration"></a> [dynamodb\_configuration](#output\_dynamodb\_configuration) | Summary of DynamoDB configuration |
| <a name="output_global_table_arns"></a> [global\_table\_arns](#output\_global\_table\_arns) | Map of global table logical names to table ARNs |
| <a name="output_global_table_names"></a> [global\_table\_names](#output\_global\_table\_names) | Map of global table logical names to actual table names |
| <a name="output_investigation_notes_table_arn"></a> [investigation\_notes\_table\_arn](#output\_investigation\_notes\_table\_arn) | Investigation notes table ARN |
| <a name="output_investigation_notes_table_name"></a> [investigation\_notes\_table\_name](#output\_investigation\_notes\_table\_name) | Investigation notes table name |
| <a name="output_read_throttled_events_alarm_arns"></a> [read\_throttled\_events\_alarm\_arns](#output\_read\_throttled\_events\_alarm\_arns) | Map of table names to read throttled events alarm ARNs |
| <a name="output_suspicious_transactions_table_arn"></a> [suspicious\_transactions\_table\_arn](#output\_suspicious\_transactions\_table\_arn) | Suspicious transactions table ARN |
| <a name="output_suspicious_transactions_table_name"></a> [suspicious\_transactions\_table\_name](#output\_suspicious\_transactions\_table\_name) | Suspicious transactions table name |
| <a name="output_table_arns"></a> [table\_arns](#output\_table\_arns) | Map of table logical names to table ARNs |
| <a name="output_table_names"></a> [table\_names](#output\_table\_names) | Map of table logical names to actual table names |
| <a name="output_table_stream_arns"></a> [table\_stream\_arns](#output\_table\_stream\_arns) | Map of table logical names to stream ARNs |
| <a name="output_write_throttled_events_alarm_arns"></a> [write\_throttled\_events\_alarm\_arns](#output\_write\_throttled\_events\_alarm\_arns) | Map of table names to write throttled events alarm ARNs |
