# ---------------------------------------------------------------------------
# Bootstrap — run ONCE before the main Terraform stack.
# Creates the S3 bucket and DynamoDB table used for remote state storage.
#
# Usage:
#   cd bootstrap
#   terraform init
#   terraform apply
#
# After apply, copy backend.hcl.example → ../backend.hcl, fill in values,
# then in the root directory:
#   terraform init -backend-config=../backend.hcl
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Bootstrap state is stored locally — this is intentional.
  # It manages only two long-lived resources that rarely change.
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  state_bucket = "${var.state_bucket_prefix}-${data.aws_caller_identity.current.account_id}"
}

# ---------------------------------------------------------------------------
# S3 bucket for Terraform state
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "tf_state" {
  bucket = local.state_bucket

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project   = "mex-open-data"
    ManagedBy = "terraform-bootstrap"
    Purpose   = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# DynamoDB table for state locking
# ---------------------------------------------------------------------------

resource "aws_dynamodb_table" "tf_lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project   = "mex-open-data"
    ManagedBy = "terraform-bootstrap"
    Purpose   = "terraform-state-lock"
  }
}

# ---------------------------------------------------------------------------
# Outputs — copy these into backend.hcl
# ---------------------------------------------------------------------------

output "state_bucket_name" {
  value       = aws_s3_bucket.tf_state.id
  description = "Name of the S3 bucket storing Terraform state. Use as 'bucket' in backend.hcl."
}

output "lock_table_name" {
  value       = aws_dynamodb_table.tf_lock.name
  description = "DynamoDB table for state locking. Use as 'dynamodb_table' in backend.hcl."
}
