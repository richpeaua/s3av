module "kms" {
  source     = "./modules/kms"
  is_enabled = var.scanner_enabled

  description = "S3AV KMS key"

  name_prefix   = var.app_env
  software_name = var.app_name
  tags          = var.tags
}
