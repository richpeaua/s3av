locals {
  # These locals allow for the invdividual deployment of the lambda functions 
  # - e.g if you only need the scanner and not any of the other.
  # without these locals, the TF apply will fail if not all functions are enabled
  dispatcher_sns_policy       = length(data.aws_iam_policy_document.lambda_dispatcher_to_sns) > 0 ? data.aws_iam_policy_document.lambda_dispatcher_to_sns[0].json : ""
  dispatcher_appconfig_policy = length(data.aws_iam_policy_document.lambda_dispatcher_appconfig) > 0 ? data.aws_iam_policy_document.lambda_dispatcher_appconfig[0].json : ""
  dispatcher_sg_policy        = length(aws_security_group.lambda_dispatcher) > 0 ? aws_security_group.lambda_dispatcher[0].id : ""

  scanner_s3_policy                    = length(data.aws_iam_policy_document.lambda_scanner_s3) > 0 ? data.aws_iam_policy_document.lambda_scanner_s3[0].json : ""
  scanner_notifier_sns_policy            = length(data.aws_iam_policy_document.lambda_scanner_to_notifier_sns) > 0 ? data.aws_iam_policy_document.lambda_scanner_to_notifier_sns[0].json : ""
  scanner_x_account_assume_role_policy = length(data.aws_iam_policy_document.lambda_scanner_cross_account_assume_role) > 0 ? data.aws_iam_policy_document.lambda_scanner_cross_account_assume_role[0].json : ""
  scanner_appconfig_policy             = length(data.aws_iam_policy_document.lambda_scanner_appconfig) > 0 ? data.aws_iam_policy_document.lambda_scanner_appconfig[0].json : ""

  notifier_asm_policy       = length(data.aws_iam_policy_document.lambda_notifier_to_asm) > 0 ? data.aws_iam_policy_document.lambda_notifier_to_asm[0].json : ""
  notifier_kms_policy       = length(data.aws_iam_policy_document.lambda_notifier_to_kms) > 0 ? data.aws_iam_policy_document.lambda_notifier_to_kms[0].json : ""
  notifier_appconfig_policy = length(data.aws_iam_policy_document.lambda_notifier_appconfig) > 0 ? data.aws_iam_policy_document.lambda_notifier_appconfig[0].json : ""
  notifier_sns_topic_arn    = length(aws_sns_topic.notification) > 0 ? aws_sns_topic.notification[0].arn : ""
  notifier_ams_secret_name  = length(aws_secretsmanager_secret.this) > 0 ? aws_secretsmanager_secret.this[0].name : ""
}


#====================================================
# Dispatcher Lambda
#====================================================
module "lambda_dispatcher" {
  source = "terraform-aws-modules/lambda/aws"
  # version = "1.28.0"

  create = var.lambda_dispatcher_enabled

  function_name = "${var.app_env}-${var.app_name}-dispatcher"
  description   = "AWS S3 Virus Scanner - Event Dispatcher"

  timeout                                 = 10
  create_current_version_allowed_triggers = false

  # Container image settings
  create_package = false
  image_uri      = "${module.ecr_dispatcher.repository_url}:${var.image_tag_dispatcher}"
  package_type   = "Image"


  # Creating Lambda inside VPC
  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [local.dispatcher_sg_policy]
  attach_network_policy  = true

  allowed_triggers = {
    CloudTrailLogs = {
      service    = "logs"
      source_arn = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:${var.cloudtrail_log_group_name}:*"
    }
  }

  # Additional policies
  attach_policy_jsons    = true
  number_of_policy_jsons = 2
  policy_jsons       = [
    local.dispatcher_sns_policy,
    local.dispatcher_appconfig_policy
  ]

  environment_variables = {
    SNS_TOPIC_ARN = aws_sns_topic.scan[0].arn
    APPCONFIG_APP = "${var.app_env}-${var.app_name}-appconfig"
    APPCONFIG_ENV = var.app_env
  }

  tags = var.tags

  depends_on = [aws_sns_topic.scan, module.ecr_dispatcher]
}

#====================================================
# Scanner Lambda
#====================================================
module "lambda_scanner" {
  source = "terraform-aws-modules/lambda/aws"
  # version = "1.28.0"

  create = var.lambda_scanner_enabled

  function_name = "${var.app_env}-${var.app_name}-scanner"
  description   = "AWS S3 Virus Scanner"

  memory_size                             = 2048
  timeout                                 = 90
  create_current_version_allowed_triggers = false
  reserved_concurrent_executions          = 20

  # Container image settings
  create_package = false
  image_uri      = "${module.ecr_scanner.repository_url}:${var.image_tag_scanner}"
  package_type   = "Image"


  # Creating Lambda inside VPC
  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.lambda_scanner[0].id]
  attach_network_policy  = true

  # EFS
  file_system_arn              = aws_efs_access_point.lambda[0].arn
  file_system_local_mount_path = "/mnt/data"

  # Additional policies
  attach_policy_jsons    = true
  number_of_policy_jsons = local.scanner_notifier_sns_policy != "" ? 4 : 3
  policy_jsons = [
    local.scanner_s3_policy,
    local.scanner_x_account_assume_role_policy,
    local.scanner_appconfig_policy,
    local.scanner_notifier_sns_policy
  ]

  # Lambda triggers
  allowed_triggers = {
    CloudTrailLogs = {
      service    = "sns"
      source_arn = aws_sns_topic.scan[0].arn
    },
    UpdateClamAVDatabase = {
      service    = "events"
      source_arn = aws_cloudwatch_event_rule.update_vs_db[0].arn
    },
  }

  # Env vars
  environment_variables = {
    AWS_ACCOUNT   = var.aws_account_id
    APPCONFIG_APP = "${var.app_env}-${var.app_name}-appconfig"
    APPCONFIG_ENV = var.appconfig_env
  }

  tags = var.tags

  depends_on = [aws_efs_mount_target.this, module.ecr_scanner]
}


# ====================================================
# Notify Lambda
# ====================================================
module "lambda_notifier" {
  source = "terraform-aws-modules/lambda/aws"
  # version = "1.28.0"

  create = var.lambda_notifier_enabled

  function_name = "${var.app_env}-${var.app_name}-notifier"
  description   = "AWS S3 Virus Scanner - Slack Notification"

  timeout                                 = 10
  create_current_version_allowed_triggers = false

  # Container image settings
  create_package = false
  image_uri      = "${module.ecr_notifier.repository_url}:${var.image_tag_notifier}"
  package_type   = "Image"


  # Creating Lambda inside VPC
  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.lambda_scanner[0].id]
  attach_network_policy  = true

  # Additional policies
  attach_policy_jsons    = true
  number_of_policy_jsons = 2
  policy_jsons = [
    local.notifier_asm_policy,
    local.notifier_kms_policy,
    local.notifier_appconfig_policy
  ]

  allowed_triggers = {
    CloudTrailLogs = {
      service    = "sns"
      source_arn = local.notifier_sns_topic_arn
    }
  }

  environment_variables = {
    ASM_SECRET_NAME = local.notifier_ams_secret_name
    APPCONFIG_APP = "${var.app_env}-${var.app_name}-appconfig"
    APPCONFIG_ENV = var.appconfig_env
  }

  tags = var.tags

  depends_on = [module.ecr_notifier]
}
