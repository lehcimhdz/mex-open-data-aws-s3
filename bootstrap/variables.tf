variable "aws_region" {
  description = "AWS region for the Terraform state resources."
  type        = string
  default     = "mx-central-1"
}

variable "state_bucket_prefix" {
  description = "Prefix for the S3 state bucket name. Account ID is appended automatically."
  type        = string
  default     = "mex-open-data-tfstate"
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking."
  type        = string
  default     = "mex-open-data-tf-lock"
}
