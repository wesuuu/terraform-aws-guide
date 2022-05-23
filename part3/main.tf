terraform {
  required_version = ">= 0.14.9"
}

provider "aws" {
  region = "us-west-1"
}

module "vpc" {
  source = "./modules/vpc"
}
