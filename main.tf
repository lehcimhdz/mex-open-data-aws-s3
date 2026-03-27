terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# NOTE: mx-central-1 (AWS Mexico Central) is a recently launched region.
# Before applying, confirm that Glue and Athena are available there:
#   aws glue list-crawlers --region mx-central-1
#   aws athena list-work-groups --region mx-central-1
# If not available, fall back to us-east-1 by changing var.aws_region.
provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.bucket_name_prefix}-${data.aws_caller_identity.current.account_id}"
  common_tags = {
    Project     = "mex-open-data"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = local.bucket_name
  tags        = local.common_tags
}

module "iam" {
  source      = "./modules/iam"
  bucket_name = local.bucket_name
  bucket_arn  = module.s3.bucket_arn
  tags        = local.common_tags
}

module "glue" {
  source        = "./modules/glue"
  bucket_name   = local.bucket_name
  glue_role_arn = module.iam.glue_role_arn
  tags          = local.common_tags
}

module "athena" {
  source      = "./modules/athena"
  bucket_name = local.bucket_name
  tags        = local.common_tags
}
