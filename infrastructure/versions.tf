terraform {
  required_version = "> 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.65.0"
    }
    template = {
      source  = "cloudposse/template"
      version = "~> 2.2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
