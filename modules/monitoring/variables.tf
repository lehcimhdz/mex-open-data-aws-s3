variable "bucket_name" {
  description = "Name of the S3 data lake bucket"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 data lake bucket"
  type        = string
}

variable "crawler_name" {
  description = "Name of the Glue crawler to monitor"
  type        = string
}

variable "alert_email" {
  description = "Email address that receives SNS alert notifications. The address must confirm the subscription before alerts are delivered."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
