# dead letter queue
resource "aws_sqs_queue" "dlq" {
  name = "${var.queue_name}-dlq"
  message_retention_seconds = 1209600 # equivalent to 14 days
  tags = var.tags
}

# main queue
resource "aws_sqs_queue" "this" {
  name = var.queue_name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds = var.message_retention_seconds
  max_message_size = var.max_message_size

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount = 3
  })

  tags = var.tags
}