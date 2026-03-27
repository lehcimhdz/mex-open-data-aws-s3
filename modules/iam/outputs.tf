output "pipeline_role_arn" {
  description = "ARN of the EC2 pipeline IAM role"
  value       = aws_iam_role.pipeline.arn
}

output "pipeline_instance_profile_name" {
  description = "IAM instance profile name to attach to the EC2 instance"
  value       = aws_iam_instance_profile.pipeline.name
}

output "glue_role_arn" {
  description = "ARN of the Glue service role"
  value       = aws_iam_role.glue.arn
}
