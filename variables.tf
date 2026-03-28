variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "mx-central-1"
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be \"dev\" or \"prod\"."
  }
}

variable "bucket_name_prefix" {
  description = "Prefix for the S3 bucket name; AWS account ID is appended automatically"
  type        = string
  default     = "mex-open-data-lake"

  validation {
    condition     = length(var.bucket_name_prefix) <= 30 && can(regex("^[a-z0-9-]+$", var.bucket_name_prefix))
    error_message = "bucket_name_prefix must use only lowercase letters, numbers, and hyphens, and be at most 30 characters."
  }
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
