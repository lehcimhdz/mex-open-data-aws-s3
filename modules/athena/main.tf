resource "aws_athena_workgroup" "lake" {
  name        = "mex-open-data"
  description = "Workgroup for querying the Mexican open data lake via Athena"
  tags        = var.tags

  configuration {
    # Force all queries to use this workgroup's settings (output location, encryption)
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.bucket_name}/athena-results/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }

    # Cost guard: cancel queries that would scan more than 1 GB
    bytes_scanned_cutoff_per_query = 1073741824
  }
}
