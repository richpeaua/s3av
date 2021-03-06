locals {
  repo_prefix = "lambda/${var.app_name}"
}

#====================================================
# Scanner ECR Repository
#====================================================
module "ecr_scanner" {
  source        = "./modules/ecr"
  is_enabled    = var.scanner_enabled
  software_name = var.app_name
  name_prefix   = "${var.app_env}-${var.app_name}"

  repository_name     = "${local.repo_prefix}/scanner"
  scan_images_on_push = true
  kms_arn             = module.kms.key_arn
  max_image_count     = var.ecr_max_image_count

  # principals_readonly_access = [module.lambda_function_container_image.this_lambda_function_arn]
  tags = var.tags
}

#====================================================
# Slack Notify ECR Repository
#====================================================
module "ecr_notifier" {
  # TODO: Use git link
  source        = "./modules/ecr"
  is_enabled    = var.notifier_enabled
  software_name = "${var.app_name}-notifier"
  name_prefix   = "${var.app_env}-${var.app_name}"

  repository_name     = "${local.repo_prefix}/notifier"
  scan_images_on_push = true
  kms_arn             = module.kms.key_arn
  max_image_count     = var.ecr_max_image_count

  # principals_readonly_access = [module.lambda_function_container_image.this_lambda_function_arn]

  tags = var.tags
}
