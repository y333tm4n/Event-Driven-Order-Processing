variable "queue_name" {
  description = "Name of the SQS queue"
  type = string
}

variable "visibility_timeout_seconds" {
  description = "visibility timeout for the queue"
  type = number
  default = 300
}

variable "message_retention_seconds" {
  description = "message retention period in seconds"
  type = number
  default = 345600
}

variable "max_message_size" {
  description = "maximum message size in bytes"
  type = number
  default = 262144
}

variable "recieve_wait_time_seconds" {
  description = "wait time for RecievedMessage calls"
  type = number
  default = 0
}

variable "tags" {
  description = "tags to apply to the queue"
  type = map(string)
  default = {}
}