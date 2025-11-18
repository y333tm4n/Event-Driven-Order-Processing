output "bucket_name" {
  description = "name of the s3 bucket"
  value = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "arn of the s3 bucket"
  value = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = "id of the s3 bucket"
  value = aws_s3_bucket.this.id
}