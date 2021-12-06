locals {
  principals_readonly_access_empty = length(var.principals_readonly_access) > 0 ? false : true
  principals_full_access_empty     = length(var.principals_full_access) > 0 ? false : true
  ecr_needs_policy                 = length(var.principals_full_access) + length(var.principals_readonly_access) > 0 ? true : false
}


# TODO: use string
data "aws_iam_policy_document" "empty" {
  count = var.is_enabled ? 1 : 0
}

data "aws_iam_policy_document" "readonly_access" {
  count = var.is_enabled ? 1 : 0

  statement {
    sid    = "ECRReadonlyAccess"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = var.principals_readonly_access
    }

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
    ]
  }
}

data "aws_iam_policy_document" "full_access" {
  count = var.is_enabled ? 1 : 0

  statement {
    sid    = "ECRFullAccess"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = var.principals_full_access
    }

    actions = ["ecr:*"]
  }
}

data "aws_iam_policy_document" "this" {
  count         = var.is_enabled ? 1 : 0
  source_json   = local.principals_readonly_access_empty ? join("", [data.aws_iam_policy_document.empty[0].json]) : join("", [data.aws_iam_policy_document.readonly_access[0].json])
  override_json = local.principals_full_access_empty ? join("", [data.aws_iam_policy_document.empty[0].json]) : join("", [data.aws_iam_policy_document.full_access[0].json])
}

resource "aws_ecr_repository_policy" "this" {
  count      = var.is_enabled && local.ecr_needs_policy ? 1 : 0
  repository = aws_ecr_repository.this[0].name
  policy     = join("", data.aws_iam_policy_document.this.*.json)
}
