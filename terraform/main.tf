# Local variables for common tags and naming
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for Lambda Functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = module.dynamodb.table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          module.sqs.queue_arn,
          module.sqs.dlq_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = module.sns.topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3.bucket_arn,
          "${module.s3.bucket_arn}/*"
        ]
      }
    ]
  })
}

# DynamoDB Module - Orders Table
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name = "${var.project_name}-orders"
  hash_key   = "order_id"
  tags       = local.common_tags
}

# SQS Module - Order Processing Queue
module "sqs" {
  source = "./modules/sqs"

  queue_name                 = "${var.project_name}-order-queue"
  visibility_timeout_seconds = 300
  tags                       = local.common_tags
}

# SNS Module - Order Notifications
module "sns" {
  source = "./modules/sns"

  topic_name   = "${var.project_name}-order-notifications"
  display_name = "Order Processing Notifications"
  tags         = local.common_tags
}

# S3 Module - Invoice Storage
module "s3" {
  source = "./modules/s3"

  bucket_name   = "${var.project_name}-invoices-${var.environment}"
  force_destroy = true
  tags          = local.common_tags
}

# Lambda Module - Create Order Function
module "lambda_create_order" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-create-order"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  source_dir    = "${path.root}/../src/create_order"
  iam_role_arn  = aws_iam_role.lambda_role.arn
  timeout       = 30
  memory_size   = 256

  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb.table_name
    SQS_QUEUE_URL  = module.sqs.queue_url
  }

  tags = local.common_tags
}

# Lambda Module - Process Order Function
module "lambda_process_order" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-process-order"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  source_dir    = "${path.root}/../src/process_order"
  iam_role_arn  = aws_iam_role.lambda_role.arn
  timeout       = 60
  memory_size   = 256

  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb.table_name
    SNS_TOPIC_ARN  = module.sns.topic_arn
    S3_BUCKET      = module.s3.bucket_name
  }

  tags = local.common_tags
}

# Lambda Module - Generate Invoice Function
module "lambda_generate_invoice" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-generate-invoice"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  source_dir    = "${path.root}/../src/generate_invoice"
  iam_role_arn  = aws_iam_role.lambda_role.arn
  timeout       = 30
  memory_size   = 256

  environment_variables = {
    S3_BUCKET      = module.s3.bucket_name
    DYNAMODB_TABLE = module.dynamodb.table_name
  }

  tags = local.common_tags
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api_gateway"

  api_name             = "${var.project_name}-api"
  api_description      = "Order Processing API"
  stage_name           = var.environment
  lambda_function_name = module.lambda_create_order.function_name
  lambda_invoke_arn    = module.lambda_create_order.invoke_arn
  tags                 = local.common_tags
}

# SQS Event Source Mapping for Process Order Lambda
resource "aws_lambda_event_source_mapping" "sqs_to_process_order" {
  event_source_arn = module.sqs.queue_arn
  function_name    = module.lambda_process_order.function_name
  batch_size       = 10
  enabled          = true
}