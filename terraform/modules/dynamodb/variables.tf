variable "table_name" {
  description = "Name of the dynamodb table"
  type = string
}

variable "hash_key" {
  description = "hash key for the table"
  type = string
}

variable "tags" {
  description = "tags to apply to the table"
  type = map(string)
  default = {}
}

