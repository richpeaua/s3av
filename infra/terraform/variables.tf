#====================================================
# General
#====================================================

variable "tf_state_bucket" {
  description = "AWS S3 bucket where the TF state will be saved"
  type        = string
}

variable "tf_state_key" {
  description = "Name of tf state file stored in tf_state_bucket"
  type        = string
}

variable "lambda_scanner_enabled" {
    description = "Whether to deploy scanner lambda"
    type = bool
    default = false
}

variable "lambda_notifier_enabled" {
    description = "Whether to deploy notifier lambda"
    type = bool
    default = false
}

variable "lambda_dispatcher_enabled" {
    description = "Whether to deploy dispatcher lambda"
    type = bool
    default = false
}

variable "lambda_scanner_image_tag" {
    description = "Container image tag for Virus Scanner Lambda source code"
    type        = string
}

variable "lambda_dispatcher_image_tag" {
    description = "Container image tag for Events Dispatcher Lambda source code"
    type        = string
}

variable "lambda_notifier_image_tag" {
    description = "Container image tag for Slack notification Lambda source code"
    type        = string
}

variable "app_env" {
    description = "Application Environment"
    type        = string
    default     = "dev"
}

variable "app_name" {
    description = "Software name"
    type        = string
    default     = "s3av"
}

variable "tags" {
    description = "A map of tags to add to all resources"
    type        = map(string)
    default     = { TerraformManaged = "true" }
}

variable "aws_account_id" {
    description = "AWS account ID which will be used to deploy resources"
    type        = string
}

variable "aws_region" {
    description = "AWS region which will be used to deploy resources"
    type        = string
    default     = "us-east-1"
}

variable "vpc_private_subnets" {
    description = "AWS vpc private subnet where the scanner lambdas will be attached to"
    type        = list(string)
}

variable "vpc_public_subnets" {
    description = "AWS vpc public subnet"
    type        = list(string)
}

variable "vpc_enable_nat_gateway" {
    description = "Whether to enable the creation of a NAT gateway"
    type        = bool
    default     = true
}

variable "vpc_single_nat_gateway" {
    description = "Whether to enable the created NAT gateway will be single NAT"
    type        = bool
    default     = true
}

variable "vpc_enable_s3_endpoint" {
    description = "Whether to enable S3 vpc endpoint for internal, private s3 communication"
    type        = bool
    default     = true
}

variable "vpc_cidr" {
    description = "AWS vpc CIDR"
    type = string
}

variable "vpc_azs" {
    description = "AWS vpc subnet availability zones"
    type        = list(string)
}

variable "vpc_create" {
    description = "whether to create vpc"
    type        = bool
    default     = true
}

variable "ecr_max_image_count" {
    type        = number
    description = "How many Docker Image versions AWS ECR will store"
    default     = 20
}

variable "cloudtrail_log_group_name" {
    type        = string
    description = "CloudTrail log group name in CloudWatch"
    default     = ""
}

variable "cloudtrail_log_filter_pattern" {
    type        = string
    description = "CloudTrail log group name in CloudWatch"
    default     = ""
}

variable "update_clamav_db_schedule_expression" {
    type        = string
    description = "Schedule expression config for ClamAV database updater"
    default     = "rate(1 day)"
}

variable "appconfig_hosted_config" {
  description = "description"
  type        = string
  default     = ""
  description = "description"
}
