variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
