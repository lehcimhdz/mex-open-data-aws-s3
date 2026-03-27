resource "aws_s3_bucket" "lake" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "lake" {
  bucket = aws_s3_bucket.lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lake" {
  bucket = aws_s3_bucket.lake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "lake" {
  bucket                  = aws_s3_bucket.lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lake" {
  bucket = aws_s3_bucket.lake.id

  # raw/ — move to Glacier after 90 days, expire after 1 year
  rule {
    id     = "raw-archive"
    status = "Enabled"
    filter { prefix = "raw/" }
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
  }

  # curated/ — keep indefinitely (always queryable via Athena)

  # athena-results/ — expire after 30 days
  rule {
    id     = "athena-results-expiry"
    status = "Enabled"
    filter { prefix = "athena-results/" }
    expiration {
      days = 30
    }
  }
}
