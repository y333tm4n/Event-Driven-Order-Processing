output "table_name" {
  description = "name of the dynamodb table"
  value = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value = aws_dynamodb_table.this.arn
}