module "kms" {
  source     = "./modules/kms"
  is_enabled = var.lambda_scanner_enabled

  description = "S3 Virus scanner KMS key"

  name_prefix   = var.app_env
  software_name = var.app_name
  tags          = var.tags
}
