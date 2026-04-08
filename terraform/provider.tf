provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
}

terraform {
    required_version = ">= 1.0.0"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.94"
        }
    }
}