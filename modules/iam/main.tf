# ---------------------------------------------------------------------------
# Pipeline role — attached to EC2 instance running Airflow
# ---------------------------------------------------------------------------

resource "aws_iam_role" "pipeline" {
  name = "mex-open-data-pipeline-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "pipeline_s3" {
  name = "pipeline-s3-access"
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # raw/ — full read/write (catalog + original files)
        Sid    = "RawReadWrite"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:GetBucketLocation"]
        Resource = [
          var.bucket_arn,
          "${var.bucket_arn}/raw/*"
        ]
      },
      {
        # curated/ — write-only; pipeline deposits Parquet files, never deletes them
        Sid      = "CuratedWriteOnly"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${var.bucket_arn}/curated/*"
      },
      {
        # Multipart upload support (required for _stream_to_s3)
        Sid    = "MultipartUpload"
        Effect = "Allow"
        Action = [
          "s3:CreateMultipartUpload",
          "s3:UploadPart",
          "s3:CompleteMultipartUpload",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "${var.bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "pipeline_glue" {
  name = "pipeline-glue-trigger"
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "GlueCrawlerTrigger"
      Effect = "Allow"
      # Restricted to crawlers in this project — prevents controlling other account crawlers
      Action   = ["glue:StartCrawler", "glue:GetCrawler", "glue:GetCrawlerMetrics"]
      Resource = "arn:aws:glue:*:*:crawler/mex-open-data-*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "pipeline_cloudwatch" {
  role       = aws_iam_role.pipeline.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "pipeline" {
  name = "mex-open-data-pipeline-profile"
  role = aws_iam_role.pipeline.name
  tags = var.tags
}

# ---------------------------------------------------------------------------
# Glue service role — used by the Glue crawler
# ---------------------------------------------------------------------------

resource "aws_iam_role" "glue" {
  name = "mex-open-data-glue-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3_read" {
  name = "glue-s3-read-curated"
  role = aws_iam_role.glue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "GlueCuratedRead"
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:ListBucket"]
      Resource = [var.bucket_arn, "${var.bucket_arn}/curated/*"]
    }]
  })
}
