#====================================================
# General
#====================================================

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

#====================================================
# Lambda
#====================================================

variable "scanner_version_file_path" {
    description = "Container image tag for Virus Scanner Lambda source code"
    type        = string
    default     = "../../services/scanner/version.json"
}

variable "scanner_enabled" {
    description = "Whether to deploy scanner lambda"
    type        = bool
    default     = true
}

variable "notifier_version_file_path" {
    description = "Container image tag for Slack notification Lambda source code"
    type        = string
    default     = "../../services/notifier/version.json"
}

variable "notifier_enabled" {
    description = "Whether to deploy notifier lambda"
    type        = bool
    default     = true
}

#====================================================
# S3
#====================================================

variable "s3_scan_bucket_name" {
  description = "Name of S3 bucket/s to be montiored for upload events"
  type        = string
  default     = ""
}

#====================================================
# VPC
#====================================================

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

#====================================================
# ECR
#====================================================

variable "ecr_max_image_count" {
    type        = number
    description = "How many Docker Image versions AWS ECR will store"
    default     = 20
}

#====================================================
# Cloud Watch
#====================================================

variable "cw_update_clamav_db_sched_expression" {
    type        = string
    description = "Schedule expression config for ClamAV database updater"
    default     = "rate(1 day)"
}

#====================================================
# Appconfig
#====================================================

variable "appconfig_hosted_config" {
  description = "Whether to enabled hosted config (as opposed to s3 or param store hosted)"
  type        = bool
  default     = true
}

variable "appconfig_hosted_config_env" {
  description = "Appconfig environment"
  type        = map(any)
}


variable "appconfig_hosted_config_content_type" {
  description = "Format of the config"
  type        = string
  default     = "application/json"
}

variable "appconfig_hosted_config_content_path" {
  description = "Path to the json config file"
  type        = string
  default     = "../../services/service_config.json"
}


