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
  description = "AWS region for the app resources"
  type        = string
  default     = "ap-south-1"
}

# A small bucket that stands in for "your application's infrastructure".
resource "aws_s3_bucket" "app" {
  bucket_prefix = "tf-learning-app-"

  # Learning only: lets "terraform destroy" delete the bucket even when it contains files.
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "app_bucket_name" {
  description = "Name of the app bucket"
  value       = aws_s3_bucket.app.bucket
}
