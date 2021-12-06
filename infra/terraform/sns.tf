#====================================================
# Scan SNS
#====================================================
resource "aws_sns_topic" "scan" {
  count = var.lambda_scanner_enabled ? 1 : 0
  name  = "${var.app_env}-${var.app_name}-scan"
  # kms_master_key_id = module.kms.key_arn
}

resource "aws_sns_topic_subscription" "scan_sns_to_scanner_lambda" {
  count = var.lambda_scanner_enabled ? 1 : 0

  topic_arn = aws_sns_topic.scan[0].arn
  protocol  = "lambda"
  endpoint  = module.lambda_scanner.lambda_function_arn
}


#====================================================
# Slack Notification SNS
#====================================================

resource "aws_sns_topic" "notification" {
  count = var.lambda_notifier_enabled ? 1 : 0
  name  = "${var.app_env}-${var.app_name}-notification"
  # kms_master_key_id = module.kms.key_arn
}

resource "aws_sns_topic_subscription" "notify_sns_to_notify_lambda" {
  count = var.lambda_notifier_enabled ? 1 : 0

  topic_arn = aws_sns_topic.notification[0].arn
  protocol  = "lambda"
  endpoint  = module.lambda_notify.lambda_function_arn
}
