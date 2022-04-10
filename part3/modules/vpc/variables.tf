variable "aws_settings" {
  type        = map(string)
  description = "Provider settings for aws and terraform"
  default = {
    source           = "hashicorp/aws",
    version          = "~> 4.3.0",
    required_version = ">= 0.14.9"
  }
}

variable "ssh_ip_range" {
  type        = string
  description = "Your public IP for SSHing to aws instances"
  default     = "0.0.0.0/0"

  validation {
    condition     = length(split("/", var.ssh_ip_range)) == 2
    error_message = "You must supply a cidr range with a '/', e.g. 0.0.0.0/0."
  }

  validation {
    condition     = length(split(".", split("/", var.ssh_ip_range)[0])) == 4
    error_message = "IP in cidr range must be separated by 4 periods '.' e.g. 0.0.0.0 ."
  }

  validation {
    condition     = length([for elem in split(".", split("/", var.ssh_ip_range)[0]) : tonumber(elem)]) == 4
    error_message = "IP must consists of integers."
  }
}

variable "project_tags" {
  type        = map(string)
  description = "Tags used for aws tutorial"
  default = {
    project = "aws-terraform-test"
  }
}

variable "vpc" {
  type        = map(string)
  description = "VPC Related data"
  default = {
    cidr_block = "10.0.0.0/16",
    name       = "main"
  }
}

variable "subnets" {
  type        = list(map(string))
  description = "Subnet data"
  default = [
    {
      name              = "public-subnet-1",
      description       = "First public subnet",
      cidr_block        = "10.0.1.0/24",
      type              = "public",
      availability_zone = "us-west-1a"
    },
    {
      name              = "private-subnet-1",
      description       = "first private subnet",
      cidr_block        = "10.0.2.0/24",
      type              = "private",
      availability_zone = "us-west-1c"
    }
  ]
}

variable "extra_subnets" {
  type        = list(map(string))
  description = "Subnet data"
  default     = []
}

variable "gateways" {
  type        = list(map(string))
  description = "Default gateways"
  default = [
    {
      name                  = "internet GW",
      type                  = "internet",
      associate_with_subnet = null
    },
    {
      name                  = "NAT GW",
      type                  = "nat",
      associate_with_subnet = "public-subnet-1"
    }
  ]
}


variable "route_tables" {
  type        = list(map(string))
  description = "Route tables for VPC"
  default = [
    {
      name                  = "public-route-table-1",
      description           = "First public route table",
      associate_with_subnet = "public-subnet-1"
    },
    {
      name                  = "private-route-table-1",
      description           = "First private route table",
      associate_with_subnet = "private-subnet-1"
    }
  ]
}

variable "extra_route_tables" {
  type        = list(map(string))
  description = "Extra route tables"
  default     = []
}

variable "route_table_rules" {
  type        = list(map(string))
  description = "Default route table rules"
  default = [
    {
      name                       = "public-1-internet",
      description                = "Route to the internet",
      cidr_block                 = "0.0.0.0/0",
      associate_with_route_table = "public-route-table-1",
      associate_with_gateway     = "internet GW",
      gateway_type               = "internet"
    },
    {
      name                       = "private-1-nat",
      description                = "Route to the NAT",
      cidr_block                 = "0.0.0.0/0",
      associate_with_route_table = "private-route-table-1",
      associate_with_gateway     = "NAT GW"
      gateway_type               = "nat"
    }
  ]
}

variable "extra_route_table_rules" {
  type        = list(map(string))
  description = "Default route table rules"
  default     = []
}

variable "nacls" {
  type        = list(map(string))
  description = "Default NACLs"
  default = [
    {
      name                  = "public-nacl-1",
      associate_with_subnet = "public-subnet-1"
    },
    {
      name                  = "private-nacl-1",
      associate_with_subnet = "private-subnet-1"
    }
  ]
}

variable "nacl_rules" {
  type        = list(map(string))
  description = "Default NACL rules"
  default = [
    {
      name                = "http-port80-egress",
      rule_type           = "egress",
      associate_with_nacl = "public-nacl-1",
      protocol            = "tcp",
      rule_no             = 100,
      action              = "allow",
      cidr_block          = "0.0.0.0/0",
      from_port           = 80
      to_port             = 80
    },
    {
      name                = "http-port443-egress",
      rule_type           = "egress",
      associate_with_nacl = "public-nacl-1",
      protocol            = "tcp",
      rule_no             = 110,
      action              = "allow",
      cidr_block          = "0.0.0.0/0",
      from_port           = 443
      to_port             = 443
    },
    {
      name                = "port-22-egress",
      rule_type           = "egress",
      associate_with_nacl = "public-nacl-1",
      protocol            = "tcp",
      rule_no             = 150,
      action              = "allow",
      cidr_block          = "10.0.1.0/24",
      from_port           = 22
      to_port             = 22
    },
    {
      name                = "dynamic-port-egress",
      rule_type           = "egress",
      associate_with_nacl = "public-nacl-1",
      protocol            = "tcp",
      rule_no             = 140,
      action              = "allow",
      cidr_block          = "0.0.0.0/0",
      from_port           = 1024
      to_port             = 65535
    },
    {
      name                = "http-port80-ingress",
      rule_type           = "ingress",
      associate_with_nacl = "public-nacl-1",
      protocol            = "tcp",
      rule_no             = 100,
      action              = "allow",
      cidr_block          = "0.0.0.0/0",
      from_port           = 80
      to_port             = 80
    },
    {
      name                = "http-port443-ingress",
      rule_type           = "ingress",
      associate_with_nacl = "public-nacl-1",
      protocol            = "tcp",
      rule_no             = 110,
      action              = "allow",
      cidr_block          = "0.0.0.0/0",
      from_port           = 443
      to_port             = 443
    },
    {
      name                = "dynamic-ports-ingress",
      rule_type           = "ingress",
      associate_with_nacl = "public-nacl-1",
      protocol            = "tcp",
      rule_no             = 140,
      action              = "allow",
      cidr_block          = "0.0.0.0/0",
      from_port           = 1024
      to_port             = 65535
    }
  ]
}
