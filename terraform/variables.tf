# ========================================
# Root Terraform Variables
# ========================================

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "schoolemy"
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

# Lambda Configuration
variable "lambda_zip_file" {
  description = "Path to Lambda deployment package"
  type        = string
  default     = "../lambda.zip"
}

variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
  default     = "handler.handler"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

# Environment Variables for Lambda
variable "mongo_url" {
  description = "MongoDB connection URL"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

variable "email_admin" {
  description = "Admin email for notifications"
  type        = string
  default     = ""
}

variable "email_pass" {
  description = "Email password for SMTP"
  type        = string
  sensitive   = true
  default     = ""
}

variable "twilio_account_sid" {
  description = "Twilio account SID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "twilio_auth_token" {
  description = "Twilio auth token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "twilio_phone_number" {
  description = "Twilio phone number"
  type        = string
  default     = ""
}

variable "twilio_whatsapp_number" {
  description = "Twilio WhatsApp number"
  type        = string
  default     = ""
}

variable "razorpay_key_id" {
  description = "Razorpay key ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "razorpay_key_secret" {
  description = "Razorpay key secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_bucket_name" {
  description = "AWS S3 bucket name"
  type        = string
  default     = ""
}

variable "node_env" {
  description = "Node environment (development, production, testing)"
  type        = string
  default     = "production"
}

# API Gateway Configuration
variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "api"
}

variable "enable_api_gateway_logging" {
  description = "Enable API Gateway access logging"
  type        = bool
  default     = true
}

variable "api_gateway_throttling_burst_limit" {
  description = "API Gateway throttling burst limit"
  type        = number
  default     = 5000
}

variable "api_gateway_throttling_rate_limit" {
  description = "API Gateway throttling rate limit"
  type        = number
  default     = 10000
}

# Custom Domain (Optional)
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

# IAM Configuration
variable "enable_s3_access" {
  description = "Enable S3 access for Lambda"
  type        = bool
  default     = true
}

variable "enable_vpc_access" {
  description = "Enable VPC access for Lambda"
  type        = bool
  default     = false
}

# Monitoring
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = false
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
