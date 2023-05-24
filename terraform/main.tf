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
  access_key = "your-aws-access-key-id"
  secret_key = "your-aws-secret-access-key"
}

resource "aws_vpc" "my-test-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "my-test-subnet-1" {
  vpc_id = aws_vpc.my-test-vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "eu-central-1a"
}

data "aws_vpc" "existing_default_vpc" {
  default = true
}

resource "aws_subnet" "my-test-subnet-2" {
  vpc_id = data.aws_vpc.existing_default_vpc.id
  cidr_block = "172.31.48.0/20"
  availability_zone = "eu-central-1a"
}