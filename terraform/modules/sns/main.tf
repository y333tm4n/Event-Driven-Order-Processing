resource "aws_sns_topic" "this" {
  name = var.topic_name
  display_name = var.display_name
  tags = var.tags
}