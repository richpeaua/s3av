# Application
output "application_arn" {
  description = "The Amazon Resource Name (ARN) of the AppConfig Application"
  value       = element(concat(aws_appconfig_application.this.*.arn, [""]), 0)
}

output "application_id" {
  description = "The AppConfig application ID"
  value       = element(concat(aws_appconfig_application.this.*.id, [""]), 0)
}

# Environments
output "environments" {
  description = "The AppConfig environments"
  value       = aws_appconfig_environment.this
}

# Configuration profile
output "configuration_profile_arn" {
  description = "The Amazon Resource Name (ARN) of the AppConfig Configuration Profile"
  value       = element(concat(aws_appconfig_configuration_profile.this.*.arn, [""]), 0)
}

output "configuration_profile_configuration_profile_id" {
  description = "The configuration profile ID"
  value       = element(concat(aws_appconfig_configuration_profile.this.*.configuration_profile_id, [""]), 0)
}

output "configuration_profile_id" {
  description = "The AppConfig configuration profile ID and application ID separated by a colon (:)"
  value       = element(concat(aws_appconfig_configuration_profile.this.*.id, [""]), 0)
}

# Hosted configuration version
output "hosted_configuration_version_arn" {
  description = "The Amazon Resource Name (ARN) of the AppConfig hosted configuration version"
  value       = element(concat(aws_appconfig_hosted_configuration_version.this.*.arn, [""]), 0)
}

output "hosted_configuration_version_id" {
  description = "The AppConfig application ID, configuration profile ID, and version number separated by a slash (/)"
  value       = element(concat(aws_appconfig_hosted_configuration_version.this.*.id, [""]), 0)
}

output "hosted_configuration_version_version_number" {
  description = "The version number of the hosted configuration"
  value       = element(concat(aws_appconfig_hosted_configuration_version.this.*.version_number, [""]), 0)
}

# Deployment strategy
output "deployment_strategy_arn" {
  description = "The Amazon Resource Name (ARN) of the AppConfig Deployment Strategy"
  value       = element(concat(aws_appconfig_deployment_strategy.this.*.arn, [""]), 0)
}

output "deployment_strategy_id" {
  description = "The AppConfig deployment strategy ID"
  value       = element(concat(aws_appconfig_deployment_strategy.this.*.id, [""]), 0)
}

# Deployment
output "deployments" {
  description = "The AppConfig deployments"
  value       = aws_appconfig_deployment.this
}

# Retrieval role
output "retrieval_role_arn" {
  description = "Amazon Resource Name (ARN) specifying the retrieval role"
  value       = element(concat(aws_iam_role.retrieval.*.arn, [""]), 0)
}

output "retrieval_role_id" {
  description = "Name of the retrieval role"
  value       = element(concat(aws_iam_role.retrieval.*.id, [""]), 0)
}

output "retrieval_role_unique_id" {
  description = "Stable and unique string identifying the retrieval role"
  value       = element(concat(aws_iam_role.retrieval.*.unique_id, [""]), 0)
}

output "retrieval_role_name" {
  description = "Name of the retrieval role"
  value       = element(concat(aws_iam_role.retrieval.*.name, [""]), 0)
}

output "retrieval_role_policy_arn" {
  description = "The ARN assigned by AWS to the retrieval role policy"
  value       = element(concat(aws_iam_policy.retrieval.*.arn, [""]), 0)
}

output "retrieval_role_policy_id" {
  description = "The ARN assigned by AWS to the retrieval role policy"
  value       = element(concat(aws_iam_policy.retrieval.*.id, [""]), 0)
}

output "retrieval_role_policy_name" {
  description = "The name of the policy"
  value       = element(concat(aws_iam_policy.retrieval.*.name, [""]), 0)
}

output "retrieval_role_policy_policy" {
  description = "The retrieval role policy document"
  value       = element(concat(aws_iam_policy.retrieval.*.policy, [""]), 0)
}

output "retrieval_role_policy_policy_id" {
  description = "The retrieval role policy ID"
  value       = element(concat(aws_iam_policy.retrieval.*.policy_id, [""]), 0)
}