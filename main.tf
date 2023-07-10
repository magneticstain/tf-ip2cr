terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {}
}

provider "aws" {
  region  = "us-east-1"
}

module "ip2cr-test-suite" {
    source = "./modules/ip2cr_test_suite"
    subnets = var.subnets
    vpc = var.vpc
}
