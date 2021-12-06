resource "aws_kms_key" "this" {
  count                   = var.is_enabled ? 1 : 0
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  policy                  = var.policy
  description             = var.description

  tags = merge({
    "Name" = "${var.name_prefix}-${var.software_name}"
    },
    var.tags
  )
}

resource "aws_kms_alias" "this" {
  count         = var.is_enabled ? 1 : 0
  name          = "alias/${var.name_prefix}/${var.software_name}"
  target_key_id = aws_kms_key.this[0].key_id
}
