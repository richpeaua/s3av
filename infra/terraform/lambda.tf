locals {
  # These locals allow for the invdividual deployment of the lambda functions 
  # - e.g if you only need the scanner and not any of the other.
  # without these locals, the TF apply will fail if not all functions are enabled
  scanner_img_version                  = lookup(jsondecode(file(var.scanner_version_file_path)), "version", "0.01")
  scanner_s3_policy                    = length(data.aws_iam_policy_document.lambda_scanner_s3) > 0 ? data.aws_iam_policy_document.lambda_scanner_s3[0].json : ""
  scanner_notifier_sns_policy          = length(data.aws_iam_policy_document.lambda_scanner_to_notifier_sns) > 0 ? data.aws_iam_policy_document.lambda_scanner_to_notifier_sns[0].json : ""
  scanner_x_account_assume_role_policy = length(data.aws_iam_policy_document.lambda_scanner_cross_account_assume_role) > 0 ? data.aws_iam_policy_document.lambda_scanner_cross_account_assume_role[0].json : ""
  scanner_appconfig_policy             = length(data.aws_iam_policy_document.lambda_scanner_appconfig) > 0 ? data.aws_iam_policy_document.lambda_scanner_appconfig[0].json : ""

  notifier_img_version      = lookup(jsondecode(file(var.notifier_version_file_path)), "version", "0.01")
  notifier_asm_policy       = length(data.aws_iam_policy_document.lambda_notifier_to_asm) > 0 ? data.aws_iam_policy_document.lambda_notifier_to_asm[0].json : ""
  notifier_kms_policy       = length(data.aws_iam_policy_document.lambda_notifier_to_kms) > 0 ? data.aws_iam_policy_document.lambda_notifier_to_kms[0].json : ""
  notifier_appconfig_policy = length(data.aws_iam_policy_document.lambda_notifier_appconfig) > 0 ? data.aws_iam_policy_document.lambda_notifier_appconfig[0].json : ""
  notifier_sns_topic_arn    = length(aws_sns_topic.notification) > 0 ? aws_sns_topic.notification[0].arn : ""
  notifier_ams_secret_name  = length(aws_secretsmanager_secret.s3av) > 0 ? aws_secretsmanager_secret.s3av[0].name : ""
}

#====================================================
# Scanner Lambda
#====================================================
module "lambda_scanner" {
  source = "terraform-aws-modules/lambda/aws"
  # version = "1.28.0"

  create = var.scanner_enabled

  function_name = "${var.app_env}-${var.app_name}-scanner"
  description   = "AWS S3 Virus Scanner"

  memory_size                             = 512
  timeout                                 = 90
  create_current_version_allowed_triggers = false

  # Container image settings
  create_package = false
  image_uri      = "${module.ecr_scanner.repository_url}:${local.scanner_img_version}"
  package_type   = "Image"

  # Creating Lambda inside VPC
  # vpc_subnet_ids         = module.vpc.private_subnets
  # vpc_security_group_ids = [aws_security_group.lambda_scanner[0].id]
  # attach_network_policy  = true

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
    S3ObjectUpload = {
      service    = "s3"
      source_arn = module.s3_bucket.s3_bucket_arn
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
    APPCONFIG_ENV = var.app_env
  }

  tags = var.tags

  depends_on = [module.ecr_scanner, module.s3_bucket]
}


# ====================================================
# Notify Lambda
# ====================================================
module "lambda_notifier" {
  source = "terraform-aws-modules/lambda/aws"
  # version = "1.28.0"

  create = var.notifier_enabled

  function_name = "${var.app_env}-${var.app_name}-notifier"
  description   = "AWS S3 Virus Scanner - Slack Notification"

  memory_size                             = 512
  timeout                                 = 10
  create_current_version_allowed_triggers = false

  # Container image settings
  create_package = false
  image_uri      = "${module.ecr_notifier.repository_url}:${local.notifier_img_version}"
  package_type   = "Image"


  # Creating Lambda inside VPC
  # vpc_subnet_ids         = module.vpc.private_subnets
  # vpc_security_group_ids = [aws_security_group.lambda_scanner[0].id]
  # attach_network_policy  = true

  # Additional policies
  attach_policy_jsons    = true
  number_of_policy_jsons = 3
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
    APPCONFIG_ENV = var.app_env
  }

  tags = var.tags

  depends_on = [module.ecr_notifier]
}
