# ========================================
# API Gateway Module Variables
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

# API Gateway Configuration
variable "endpoint_type" {
  description = "API Gateway endpoint type (REGIONAL, EDGE, PRIVATE)"
  type        = string
  default     = "REGIONAL"
}

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "api"
}

variable "authorization_type" {
  description = "Authorization type for API Gateway methods (NONE, AWS_IAM, CUSTOM, COGNITO_USER_POOLS)"
  type        = string
  default     = "NONE"
}

# Lambda Integration
variable "lambda_invoke_arn" {
  description = "Lambda function invoke ARN for API Gateway integration"
  type        = string
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "logging_level" {
  description = "Logging level (OFF, ERROR, INFO)"
  type        = string
  default     = "INFO"
}

variable "enable_data_trace" {
  description = "Enable data trace logging"
  type        = bool
  default     = false
}

# Monitoring
variable "enable_metrics" {
  description = "Enable CloudWatch metrics"
  type        = bool
  default     = true
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = false
}

# Throttling
variable "throttling_burst_limit" {
  description = "API Gateway throttling burst limit"
  type        = number
  default     = 5000
}

variable "throttling_rate_limit" {
  description = "API Gateway throttling rate limit"
  type        = number
  default     = 10000
}

# Custom Domain
variable "custom_domain_name" {
  description = "Custom domain name for API Gateway"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain"
  type        = string
  default     = ""
}

variable "base_path" {
  description = "Base path mapping for custom domain"
  type        = string
  default     = ""
}

# Usage Plan
variable "create_usage_plan" {
  description = "Create API Gateway usage plan"
  type        = bool
  default     = false
}

variable "quota_limit" {
  description = "Maximum number of requests per quota period"
  type        = number
  default     = 10000
}

variable "quota_offset" {
  description = "Number of requests subtracted from the quota limit"
  type        = number
  default     = 0
}

variable "quota_period" {
  description = "Quota period (DAY, WEEK, MONTH)"
  type        = string
  default     = "MONTH"
}

# API Key
variable "create_api_key" {
  description = "Create API Gateway API key"
  type        = bool
  default     = false
}
