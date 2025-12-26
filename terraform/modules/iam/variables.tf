# ========================================
# IAM Module Variables
# ========================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, stage, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_vpc_access" {
  description = "Enable VPC access for Lambda"
  type        = bool
  default     = false
}

variable "custom_policy_statements" {
  description = "Custom policy statements for Lambda"
  type        = list(any)
  default     = []
}

variable "enable_s3_access" {
  description = "Enable S3 access for Lambda"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "S3 bucket name for Lambda access"
  type        = string
  default     = ""
}

variable "enable_secrets_manager" {
  description = "Enable Secrets Manager access for Lambda"
  type        = bool
  default     = false
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager ARNs to grant access to"
  type        = list(string)
  default     = []
}
