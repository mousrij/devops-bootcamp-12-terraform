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

variable "vpc_cidr_block" {
  description = "vpc cidr block"
}

variable "subnet_cidr_block" {
  description = "subnet cidr block"
}

resource "aws_vpc" "my-test-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "test-vpc"
  }
}

resource "aws_subnet" "my-test-subnet-1" {
  vpc_id = aws_vpc.my-test-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = "eu-central-1a"
  tags = {
    Name: "test-subnet-1"
  }
}

data "aws_vpc" "existing_default_vpc" {
  default = true
}

resource "aws_subnet" "my-test-subnet-2" {
  vpc_id = data.aws_vpc.existing_default_vpc.id
  cidr_block = "172.31.48.0/20"
  availability_zone = "eu-central-1a"
  tags = {
    Name: "test-subnet-2"
  }
}

output "test-vpc-id" {
  value = aws_vpc.my-test-vpc.id
}

output "test-subnet-1-id" {
  value = aws_subnet.my-test-subnet-1.id
}