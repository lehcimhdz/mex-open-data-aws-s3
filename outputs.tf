output "bucket_name" {
  description = "S3 data lake bucket name"
  value       = local.bucket_name
}

output "bucket_arn" {
  description = "S3 data lake bucket ARN"
  value       = module.s3.bucket_arn
}

output "pipeline_role_arn" {
  description = "IAM role ARN to attach to the pipeline EC2 instance"
  value       = module.iam.pipeline_role_arn
}

output "pipeline_instance_profile_name" {
  description = "IAM instance profile name to attach to EC2 (used in EC2 launch config)"
  value       = module.iam.pipeline_instance_profile_name
}

output "glue_database_name" {
  description = "Glue catalog database name"
  value       = module.glue.database_name
}

output "glue_crawler_name" {
  description = "Glue crawler name (set as Airflow Variable GLUE_CRAWLER_NAME)"
  value       = module.glue.crawler_name
}

output "athena_workgroup_name" {
  description = "Athena workgroup name"
  value       = module.athena.workgroup_name
}

output "alerts_sns_topic_arn" {
  description = "SNS topic ARN for pipeline alerts (Glue failures, S3 errors)"
  value       = module.monitoring.sns_topic_arn
}

output "cloudtrail_name" {
  description = "CloudTrail trail name for infrastructure audit"
  value       = module.monitoring.cloudtrail_name
}
