terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.3.0"
    }
  }

  required_version = ">= 0.14.9"
}

variable "project_tags" {
  type = map(string)
  default = {
    project = "aws-terraform-test"
  }
}
