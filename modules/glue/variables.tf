variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "glue_role_arn" {
  description = "ARN of the IAM role for the Glue crawler"
  type        = string
}

variable "glue_schedule" {
  description = "Cron expression for the Glue crawler schedule (AWS format)"
  type        = string
  default     = "cron(0 12 ? * MON-FRI *)"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
