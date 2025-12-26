# ========================================
# Terraform Outputs
# ========================================

# Lambda Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "lambda_function_url" {
  description = "Lambda Function URL (if enabled)"
  value       = module.lambda.function_url
}

output "lambda_log_group" {
  description = "CloudWatch log group for Lambda"
  value       = module.lambda.log_group_name
}

# API Gateway Outputs
output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = module.api_gateway.api_id
}

output "api_gateway_endpoint" {
  description = "Base URL of the API Gateway"
  value       = module.api_gateway.api_endpoint
}

output "api_gateway_stage" {
  description = "API Gateway stage name"
  value       = module.api_gateway.stage_name
}

output "api_gateway_invoke_url" {
  description = "Full invoke URL for the API Gateway"
  value       = "${module.api_gateway.api_endpoint}/"
}

# Custom Domain Outputs (if configured)
output "custom_domain_name" {
  description = "Custom domain name (if configured)"
  value       = module.api_gateway.custom_domain_name
}

output "custom_domain_cloudfront_domain" {
  description = "CloudFront domain for custom domain (if configured)"
  value       = module.api_gateway.custom_domain_cloudfront_domain_name
}

# IAM Outputs
output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.iam.lambda_role_arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = module.iam.lambda_role_name
}

# ========================================
# Cron Lambda Outputs
# ========================================

output "lambda_cron_function_name" {
  description = "Name of the Cron Lambda function"
  value       = module.lambda_cron.function_name
}

output "lambda_cron_function_arn" {
  description = "ARN of the Cron Lambda function"
  value       = module.lambda_cron.function_arn
}

output "lambda_cron_log_group" {
  description = "CloudWatch log group for Cron Lambda"
  value       = module.lambda_cron.log_group_name
}

# ========================================
# EventBridge Outputs
# ========================================

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule for EMI cron"
  value       = module.eventbridge_emi.event_rule_name
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule for EMI cron"
  value       = module.eventbridge_emi.event_rule_arn
}

output "eventbridge_schedule" {
  description = "Schedule expression for EventBridge rule"
  value       = module.eventbridge_emi.event_rule_schedule
}

# Deployment Information
output "deployment_info" {
  description = "Deployment information"
  value = {
    project     = var.project_name
    environment = var.environment
    region      = var.aws_region
    timestamp   = timestamp()
  }
}

# Quick Start Command
output "test_command" {
  description = "Command to test the API Gateway endpoint"
  value       = "curl -X GET ${module.api_gateway.api_endpoint}/health"
}

# Environment Summary
output "environment_summary" {
  description = "Summary of deployed environment"
  value = {
    api_endpoint    = module.api_gateway.api_endpoint
    lambda_function = module.lambda.function_name
    lambda_cron     = module.lambda_cron.function_name
    cron_schedule   = module.eventbridge_emi.event_rule_schedule
    environment     = var.environment
    region          = var.aws_region
  }
}

# ========================================
# EMI Cron Information
# ========================================

output "emi_cron_info" {
  description = "EMI cron job configuration details"
  value = {
    lambda_function = module.lambda_cron.function_name
    schedule        = module.eventbridge_emi.event_rule_schedule
    description     = "Runs daily at 10:00 AM IST (4:30 AM UTC)"
    tasks           = "processOverdueEmis, sendPaymentReminders"
    log_group       = module.lambda_cron.log_group_name
  }
}
