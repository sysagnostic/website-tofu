terraform {
  backend "s3" {
    bucket = "sysagnostic-tfstate"
    key    = "website.tfstate"
    region = "eu-central-1"
  }
  required_providers {
    aws = {
      source  = "opentofu/aws"
      version = "~> 5.0"
    }
    archive = {
      source = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}

locals {
  root_domain = "sysagnostic.com"
  s3_bucket_names = toset(concat(["www.${local.root_domain}"], [for id in range(1, 4): format("www%d.%s", id, local.root_domain)]))
  github_actions_arn = "arn:aws:iam::180294196620:user/github"
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-north-1"
}
provider "aws" {
  alias = "global"
  region = "us-east-1"
}
