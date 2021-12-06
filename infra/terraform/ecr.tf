locals {
  repo_prefix = "lambda/${var.app_name}"
}

#====================================================
# Dispatcher ECR Repository
#====================================================
module "ecr_dispatcher" {
  source        = "modules/ecr"
  is_enabled    = var.lambda_dispatcher_enabled
  software_name = var.app_name
  name_prefix   = "${var.app_env}-${var.app_name}"

  repository_name     = "${local.repo_prefix}/dispatcher"
  scan_images_on_push = true
  kms_arn             = module.kms.key_arn
  max_image_count     = var.ecr_max_image_count

  # principals_readonly_access = [module.lambda_function_container_image.this_lambda_function_arn]

  tags = var.tags
}

#====================================================
# Scanner ECR Repository
#====================================================
module "ecr_scanner" {
  source        = "module/ecr"
  is_enabled    = var.lambda_scanner_enabled
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
  source        = "module/ecr"
  is_enabled    = var.lambda_notifier_enabled
  software_name = "${var.app_name}-notifier"
  name_prefix   = "${var.app_env}-${var.app_name}"

  repository_name     = "${local.repo_prefix}/notifier"
  scan_images_on_push = true
  kms_arn             = module.kms.key_arn
  max_image_count     = var.ecr_max_image_count

  # principals_readonly_access = [module.lambda_function_container_image.this_lambda_function_arn]

  tags = var.tags
}
