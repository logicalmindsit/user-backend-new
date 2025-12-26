# =====================================================================
# EventBridge Module Outputs
# =====================================================================

output "event_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.emi_cron.arn
}

output "event_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.emi_cron.name
}

output "event_rule_schedule" {
  description = "Schedule expression of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.emi_cron.schedule_expression
}
