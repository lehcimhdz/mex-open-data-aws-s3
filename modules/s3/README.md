# Module: s3

Creates the S3 data lake bucket with versioning, AES-256 encryption, public access block, server access logging, and lifecycle rules.

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `bucket_name` | `string` | yes | Bucket name (account ID appended by root module) |
| `tags` | `map(string)` | no | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | S3 bucket name |
| `bucket_arn` | S3 bucket ARN |

## Lifecycle rules

| Prefix | Rule |
|--------|------|
| `raw/` | Glacier after 90 days, expire after 365 days |
| `athena-results/` | Expire after 30 days |
| `curated/` | Retained indefinitely |
