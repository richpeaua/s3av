* Create VPC first
* Create ECR repos
* Set ASM secrets

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudtrail_log_subscription"></a> [cloudtrail\_log\_subscription](#module\_cloudtrail\_log\_subscription) | ../cloudwatch-subscription | n/a |
| <a name="module_ecr_dispatcher"></a> [ecr\_dispatcher](#module\_ecr\_dispatcher) | ../ecr | n/a |
| <a name="module_ecr_notify"></a> [ecr\_notify](#module\_ecr\_notify) | ../ecr | n/a |
| <a name="module_ecr_scanner"></a> [ecr\_scanner](#module\_ecr\_scanner) | ../ecr | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ../kms | n/a |
| <a name="module_lambda_dispatcher"></a> [lambda\_dispatcher](#module\_lambda\_dispatcher) | terraform-aws-modules/lambda/aws | n/a |
| <a name="module_lambda_notify"></a> [lambda\_notify](#module\_lambda\_notify) | terraform-aws-modules/lambda/aws | n/a |
| <a name="module_lambda_scanner"></a> [lambda\_scanner](#module\_lambda\_scanner) | terraform-aws-modules/lambda/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.update_vs_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.update_vs_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_efs_access_point.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_security_group.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.lambda_dispatcher](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.lambda_scanner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_sns_topic.notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.scan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.notify_sns_to_notify_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.scan_sns_to_scanner_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_iam_policy_document.lambda_dispatcher_appconfig](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_dispatcher_to_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_notify_to_asm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_notify_to_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_scanner_appconfig](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_scanner_cross_account_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_scanner_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_scanner_to_notify_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_appconfig_app_arn"></a> [appconfig\_app\_arn](#input\_appconfig\_app\_arn) | Arn of the AppConfig application that will be used to supply configuration to all three lambda functions | `string` | n/a | yes |
| <a name="input_appconfig_config_prof_arn"></a> [appconfig\_config\_prof\_arn](#input\_appconfig\_config\_prof\_arn) | Arn of the AppConfig application configuration profile | `string` | n/a | yes |
| <a name="input_appconfig_env_arn"></a> [appconfig\_env\_arn](#input\_appconfig\_env\_arn) | Arn of the AppConfig application environment | `string` | n/a | yes |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS account ID which will be used to deploy resources | `string` | n/a | yes |
| <a name="input_cloudtrail_log_filter_pattern"></a> [cloudtrail\_log\_filter\_pattern](#input\_cloudtrail\_log\_filter\_pattern) | CloudTrail log group name in CloudWatch | `string` | `""` | no |
| <a name="input_cloudtrail_log_group_name"></a> [cloudtrail\_log\_group\_name](#input\_cloudtrail\_log\_group\_name) | CloudTrail log group name in CloudWatch | `string` | n/a | yes |
| <a name="input_ecr_max_image_count"></a> [ecr\_max\_image\_count](#input\_ecr\_max\_image\_count) | How many Docker Image versions AWS ECR will store | `number` | `20` | no |
| <a name="input_image_tag_dispatcher"></a> [image\_tag\_dispatcher](#input\_image\_tag\_dispatcher) | Container image tag for Events Dispatcher Lambda source code | `string` | n/a | yes |
| <a name="input_image_tag_notify"></a> [image\_tag\_notify](#input\_image\_tag\_notify) | Container image tag for Slack notification Lambda source code | `string` | n/a | yes |
| <a name="input_image_tag_scanner"></a> [image\_tag\_scanner](#input\_image\_tag\_scanner) | Container image tag for Virus Scanner Lambda source code | `string` | n/a | yes |
| <a name="input_is_enabled"></a> [is\_enabled](#input\_is\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Name to be used on all resources as prefix. Is most cases project name or terraform workspace. eg corporate, sandbox\_poc | `string` | `"sandbox"` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | n/a | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region which will be used to deploy resources | `string` | n/a | yes |
| <a name="input_software_name"></a> [software\_name](#input\_software\_name) | Software name | `string` | `"splunk"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_update_clamav_db_schedule_expression"></a> [update\_clamav\_db\_schedule\_expression](#input\_update\_clamav\_db\_schedule\_expression) | Schedule expression config for ClamAV database updater | `string` | `"rate(1 day)"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC CIDR | `any` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `any` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->