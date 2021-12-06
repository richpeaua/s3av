resource "aws_ecr_repository" "this" {
  count                = var.is_enabled ? 1 : 0
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_arn
  }

  image_scanning_configuration {
    scan_on_push = var.scan_images_on_push
  }

  tags = merge({
    "Name" = "${var.name_prefix}-${var.software_name}"
    },
    var.tags
  )
}

locals {
  repo_lifecycle_policy = jsonencode({
    rules = [
      {
        action       = { type = "expire" }
        description  = "Store just ${var.max_image_count} images and expire old images"
        rulePriority = 2
        selection = {
          countNumber = var.max_image_count
          countType   = "imageCountMoreThan"
          tagStatus   = "any"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.is_enabled && var.enable_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.this[0].name

  policy = local.repo_lifecycle_policy
}
