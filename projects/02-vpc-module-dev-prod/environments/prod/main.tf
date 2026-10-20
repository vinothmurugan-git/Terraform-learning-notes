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
  region = "ap-south-1"

  default_tags {
    tags = {
      Project     = "terraform-learning-notes"
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name     = "prod"
  vpc_cidr = "10.1.0.0/16"

  public_subnets = {
    "ap-south-1a" = "10.1.1.0/24"
    "ap-south-1b" = "10.1.2.0/24"
  }
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}
