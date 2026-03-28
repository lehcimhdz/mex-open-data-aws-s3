# Terraform test for modules/s3
# Run with: terraform test (requires Terraform >= 1.7 for mock_provider)
#
# These tests use plan-only mode with a mocked AWS provider so no real
# infrastructure is created and no AWS credentials are needed.

mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      id  = "test-bucket"
      arn = "arn:aws:s3:::test-bucket"
    }
  }
  mock_resource "aws_s3_bucket_server_side_encryption_configuration" {
    defaults = {}
  }
  mock_resource "aws_s3_bucket_versioning" {
    defaults = {}
  }
  mock_resource "aws_s3_bucket_public_access_block" {
    defaults = {}
  }
  mock_resource "aws_s3_bucket_lifecycle_configuration" {
    defaults = {}
  }
  mock_resource "aws_s3_bucket_logging" {
    defaults = {}
  }
}

run "s3_bucket_encryption_is_aes256" {
  command = plan

  module {
    source = "./modules/s3"
  }

  variables {
    bucket_name = "test-mex-open-data-lake"
  }

  assert {
    condition = aws_s3_bucket_server_side_encryption_configuration.lake.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "S3 bucket must use AES256 server-side encryption"
  }

  assert {
    condition = aws_s3_bucket_server_side_encryption_configuration.lake.rule[0].bucket_key_enabled == true
    error_message = "Bucket key must be enabled to reduce SSE costs"
  }
}

run "s3_bucket_blocks_all_public_access" {
  command = plan

  module {
    source = "./modules/s3"
  }

  variables {
    bucket_name = "test-mex-open-data-lake"
  }

  assert {
    condition = aws_s3_bucket_public_access_block.lake.block_public_acls == true
    error_message = "block_public_acls must be true"
  }

  assert {
    condition = aws_s3_bucket_public_access_block.lake.block_public_policy == true
    error_message = "block_public_policy must be true"
  }

  assert {
    condition = aws_s3_bucket_public_access_block.lake.restrict_public_buckets == true
    error_message = "restrict_public_buckets must be true"
  }
}

run "s3_bucket_versioning_enabled" {
  command = plan

  module {
    source = "./modules/s3"
  }

  variables {
    bucket_name = "test-mex-open-data-lake"
  }

  assert {
    condition = aws_s3_bucket_versioning.lake.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be enabled on the data lake bucket"
  }
}
