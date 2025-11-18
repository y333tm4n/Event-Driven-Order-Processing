output "topic_arn" {
  description = "arn of the sns topic"
  value = aws_sns_topic.this.arn
}

output "topic_name" {
  description = "name of the sns topic"
  value = aws_sns_topic.this.name
}
