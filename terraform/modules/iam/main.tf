# ========================================
# IAM Role for Lambda Execution
# ========================================

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.project_name}-${var.environment}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-lambda-role"
    }
  )
}

# Assume Role Policy for Lambda
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ========================================
# IAM Policies
# ========================================

# Basic Lambda Execution Policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC Execution Policy (if Lambda needs to access VPC resources)
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  count      = var.enable_vpc_access ? 1 : 0
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom Policy for Additional Permissions
resource "aws_iam_policy" "lambda_custom_policy" {
  count       = length(var.custom_policy_statements) > 0 ? 1 : 0
  name        = "${var.project_name}-${var.environment}-lambda-custom-policy"
  description = "Custom policy for Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = var.custom_policy_statements
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-lambda-custom-policy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_custom_policy" {
  count      = length(var.custom_policy_statements) > 0 ? 1 : 0
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_custom_policy[0].arn
}

# S3 Access Policy (for your audio/file uploads)
resource "aws_iam_policy" "lambda_s3_policy" {
  count       = var.enable_s3_access ? 1 : 0
  name        = "${var.project_name}-${var.environment}-lambda-s3-policy"
  description = "S3 access policy for Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-lambda-s3-policy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  count      = var.enable_s3_access ? 1 : 0
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy[0].arn
}

# Secrets Manager Access (for storing sensitive configuration)
resource "aws_iam_policy" "lambda_secrets_policy" {
  count       = var.enable_secrets_manager ? 1 : 0
  name        = "${var.project_name}-${var.environment}-lambda-secrets-policy"
  description = "Secrets Manager access policy for Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secrets_manager_arns
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-lambda-secrets-policy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_policy" {
  count      = var.enable_secrets_manager ? 1 : 0
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_secrets_policy[0].arn
}
