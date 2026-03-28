# Module: athena

Creates an Athena workgroup configured for the data lake.

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `bucket_name` | `string` | yes | S3 bucket name (query results stored in `athena-results/`) |
| `tags` | `map(string)` | no | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `workgroup_name` | Athena workgroup name (`mex-open-data`) |

## Configuration

| Setting | Value |
|---------|-------|
| Engine version | Athena engine version 3 |
| Output location | `s3://{bucket}/athena-results/` |
| Encryption | SSE-S3 |
| Cost guard | Queries scanning > 1 GB are cancelled |
| Workgroup enforcement | Enabled — client settings are overridden |
