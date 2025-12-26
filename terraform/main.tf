# ========================================
# Schoolemy Backend - AWS Lambda + API Gateway
# Production-Ready Terraform Configuration
# ========================================

locals {
  common_tags = merge(
    var.additional_tags,
    {
      Project     = var.project_name
      Environment = var.environment
    }
  )

  # Environment variables for Lambda function
  # ✅ FIXED: Removed AWS reserved environment variables
  # - AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY are automatically provided by Lambda
  # - Lambda uses IAM role credentials (configured in IAM module)
  # - S3 access works through IAM role permissions
  lambda_environment_variables = {
    NODE_ENV                                     = var.node_env
    MONGO_URL                                    = var.mongo_url
    JWT_SECRET                                   = var.jwt_secret
    EMAIL_ADMIN                                  = var.email_admin
    EMAIL_PASS                                   = var.email_pass
    TWILIO_ACCOUNT_SID                           = var.twilio_account_sid
    TWILIO_AUTH_TOKEN                            = var.twilio_auth_token
    TWILIO_PHONE_NUMBER                          = var.twilio_phone_number
    TWILIO_WHATSAPP_NUMBER                       = var.twilio_whatsapp_number
    RAZORPAY_KEY_ID                              = var.razorpay_key_id
    RAZORPAY_KEY_SECRET                          = var.razorpay_key_secret
    AWS_BUCKET_NAME                              = var.aws_bucket_name
    AWS_SDK_JS_SUPPRESS_MAINTENANCE_MODE_MESSAGE = "1"
  }
}

# ========================================
# IAM Module - Lambda Execution Role
# ========================================

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # S3 Access Configuration
  enable_s3_access = var.enable_s3_access
  s3_bucket_name   = var.aws_bucket_name

  # VPC Access Configuration (if needed)
  enable_vpc_access = var.enable_vpc_access

  # Custom Policy Statements (if needed)
  custom_policy_statements = []

  # Secrets Manager (optional)
  enable_secrets_manager = false
  secrets_manager_arns   = []
}

# ========================================
# Lambda Module - Function Deployment
# ========================================

module "lambda" {
  source = "./modules/lambda"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Lambda Configuration
  zip_file_path     = var.lambda_zip_file
  handler           = var.lambda_handler
  runtime           = var.lambda_runtime
  timeout           = var.lambda_timeout
  memory_size       = var.lambda_memory_size

  # If zip is large, upload to S3 (only enable when aws_bucket_name is provided)
  upload_to_s3      = var.aws_bucket_name != "" ? true : false
  s3_bucket_name    = var.aws_bucket_name

  # IAM Role
  lambda_role_arn = module.iam.lambda_role_arn

  # Environment Variables
  environment_variables = local.lambda_environment_variables

  # CloudWatch Logs
  log_retention_days = var.log_retention_days

  # VPC Configuration (optional)
  vpc_config = null

  # API Gateway Permission - Will be created separately to avoid circular dependency
  allow_api_gateway_invoke  = false
  api_gateway_execution_arn = ""

  # Lambda Function URL (disabled - using API Gateway)
  enable_function_url = false

  # Lambda Alias (optional)
  create_alias = false

  depends_on = [module.iam]
}

# ========================================
# Lambda Module - Cron Handler (EventBridge)
# ========================================
# This is a SEPARATE Lambda function specifically for scheduled cron jobs
# It uses the same codebase but different handler: cron-handler.js
# Triggered by AWS EventBridge (not API Gateway)
# ========================================

module "lambda_cron" {
  source = "./modules/lambda"

  project_name = "${var.project_name}-cron"
  environment  = var.environment
  tags         = local.common_tags

  # Lambda Configuration
  zip_file_path     = var.lambda_zip_file    # Same zip file, different handler
  handler           = "cron-handler.handler" # Points to cron-handler.js
  runtime           = var.lambda_runtime
  timeout           = 300 # 5 minutes timeout for cron jobs
  memory_size       = 512 # 512 MB memory for cron processing

  # Use S3 upload for large zip packages (only enable when aws_bucket_name is provided)
  upload_to_s3      = var.aws_bucket_name != "" ? true : false
  s3_bucket_name    = var.aws_bucket_name

  # IAM Role (reuse the same role as main Lambda)
  lambda_role_arn = module.iam.lambda_role_arn

  # Environment Variables (same as main Lambda)
  environment_variables = local.lambda_environment_variables

  # CloudWatch Logs
  log_retention_days = var.log_retention_days

  # VPC Configuration (optional)
  vpc_config = null

  # No API Gateway for cron Lambda
  allow_api_gateway_invoke  = false
  api_gateway_execution_arn = ""

  # Lambda Function URL (disabled)
  enable_function_url = false

  # Lambda Alias (optional)
  create_alias = false

  depends_on = [module.iam]
}

# ========================================
# EventBridge Module - EMI Cron Scheduler
# ========================================
# This creates an EventBridge rule that triggers the cron Lambda function
# on a schedule (daily at 10:00 AM IST)
# ========================================

module "eventbridge_emi" {
  source = "./modules/eventbridge"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Lambda Configuration
  lambda_function_arn  = module.lambda_cron.function_arn
  lambda_function_name = module.lambda_cron.function_name

  # Schedule: Every day at 10:00 AM IST (4:30 AM UTC)
  # IST is UTC+5:30, so we subtract 5.5 hours from IST time
  # 10:00 AM IST = 4:30 AM UTC
  schedule_expression = "cron(30 4 * * ? *)"

  # Alternative schedules (uncomment to use):
  # - Every hour: "rate(1 hour)"
  # - Every 30 minutes: "rate(30 minutes)"
  # - Every day at midnight IST: "cron(30 18 * * ? *)"
  # - Every Monday at 10 AM IST: "cron(30 4 ? * MON *)"

  depends_on = [module.lambda_cron]
}

# ========================================
# API Gateway Module - REST API
# ========================================

module "api_gateway" {
  source = "./modules/api_gateway"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # API Gateway Configuration
  endpoint_type      = "REGIONAL"
  stage_name         = var.api_stage_name
  authorization_type = "NONE"

  # Lambda Integration
  lambda_invoke_arn = module.lambda.function_invoke_arn

  # Logging & Monitoring
  log_retention_days  = var.log_retention_days
  logging_level       = "INFO"
  enable_data_trace   = false
  enable_metrics      = true
  enable_xray_tracing = var.enable_xray_tracing

  # Throttling
  throttling_burst_limit = var.api_gateway_throttling_burst_limit
  throttling_rate_limit  = var.api_gateway_throttling_rate_limit

  # Custom Domain (optional)
  custom_domain_name = var.custom_domain_name
  certificate_arn    = var.certificate_arn
  base_path          = ""

  # Usage Plan (optional - for production rate limiting)
  create_usage_plan = false
  quota_limit       = 100000
  quota_period      = "MONTH"

  # API Key (optional)
  create_api_key = false

  depends_on = [module.lambda]
}

# ========================================
# Lambda Permission for API Gateway
# ========================================
# This is separate to avoid circular dependency

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # Allow invocation from any route in this API Gateway
  source_arn = "${module.api_gateway.api_execution_arn}/*/*"

  depends_on = [
    module.lambda,
    module.api_gateway
  ]
}

# ========================================
# CloudWatch Alarms (Optional)
# ========================================

# Lambda Error Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors Lambda function errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = module.lambda.function_name
  }

  tags = local.common_tags
}

# Lambda Duration Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = var.lambda_timeout * 1000 * 0.8 # 80% of timeout
  alarm_description   = "This metric monitors Lambda function duration"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = module.lambda.function_name
  }

  tags = local.common_tags
}

# API Gateway 4XX Errors Alarm
resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx" {
  alarm_name          = "${var.project_name}-${var.environment}-api-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors API Gateway 4XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = "${var.project_name}-${var.environment}-api"
  }

  tags = local.common_tags
}

# API Gateway 5XX Errors Alarm
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  alarm_name          = "${var.project_name}-${var.environment}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors API Gateway 5XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = "${var.project_name}-${var.environment}-api"
  }

  tags = local.common_tags
}
