# ========================================
# IAM Role for API Gateway CloudWatch Logging
# ========================================

data "aws_iam_policy_document" "api_gateway_cloudwatch_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name               = "${var.project_name}-${var.environment}-api-gateway-cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_cloudwatch_assume_role.json

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-api-gateway-cloudwatch"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Set the CloudWatch role for API Gateway account settings
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# ========================================
# API Gateway REST API
# ========================================

resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "API Gateway for ${var.project_name} ${var.environment}"

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-api"
      Environment = var.environment
    }
  )
}

# ========================================
# API Gateway Resource (Proxy)
# ========================================

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# ========================================
# API Gateway Method (ANY for proxy+)
# ========================================

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = var.authorization_type

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# ========================================
# API Gateway Method (ANY for root)
# ========================================

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "ANY"
  authorization = var.authorization_type
}

# ========================================
# API Gateway Integration (Lambda Proxy)
# ========================================

resource "aws_api_gateway_integration" "lambda_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_integration" "lambda_proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# ========================================
# API Gateway Deployment
# ========================================

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_method.proxy_root.id,
      aws_api_gateway_integration.lambda_proxy.id,
      aws_api_gateway_integration.lambda_proxy_root.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.lambda_proxy,
    aws_api_gateway_integration.lambda_proxy_root
  ]
}

# ========================================
# API Gateway Stage
# ========================================

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name

  xray_tracing_enabled = var.enable_xray_tracing

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.stage_name}"
      Environment = var.environment
    }
  )

  depends_on = [aws_api_gateway_account.main]
}

# ========================================
# API Gateway Method Settings
# ========================================

resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = var.enable_metrics
    logging_level         = var.logging_level
    data_trace_enabled    = var.enable_data_trace
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }
}

# ========================================
# CloudWatch Log Group for API Gateway
# ========================================

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-api-logs"
      Environment = var.environment
    }
  )
}

# ========================================
# API Gateway Domain Name (Optional)
# ========================================

resource "aws_api_gateway_domain_name" "main" {
  count           = var.custom_domain_name != "" ? 1 : 0
  domain_name     = var.custom_domain_name
  certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-domain"
      Environment = var.environment
    }
  )
}

resource "aws_api_gateway_base_path_mapping" "main" {
  count       = var.custom_domain_name != "" ? 1 : 0
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.main[0].domain_name
  base_path   = var.base_path
}

# ========================================
# API Gateway Usage Plan (Optional)
# ========================================

resource "aws_api_gateway_usage_plan" "main" {
  count       = var.create_usage_plan ? 1 : 0
  name        = "${var.project_name}-${var.environment}-usage-plan"
  description = "Usage plan for ${var.project_name} ${var.environment}"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  quota_settings {
    limit  = var.quota_limit
    offset = var.quota_offset
    period = var.quota_period
  }

  throttle_settings {
    burst_limit = var.throttling_burst_limit
    rate_limit  = var.throttling_rate_limit
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-usage-plan"
      Environment = var.environment
    }
  )
}

# ========================================
# API Gateway API Key (Optional)
# ========================================

resource "aws_api_gateway_api_key" "main" {
  count       = var.create_api_key ? 1 : 0
  name        = "${var.project_name}-${var.environment}-api-key"
  description = "API Key for ${var.project_name} ${var.environment}"
  enabled     = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-api-key"
      Environment = var.environment
    }
  )
}

resource "aws_api_gateway_usage_plan_key" "main" {
  count         = var.create_api_key && var.create_usage_plan ? 1 : 0
  key_id        = aws_api_gateway_api_key.main[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main[0].id
}
