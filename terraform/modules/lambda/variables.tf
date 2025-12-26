# ========================================
# Lambda Module Variables
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

# Lambda Function Configuration
variable "zip_file_path" {
  description = "Path to the Lambda deployment package (zip file)"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "handler.handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for Lambda function"
  type        = map(string)
  default     = {}
}

# CloudWatch Logs
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

# VPC Configuration
variable "vpc_config" {
  description = "VPC configuration for Lambda"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

# Dead Letter Queue
variable "dead_letter_config_target_arn" {
  description = "ARN of SQS or SNS for dead letter queue"
  type        = string
  default     = ""
}

# Lambda Function URL
variable "enable_function_url" {
  description = "Enable Lambda Function URL"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "Authorization type for Function URL (NONE or AWS_IAM)"
  type        = string
  default     = "NONE"
}

variable "function_url_cors" {
  description = "CORS configuration for Function URL"
  type = object({
    allow_credentials = bool
    allow_origins     = list(string)
    allow_methods     = list(string)
    allow_headers     = list(string)
    expose_headers    = list(string)
    max_age           = number
  })
  default = {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["*"]
    expose_headers    = []
    max_age           = 0
  }
}

# Lambda Alias
variable "create_alias" {
  description = "Create Lambda alias"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Name of the Lambda alias"
  type        = string
  default     = "live"
}

variable "alias_function_version" {
  description = "Lambda function version for alias"
  type        = string
  default     = "$LATEST"
}

# API Gateway Integration
variable "allow_api_gateway_invoke" {
  description = "Allow API Gateway to invoke Lambda"
  type        = bool
  default     = true
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permission"
  type        = string
  default     = ""
}

# Concurrency
variable "provisioned_concurrent_executions" {
  description = "Amount of provisioned concurrency to allocate"
  type        = number
  default     = 0
}

variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent executions for this lambda function"
  type        = number
  default     = -1
}

# Optional: Upload the zip to S3 and reference it (useful when zip > API upload limit)
variable "upload_to_s3" {
  description = "If true, upload the zip to S3 and point Lambda at the S3 object instead of using local filename"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "S3 bucket to upload lambda zip to (required if upload_to_s3 is true)"
  type        = string
  default     = ""
}

variable "s3_key" {
  description = "Optional S3 key for the uploaded zip (defaults to <project>-<env>.zip)"
  type        = string
  default     = ""
}
