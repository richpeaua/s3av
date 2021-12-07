resource "aws_secretsmanager_secret" "s3av" {
  count                   = var.scanner_enabled ? 1 : 0
  name                    = "${var.app_env}-${var.app_name}-asm"
  description             = "S3 Virus Scanner Secrets"
  recovery_window_in_days = 30
  kms_key_id              = module.kms.key_arn
  tags                    = var.tags
}
