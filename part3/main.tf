terraform {
  required_version = ">= 0.14.9"
}

provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

module "vpc" {
  source = "./modules/vpc"
}
