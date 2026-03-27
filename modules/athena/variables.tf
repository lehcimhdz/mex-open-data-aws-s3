variable "bucket_name" {
  description = "S3 bucket name (used for Athena query results location)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
