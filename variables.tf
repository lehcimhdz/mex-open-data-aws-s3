variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "mx-central-1"
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "prod"
}

variable "bucket_name_prefix" {
  description = "Prefix for the S3 bucket name; AWS account ID is appended automatically"
  type        = string
  default     = "mex-open-data-lake"
}

variable "glue_schedule" {
  description = "Cron schedule for the Glue crawler (AWS cron format). Default: Mon-Fri at noon UTC."
  type        = string
  default     = "cron(0 12 ? * MON-FRI *)"
}

variable "alert_email" {
  description = "Email address for pipeline failure and S3 error notifications. Must confirm the SNS subscription."
  type        = string
}
