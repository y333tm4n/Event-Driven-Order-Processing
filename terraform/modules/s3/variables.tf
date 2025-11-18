variable "bucket_name" {
  description = "name of the s3 bucket"
  type = string
}

variable "force_destroy" {
  description = "allow the bucket to be destroyed even if it contains objects"
  type = bool
  default = true
}

variable "tags" {
  description = "tags to apply to the bucket"
  type = map(string)
  default = {}
}