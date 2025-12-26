# ========================================
# API Gateway Module Outputs
# ========================================

output "api_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_arn" {
  description = "ARN of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.main.arn
}

output "api_execution_arn" {
  description = "Execution ARN of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "api_endpoint" {
  description = "Base URL of the API Gateway stage"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.main.stage_name
}

output "stage_arn" {
  description = "ARN of the API Gateway stage"
  value       = aws_api_gateway_stage.main.arn
}

output "deployment_id" {
  description = "ID of the API Gateway deployment"
  value       = aws_api_gateway_deployment.main.id
}

output "custom_domain_name" {
  description = "Custom domain name (if configured)"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.main[0].domain_name : null
}

output "custom_domain_cloudfront_domain_name" {
  description = "CloudFront domain name for custom domain (if configured)"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.main[0].cloudfront_domain_name : null
}

output "custom_domain_cloudfront_zone_id" {
  description = "CloudFront zone ID for custom domain (if configured)"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.main[0].cloudfront_zone_id : null
}

output "api_key_id" {
  description = "ID of the API Gateway API key (if created)"
  value       = var.create_api_key ? aws_api_gateway_api_key.main[0].id : null
}

output "api_key_value" {
  description = "Value of the API Gateway API key (if created)"
  value       = var.create_api_key ? aws_api_gateway_api_key.main[0].value : null
  sensitive   = true
}

output "usage_plan_id" {
  description = "ID of the API Gateway usage plan (if created)"
  value       = var.create_usage_plan ? aws_api_gateway_usage_plan.main[0].id : null
}
