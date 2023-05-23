terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
    region = "eu-central-1"
    access-key = "your-aws-access-key-id"
    secret-key = "your-aws-secret-access-key"
}