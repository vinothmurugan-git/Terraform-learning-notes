terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "terraform-learning-notes"
      ManagedBy = "Terraform"
    }
  }
}

variable "region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "ap-south-1"
}

# The bucket that will store Terraform state files.
# bucket_prefix lets AWS add a unique suffix, because bucket names must be globally unique.
resource "aws_s3_bucket" "state" {
  bucket_prefix = "tf-learning-state-"

  # Learning only: lets "terraform destroy" delete the bucket even when it contains files.
  # Never use this for a real state bucket.
  force_destroy = true
}

# Keep old versions of every state file, so a broken or deleted state can be recovered.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state files at rest.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# State can contain secrets, so the bucket must never be public.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket_name" {
  description = "Name of the state bucket. Copy this into app/backend.tf."
  value       = aws_s3_bucket.state.bucket
}
