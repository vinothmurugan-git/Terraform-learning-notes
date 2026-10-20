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
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "github_repo" {
  description = "Your GitHub repository, written as owner/name, for example octocat/terraform-pipeline-practice"
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the state bucket from Project 1"
  type        = string
}

# Lets AWS trust login tokens issued by GitHub Actions.
# An AWS account can only have one of these. If you already have one, see the README.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# Who can use the role: only your repository, and only from
# pull requests (for plan) or the "production" environment (for apply).
data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:pull_request",
        "repo:${var.github_repo}:environment:production",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-terraform-learning"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

# What the role can do: manage VPCs (for Project 2's dev environment)...
resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

# ...and read and write Project 2's state files, including the lock file.
data "aws_iam_policy_document" "state" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/project-2/*"]
  }
}

resource "aws_iam_role_policy" "state" {
  name   = "terraform-state-access"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.state.json
}

output "role_arn" {
  description = "Copy this into your GitHub repository variable AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}
