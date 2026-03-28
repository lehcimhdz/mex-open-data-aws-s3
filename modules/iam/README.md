# Module: iam

Creates two IAM roles with least-privilege policies:

- **Pipeline role** — attached to the EC2 instance running Airflow.
- **Glue service role** — used by the Glue crawler.

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `bucket_name` | `string` | yes | S3 bucket name |
| `bucket_arn` | `string` | yes | S3 bucket ARN |
| `tags` | `map(string)` | no | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `pipeline_role_arn` | ARN of the EC2 pipeline role |
| `pipeline_instance_profile_name` | Instance profile name to attach to EC2 |
| `glue_role_arn` | ARN of the Glue service role |

## Permissions summary

**Pipeline role (EC2):**

| Resource | Actions |
|----------|---------|
| `raw/*` | `GetObject`, `PutObject`, `ListBucket`, `GetBucketLocation` |
| `curated/*` | `GetObject`, `PutObject` — no `DeleteObject` |
| `*` | Multipart upload actions |
| `arn:aws:glue:*:*:crawler/mex-open-data-*` | `StartCrawler`, `GetCrawler`, `GetCrawlerMetrics` |

**Glue service role:** `AWSGlueServiceRole` (managed) + `GetObject`/`ListBucket` on `curated/*`.
