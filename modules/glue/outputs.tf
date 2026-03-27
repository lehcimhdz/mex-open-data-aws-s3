output "database_name" {
  description = "Glue catalog database name"
  value       = aws_glue_catalog_database.lake.name
}

output "crawler_name" {
  description = "Glue crawler name — set this as Airflow Variable GLUE_CRAWLER_NAME"
  value       = aws_glue_crawler.curated.name
}
