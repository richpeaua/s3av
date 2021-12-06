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
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

#====================================================
# Module
#====================================================
variable "deletion_window_in_days" {
  type        = number
  default     = 10
  description = "Duration in days after which the key is deleted after destruction of the resource"
}

variable "enable_key_rotation" {
  type        = bool
  default     = true
  description = "Specifies whether key rotation is enabled"
}

variable "description" {
  type        = string
  default     = ""
  description = "The description of the key as viewed in AWS console"
}

variable "policy" {
  type        = string
  default     = ""
  description = "A valid KMS policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy."
}
