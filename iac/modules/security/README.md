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
| [aws_kms_alias.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms_data_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_secrets_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_kms_keys"></a> [create\_kms\_keys](#input\_create\_kms\_keys) | Whether to create KMS keys | `bool` | `true` | no |
| <a name="input_create_security_groups"></a> [create\_security\_groups](#input\_create\_security\_groups) | Whether to create security groups | `bool` | `true` | no |
| <a name="input_enable_multi_region_keys"></a> [enable\_multi\_region\_keys](#input\_enable\_multi\_region\_keys) | Enable multi-region KMS keys | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, prod) | `string` | n/a | yes |
| <a name="input_kms_key_aliases"></a> [kms\_key\_aliases](#input\_kms\_key\_aliases) | Map of KMS key aliases to create | `map(string)` | <pre>{<br/>  "data": "data-key",<br/>  "logs": "logs-key",<br/>  "secrets": "secrets-key"<br/>}</pre> | no |
| <a name="input_lambda_function_names"></a> [lambda\_function\_names](#input\_lambda\_function\_names) | List of Lambda function names that need security groups | `list(string)` | `[]` | no |
| <a name="input_primary_region"></a> [primary\_region](#input\_primary\_region) | Primary region for multi-region KMS keys | `string` | `"us-west-2"` | no |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | CIDR blocks of private subnets | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for resources | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | CIDR block of the VPC | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where security groups will be created | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_security_group_id"></a> [alb\_security\_group\_id](#output\_alb\_security\_group\_id) | Security group ID for Application Load Balancer |
| <a name="output_api_gateway_security_group_id"></a> [api\_gateway\_security\_group\_id](#output\_api\_gateway\_security\_group\_id) | Security group ID for API Gateway |
| <a name="output_database_security_group_id"></a> [database\_security\_group\_id](#output\_database\_security\_group\_id) | Security group ID for database instances |
| <a name="output_ecs_security_group_id"></a> [ecs\_security\_group\_id](#output\_ecs\_security\_group\_id) | Security group ID for ECS services |
| <a name="output_kms_data_alias_name"></a> [kms\_data\_alias\_name](#output\_kms\_data\_alias\_name) | KMS key alias name for data encryption |
| <a name="output_kms_data_key_arn"></a> [kms\_data\_key\_arn](#output\_kms\_data\_key\_arn) | KMS key ARN for data encryption |
| <a name="output_kms_data_key_id"></a> [kms\_data\_key\_id](#output\_kms\_data\_key\_id) | KMS key ID for data encryption |
| <a name="output_kms_logs_alias_name"></a> [kms\_logs\_alias\_name](#output\_kms\_logs\_alias\_name) | KMS key alias name for logs encryption |
| <a name="output_kms_logs_key_arn"></a> [kms\_logs\_key\_arn](#output\_kms\_logs\_key\_arn) | KMS key ARN for logs encryption |
| <a name="output_kms_logs_key_id"></a> [kms\_logs\_key\_id](#output\_kms\_logs\_key\_id) | KMS key ID for logs encryption |
| <a name="output_kms_secrets_alias_name"></a> [kms\_secrets\_alias\_name](#output\_kms\_secrets\_alias\_name) | KMS key alias name for secrets encryption |
| <a name="output_kms_secrets_key_arn"></a> [kms\_secrets\_key\_arn](#output\_kms\_secrets\_key\_arn) | KMS key ARN for secrets encryption |
| <a name="output_kms_secrets_key_id"></a> [kms\_secrets\_key\_id](#output\_kms\_secrets\_key\_id) | KMS key ID for secrets encryption |
| <a name="output_lambda_security_group_id"></a> [lambda\_security\_group\_id](#output\_lambda\_security\_group\_id) | Security group ID for Lambda functions |
| <a name="output_security_summary"></a> [security\_summary](#output\_security\_summary) | Summary of security configuration |
