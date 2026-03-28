terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote backend — stores state in S3 with DynamoDB locking.
  # Before first `terraform init`, run bootstrap/ to create these resources:
  #   cd bootstrap && terraform init && terraform apply
  # Then copy backend.hcl.example → backend.hcl and fill in values.
  # Init with: terraform init -backend-config=backend.hcl
  backend "s3" {
    # Values are supplied via backend.hcl (not committed to git).
    # See backend.hcl.example for the required keys.
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
    Project            = "mex-open-data"
    Environment        = var.environment
    ManagedBy          = "terraform"
    Owner              = var.owner
    CostCenter         = var.cost_center
    DataClassification = "public"
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
  glue_schedule = var.glue_schedule
  tags          = local.common_tags
}

module "monitoring" {
  source       = "./modules/monitoring"
  bucket_name  = local.bucket_name
  bucket_arn   = module.s3.bucket_arn
  crawler_name = module.glue.crawler_name
  alert_email  = var.alert_email
  tags         = local.common_tags
}

module "athena" {
  source      = "./modules/athena"
  bucket_name = local.bucket_name
  tags        = local.common_tags
}
