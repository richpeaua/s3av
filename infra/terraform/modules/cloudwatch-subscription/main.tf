resource "aws_cloudwatch_log_subscription_filter" "this" {
  count           = var.is_enabled ? 1 : 0
  name            = "${var.name_prefix}"
  role_arn        = var.role_arn
  log_group_name  = var.log_group_name
  filter_pattern  = var.filter_pattern
  destination_arn = var.destination_arn
  distribution    = var.distribution
}
