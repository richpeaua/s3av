#====================================================
# CloudTrail log subscription
#====================================================

module "cloudtrail_log_subscription" {
  source = "./modules/cloudwatch-subscription"


  is_enabled = var.lambda_dispatcher_enabled

  name_prefix     = var.app_env
  software_name   = var.app_name
  log_group_name  = var.cloudtrail_log_group_name
  filter_pattern  = var.cloudtrail_log_filter_pattern
  destination_arn = module.lambda_dispatcher.lambda_function_arn
  distribution    = "ByLogStream"

  depends_on = [module.lambda_dispatcher]
}

#====================================================
# ClamAV database updater event
#====================================================

resource "aws_cloudwatch_event_rule" "update_vs_db" {
  count               = var.lambda_scanner_enabled ? 1 : 0
  name                = "${var.app_env}-${var.app_name}-update-antivirus-db"
  description         = "Trigger Virus Scanner Lambda to update the ClamAV database"
  schedule_expression = var.update_clamav_db_schedule_expression
}

# Event target: Associates a rule with a function to run
resource "aws_cloudwatch_event_target" "update_vs_db" {
  count     = var.lambda_scanner_enabled ? 1 : 0
  target_id = "update-antivirus-db"
  rule      = aws_cloudwatch_event_rule.update_vs_db[0].name
  arn       = module.lambda_scanner.lambda_function_arn
  input     = "{\"command\":\"update\"}"
}
