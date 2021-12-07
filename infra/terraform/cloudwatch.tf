#====================================================
# ClamAV database updater event
#====================================================

resource "aws_cloudwatch_event_rule" "update_vs_db" {
  count               = var.scanner_enabled ? 1 : 0
  name                = "${var.app_env}-${var.app_name}-update-antivirus-db"
  description         = "Trigger Virus Scanner Lambda to update the ClamAV database"
  schedule_expression = var.cw_update_clamav_db_sched_expression
}

# Event target: Associates a rule with a function to run
resource "aws_cloudwatch_event_target" "update_vs_db" {
  count     = var.scanner_enabled ? 1 : 0
  target_id = "update-antivirus-db"
  rule      = aws_cloudwatch_event_rule.update_vs_db[0].name
  arn       = module.lambda_scanner.lambda_function_arn
  input     = "{\"command\":\"update\"}"
}
