resource "aws_glue_catalog_database" "lake" {
  name        = "mex_open_data"
  description = "Mexican government open data — datos.gob.mx (curated Parquet layer)"
  tags        = var.tags
}

resource "aws_glue_crawler" "curated" {
  name          = "mex-open-data-curated-crawler"
  role          = var.glue_role_arn
  database_name = aws_glue_catalog_database.lake.name
  description   = "Scans curated/ Parquet files and keeps the Glue catalog up to date"
  tags          = var.tags

  s3_target {
    path = "s3://${var.bucket_name}/curated/"
  }

  schema_change_policy {
    # Log schema deletions rather than silently removing tables
    delete_behavior = "LOG"
    # Automatically update table definitions when columns change
    update_behavior = "UPDATE_IN_DATABASE"
  }

  schedule = var.glue_schedule

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      # Combine Parquet files with the same schema into a single table
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })
}
