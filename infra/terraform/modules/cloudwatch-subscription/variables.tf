#====================================================
# General
#====================================================

variable "is_enabled" {
  default = false
}

variable "name_prefix" {
  description = "Name to be used on all resources as prefix. Is most cases project name or terraform workspace. eg corporate, sandbox_poc"
  default     = "sandbox"
  type        = string
}

variable "software_name" {
  description = "Software name"
  default     = "splunk"
  type        = string
}

#====================================================
# Module
#====================================================

variable "role_arn" {
  type        = string
  default     = ""
  description = "The ARN of an IAM role that grants Amazon CloudWatch Logs permissions to deliver ingested log events to the destination"
}

variable "log_group_name" {
  type        = string
  description = "The name of the log group to associate the subscription filter with"
}

variable "filter_pattern" {
  type        = string
  description = "A valid CloudWatch Logs filter pattern for subscribing to a filtered stream of log events."
}

variable "destination_arn" {
  type        = string
  description = "The ARN of the destination to deliver matching log events to. Kinesis stream or Lambda function ARN."
}

variable "distribution" {
  type        = string
  default     = ""
  description = "The method used to distribute log data to the destination."
}


