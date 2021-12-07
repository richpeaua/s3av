#====================================================
# Dispatcher Lambda
#====================================================

data "aws_iam_policy_document" "lambda_dispatcher_appconfig" {
    count = var.lambda_dispatcher_enabled ? 1 : 0
    statement {
        sid    = "AllowAppConfigGetConfig"
        effect = "Allow"
        actions = ["appconfig:GetConfiguration"]
        resources = [ 
            module.appconfig.application_arn, 
            module.appconfig.environments[var.app_env].arn, 
            module.appconfig.hosted_configuration_version_arn
        ]
    }
}

#====================================================
# Scanner Lambda
#====================================================
data "aws_iam_policy_document" "lambda_scanner_s3" {
    count = var.scanner_enabled ? 1 : 0
    statement {
        sid     = "AllowS3ReadAccess"
        effect  = "Allow"
        actions = [
            "s3:ListBucket",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:HeadObject",
            "s3:GetObjectTagging",
            "s3:PutObjectTagging"
        ]
        resources = [module.s3_bucket.s3_bucket_arn]
    }
}

data "aws_iam_policy_document" "lambda_scanner_to_notifier_sns" {
    count = var.notifier_enabled ? 1 : 0
    statement {
        sid     = "AllowSNSPublish"
        effect  = "Allow"
        actions = [
            "sns:Publish"
        ]
        resources = [aws_sns_topic.notification[0].arn]
    }
}

data "aws_iam_policy_document" "lambda_scanner_cross_account_assume_role" {
    count = var.scanner_enabled ? 1 : 0
    statement {
        sid     = "AllowAssumeRole"
        effect  = "Allow"
        actions = [ "sts:AssumeRole"]
        resources = ["arn:aws:iam::*:role/s3av-cross-account-role"]
    }
}


data "aws_iam_policy_document" "lambda_scanner_appconfig" {
    count = var.scanner_enabled ? 1 : 0
    statement {
        sid       = "AllowAppConfigGetConfig"
        effect    = "Allow"
        actions   = ["appconfig:GetConfiguration"]
        resources = [ 
            module.appconfig.application_arn, 
            module.appconfig.environments[var.app_env].arn, 
            module.appconfig.hosted_configuration_version_arn
        ]
    }
}

#====================================================
# Notify Lambda
#====================================================

data "aws_iam_policy_document" "lambda_notifier_to_asm" {
    count = var.notifier_enabled ? 1 : 0
    statement {
        sid       = "AllowASMGetSecretValue"
        effect    = "Allow"
        actions   = ["secretsmanager:GetSecretValue"]
        resources = [aws_secretsmanager_secret.s3av[0].arn]
    }
}

data "aws_iam_policy_document" "lambda_notifier_to_kms" {
    count = var.notifier_enabled ? 1 : 0
    statement {
        sid     = "AllowKMSDecrypt"
        effect  = "Allow"
        actions = ["kms:Decrypt"]
        resources = [module.kms.key_arn]
    }
}

data "aws_iam_policy_document" "lambda_notifier_appconfig" {
  count = var.notifier_enabled ? 1 : 0
  statement {
    sid    = "AllowAppConfigGetConfig"
    effect = "Allow"
    actions = ["appconfig:GetConfiguration"]
    resources = [ 
        module.appconfig.application_arn, 
        module.appconfig.environments[var.app_env].arn, 
        module.appconfig.hosted_configuration_version_arn
    ]
  }
}
