# ========================================
# Lambda Module Outputs
# ========================================

output "function_name" {
  description = "Name of the Lambda function"
  value       = local.lambda.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = local.lambda.arn
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = local.lambda.invoke_arn
}

output "function_version" {
  description = "Latest published version of the Lambda function"
  value       = local.lambda.version
}

output "function_qualified_arn" {
  description = "Qualified ARN of the Lambda function"
  value       = local.lambda.qualified_arn
}

output "function_url" {
  description = "Lambda Function URL (if enabled)"
  value       = var.enable_function_url ? aws_lambda_function_url.main[0].function_url : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_log_group.arn
}

output "alias_arn" {
  description = "ARN of the Lambda alias (if created)"
  value       = var.create_alias ? aws_lambda_alias.main[0].arn : null
}

output "alias_name" {
  description = "Name of the Lambda alias (if created)"
  value       = var.create_alias ? aws_lambda_alias.main[0].name : null
}
