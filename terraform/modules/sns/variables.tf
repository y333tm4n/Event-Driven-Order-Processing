variable "topic_name" {
  description = "name of the sns topic"
  type = string
}

variable "display_name" {
  description = "display name for the sns topic"
  type = string
  default = ""
}

variable "tags" {
  description = "tags to apply to the topic"
  type = map(string)
  default = {}
}