# =====================================================================
# AWS EventBridge Module - Scheduled Events for Lambda
# =====================================================================
# This module creates EventBridge (CloudWatch Events) rules to trigger
# Lambda functions on a schedule (similar to cron jobs).
#
# Purpose: Schedule EMI email reminders to run daily at 10:00 AM IST
# =====================================================================

# ---------------------------------------------------------------------
# EventBridge Rule - EMI Cron Job Scheduler
# ---------------------------------------------------------------------
# This rule triggers the Lambda function on a cron schedule
# Cron expression: cron(30 4 * * ? *)
# Explanation: 4:30 AM UTC = 10:00 AM IST (UTC+5:30)
# ---------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "emi_cron" {
  name                = "${var.project_name}-${var.environment}-emi-cron"
  description         = "Trigger EMI email reminders daily at 10:00 AM IST"
  schedule_expression = var.schedule_expression
  
  tags = var.tags
}

# ---------------------------------------------------------------------
# EventBridge Target - Link Rule to Lambda Function
# ---------------------------------------------------------------------
# This connects the EventBridge rule to the Lambda function
# When the rule triggers, it invokes the specified Lambda function
# ---------------------------------------------------------------------
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.emi_cron.name
  target_id = "EmiCronLambda"
  arn       = var.lambda_function_arn
  
  # Optional: Pass custom input to Lambda (uncomment if needed)
  # input = jsonencode({
  #   type = "scheduled_emi_cron"
  # })
}

# ---------------------------------------------------------------------
# Lambda Permission - Allow EventBridge to Invoke Lambda
# ---------------------------------------------------------------------
# This grants EventBridge permission to invoke the Lambda function
# Without this, EventBridge cannot trigger the Lambda
# ---------------------------------------------------------------------
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.emi_cron.arn
}

# =====================================================================
# NOTE: Outputs are defined in outputs.tf to avoid duplication
# =====================================================================
