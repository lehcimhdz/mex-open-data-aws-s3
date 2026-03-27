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
