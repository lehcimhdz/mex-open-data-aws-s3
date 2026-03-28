# Module: glue

Creates a Glue catalog database and a crawler that scans `curated/` Parquet files to keep the catalog up to date.

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `bucket_name` | `string` | yes | S3 bucket name |
| `glue_role_arn` | `string` | yes | ARN of the Glue service IAM role |
| `glue_schedule` | `string` | no | Crawler cron schedule (default: Mon-Fri noon UTC) |
| `tags` | `map(string)` | no | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `database_name` | Glue catalog database name (`mex_open_data`) |
| `crawler_name` | Crawler name — set as Airflow Variable `GLUE_CRAWLER_NAME` |

## Crawler behavior

- **Schema change — deleted columns:** `LOG` (does not remove tables)
- **Schema change — updated columns:** `UPDATE_IN_DATABASE`
- **Grouping:** Compatible Parquet schemas are merged into a single table
