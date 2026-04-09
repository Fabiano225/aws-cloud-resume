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

terraform {
  backend "s3" {
    bucket = "resume-terraformstate-395833164369-eu-north-1-an"
    key    = "terraform.tfstate"
    region = "eu-north-1"
  }
}