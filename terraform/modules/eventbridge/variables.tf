# =====================================================================
# EventBridge Module Variables
# =====================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, stage, prod)"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to trigger"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to trigger"
  type        = string
}

variable "schedule_expression" {
  description = "Cron or rate expression for EventBridge schedule"
  type        = string
  default     = "cron(30 4 * * ? *)" # 10:00 AM IST = 4:30 AM UTC
  
  # Common schedule examples:
  # - "cron(30 4 * * ? *)"      = Every day at 10:00 AM IST
  # - "cron(0 0 * * ? *)"       = Every day at 5:30 AM IST (midnight UTC)
  # - "rate(1 hour)"            = Every hour
  # - "rate(30 minutes)"        = Every 30 minutes
  # - "cron(0 10 ? * MON *)"    = Every Monday at 3:30 PM IST (10 AM UTC)
  # - "cron(0 0 1 * ? *)"       = First day of every month at 5:30 AM IST
}

variable "tags" {
  description = "Tags to apply to EventBridge resources"
  type        = map(string)
  default     = {}
}
