output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "api_id" {
  description = "API Gateway ID"
  value       = module.api_gateway.api_id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = module.sqs.queue_url
}

output "sqs_queue_name" {
  description = "SQS queue name"
  value       = module.sqs.queue_name
}

output "sqs_dlq_url" {
  description = "SQS dead letter queue URL"
  value       = module.sqs.dlq_url
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = module.sns.topic_arn
}

output "s3_bucket_name" {
  description = "S3 bucket name for invoices"
  value       = module.s3.bucket_name
}

output "lambda_create_order_name" {
  description = "Create Order Lambda function name"
  value       = module.lambda_create_order.function_name
}

output "lambda_process_order_name" {
  description = "Process Order Lambda function name"
  value       = module.lambda_process_order.function_name
}

output "lambda_generate_invoice_name" {
  description = "Generate Invoice Lambda function name"
  value       = module.lambda_generate_invoice.function_name
}