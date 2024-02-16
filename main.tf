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
    ami_id = var.ami_id
}

output "ip2cr-testing-metadata" {
  value = [
    module.ip2cr-test-suite.ip2cr-ec2-metadata,
    module.ip2cr-test-suite.ip2cr-cf-distro-metadata,
    module.ip2cr-test-suite.ip2cr-testing-alb-metadata,
    module.ip2cr-test-suite.ip2cr-testing-nlb-metadata,
    module.ip2cr-test-suite.ip2cr-testing-elb-metadata
  ]
}
