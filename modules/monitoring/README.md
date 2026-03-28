# Module: monitoring

Creates the full observability stack: SNS alerts, EventBridge rules, CloudWatch alarms, and a CloudTrail trail.

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `bucket_name` | `string` | yes | Data lake bucket name |
| `bucket_arn` | `string` | yes | Data lake bucket ARN |
| `crawler_name` | `string` | yes | Glue crawler name to monitor |
| `alert_email` | `string` | yes | Email address for alert notifications |
| `tags` | `map(string)` | no | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `sns_topic_arn` | ARN of the SNS alerts topic |
| `cloudtrail_name` | Name of the CloudTrail trail |

## Alerts

| Alert | Mechanism | Condition |
|-------|-----------|-----------|
| Glue crawler failure | EventBridge → SNS | Crawler state = `Failed` |
| S3 4xx errors | CloudWatch alarm → SNS | Sum > 20 in 5 min |
| S3 5xx errors | CloudWatch alarm → SNS | Sum > 5 in 5 min |

## Notes

- After the first `terraform apply`, AWS sends a confirmation email to `alert_email`. **The subscription must be confirmed before alerts are delivered.**
- CloudTrail logs are written to `cloudtrail/` prefix in the data lake bucket (same bucket, separate prefix).
- S3 request metrics are enabled for the entire bucket (`aws_s3_bucket_metric`). AWS charges a small fee per metric per month.
