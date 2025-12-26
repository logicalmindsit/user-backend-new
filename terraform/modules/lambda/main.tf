# ========================================
# Lambda Function
# ========================================

# If the deployment package is large, upload it to S3 and reference it in the Lambda resource
resource "aws_s3_object" "lambda_zip" {
  count        = var.upload_to_s3 ? 1 : 0
  bucket       = var.s3_bucket_name
  key          = var.s3_key != "" ? var.s3_key : "${var.project_name}-${var.environment}.zip"
  source       = var.zip_file_path
  content_type = "application/zip"
}

# Lambda using local file (direct API upload) - used when upload_to_s3 = false
resource "aws_lambda_function" "main" {
  count            = var.upload_to_s3 ? 0 : 1
  filename         = var.zip_file_path
  function_name    = "${var.project_name}-${var.environment}"
  role             = var.lambda_role_arn
  handler          = var.handler
  source_code_hash = filebase64sha256(var.zip_file_path)
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size

  # Reserved Concurrent Executions (optional)
  reserved_concurrent_executions = var.reserved_concurrent_executions >= 0 ? var.reserved_concurrent_executions : null

  environment {
    variables = var.environment_variables
  }

  # VPC Configuration (optional)
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Dead Letter Queue Configuration (optional)
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config_target_arn != "" ? [1] : []
    content {
      target_arn = var.dead_letter_config_target_arn
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}"
      Environment = var.environment
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group
  ]
}

# Lambda using S3 object - used when upload_to_s3 = true
resource "aws_lambda_function" "s3" {
  count            = var.upload_to_s3 ? 1 : 0
  s3_bucket        = var.s3_bucket_name
  s3_key           = var.s3_key != "" ? var.s3_key : "${var.project_name}-${var.environment}.zip"
  function_name    = "${var.project_name}-${var.environment}"
  role             = var.lambda_role_arn
  handler          = var.handler
  source_code_hash = filebase64sha256(var.zip_file_path)
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size

  # Reserved Concurrent Executions (optional)
  reserved_concurrent_executions = var.reserved_concurrent_executions >= 0 ? var.reserved_concurrent_executions : null

  environment {
    variables = var.environment_variables
  }

  # VPC Configuration (optional)
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Dead Letter Queue Configuration (optional)
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config_target_arn != "" ? [1] : []
    content {
      target_arn = var.dead_letter_config_target_arn
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}"
      Environment = var.environment
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group,
    aws_s3_object.lambda_zip
  ]
}

# Provide a single reference to the active lambda resource for downstream use
locals {
  lambda = var.upload_to_s3 ? aws_lambda_function.s3[0] : aws_lambda_function.main[0]
}

# ========================================
# CloudWatch Log Group
# ========================================

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-logs"
      Environment = var.environment
    }
  )
}

# ========================================
# Lambda Function URL (Optional - for direct HTTP access)
# ========================================

resource "aws_lambda_function_url" "main" {
  count              = var.enable_function_url ? 1 : 0
  function_name      = local.lambda.function_name
  authorization_type = var.function_url_auth_type

  cors {
    allow_credentials = var.function_url_cors.allow_credentials
    allow_origins     = var.function_url_cors.allow_origins
    allow_methods     = var.function_url_cors.allow_methods
    allow_headers     = var.function_url_cors.allow_headers
    expose_headers    = var.function_url_cors.expose_headers
    max_age           = var.function_url_cors.max_age
  }
}

# ========================================
# Lambda Alias (for versioning)
# ========================================

resource "aws_lambda_alias" "main" {
  count            = var.create_alias ? 1 : 0
  name             = var.alias_name
  description      = "Alias for ${var.project_name}-${var.environment}"
  function_name    = local.lambda.function_name
  function_version = var.alias_function_version

  lifecycle {
    ignore_changes = [function_version]
  }
}

# ========================================
# Lambda Permission for API Gateway
# ========================================

resource "aws_lambda_permission" "api_gateway" {
  count         = var.allow_api_gateway_invoke ? 1 : 0
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = local.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.api_gateway_execution_arn
}

# ========================================
# Lambda Provisioned Concurrency (Optional)
# ========================================

resource "aws_lambda_provisioned_concurrency_config" "main" {
  count                             = var.provisioned_concurrent_executions > 0 ? 1 : 0
  function_name                     = local.lambda.function_name
  provisioned_concurrent_executions = var.provisioned_concurrent_executions
  qualifier                         = var.create_alias ? aws_lambda_alias.main[0].name : local.lambda.version

  depends_on = [aws_lambda_function.main, aws_lambda_function.s3]
}
