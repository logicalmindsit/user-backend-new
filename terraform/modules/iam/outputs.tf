# ========================================
# IAM Module Outputs
# ========================================

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.name
}

output "lambda_role_id" {
  description = "ID of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.id
}
