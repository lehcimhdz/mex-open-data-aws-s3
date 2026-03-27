data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# SNS — central alert bus for all pipeline notifications
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "alerts" {
  name = "mex-open-data-alerts"
  tags = var.tags
}

# Email subscription — the address must click the confirmation link AWS sends
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Allow EventBridge and CloudWatch to publish to this topic
resource "aws_sns_topic_policy" "allow_publish" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridge"
        Effect = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Sid    = "AllowCloudWatch"
        Effect = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Glue crawler failure — EventBridge rule (more reliable than CW metrics)
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "glue_crawler_failed" {
  name        = "mex-open-data-glue-crawler-failed"
  description = "Fires when the Glue crawler transitions to FAILED state"
  tags        = var.tags

  event_pattern = jsonencode({
    source      = ["aws.glue"]
    "detail-type" = ["Glue Crawler State Change"]
    detail = {
      crawlerName = [var.crawler_name]
      state       = ["Failed"]
    }
  })
}

resource "aws_cloudwatch_event_target" "glue_crawler_failed_sns" {
  rule      = aws_cloudwatch_event_rule.glue_crawler_failed.name
  target_id = "sns-alerts"
  arn       = aws_sns_topic.alerts.arn
}

# ---------------------------------------------------------------------------
# S3 request metrics — must be enabled before CW alarms can use them
# ---------------------------------------------------------------------------

resource "aws_s3_bucket_metric" "lake_all" {
  bucket = var.bucket_name
  name   = "EntireBucket"
  # No filter = metrics for the whole bucket
}

resource "aws_cloudwatch_metric_alarm" "s3_4xx" {
  alarm_name          = "mex-open-data-s3-4xx-errors"
  alarm_description   = "S3 4xx error rate elevated — possible bad requests or IAM misconfiguration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 20
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    BucketName  = var.bucket_name
    StorageType = "AllStorageTypes"
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "s3_5xx" {
  alarm_name          = "mex-open-data-s3-5xx-errors"
  alarm_description   = "S3 5xx errors detected — AWS-side failures impacting the pipeline"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    BucketName  = var.bucket_name
    StorageType = "AllStorageTypes"
  }
  tags = var.tags
}

# ---------------------------------------------------------------------------
# CloudTrail — full API audit log written to cloudtrail/ prefix in data lake
# ---------------------------------------------------------------------------

# Bucket policy required by CloudTrail before the trail can be created
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = var.bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = var.bucket_arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/mex-open-data-trail"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${var.bucket_arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/mex-open-data-trail"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "pipeline" {
  name                          = "mex-open-data-trail"
  s3_bucket_name                = var.bucket_name
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true
  tags                          = var.tags

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}
