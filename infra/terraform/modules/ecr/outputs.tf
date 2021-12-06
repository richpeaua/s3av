output "registry_id" {
  value       = var.is_enabled ? aws_ecr_repository.this[0].registry_id : ""
  description = "Registry ID"
}

output "repository_name" {
  value       = var.is_enabled ? aws_ecr_repository.this[0].name : ""
  description = "Repository Name"
}

output "repository_url" {
  value       = var.is_enabled ? aws_ecr_repository.this[0].repository_url : ""
  description = "Repository URL"
}

output "repository_arn" {
  value       = var.is_enabled ? aws_ecr_repository.this[0].arn : ""
  description = "Repository ARN"
}
