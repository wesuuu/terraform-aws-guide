terraform {
  required_version = ">= 0.14.9"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

locals {
  all_subnets = concat(var.subnets, var.extra_subnets)

  all_route_tables      = concat(var.route_tables, var.extra_route_tables)
  all_route_table_rules = concat(var.route_table_rules, var.extra_route_table_rules)

  internet_gateways = [for gateway in var.gateways : gateway if gateway.type == "internet"]
  nat_gateways      = [for gateway in var.gateways : gateway if gateway.type == "nat"]

  all_nacls      = var.nacls
  all_nacl_rules = var.nacl_rules
}

data "aws_availability_zones" "available" {}

data "aws_availability_zone" "available" {
  for_each = toset(data.aws_availability_zones.available.names)
  name     = each.value
}

resource "aws_vpc" "main" {
  cidr_block                     = var.vpc["cidr_block"]
  enable_dns_hostnames           = true
  enable_dns_support             = true
  enable_classiclink_dns_support = true

  tags = merge(
    var.project_tags,
    {
      Name = var.vpc.name
    },
  var.vpc)
}

resource "aws_subnet" "public" {
  for_each          = { for subnet in local.all_subnets : subnet.name => subnet }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge(
    var.project_tags,
    {
      Name = each.value.name
    },
    each.value
  )
}

### Gateways ###

resource "aws_internet_gateway" "internet" {
  for_each = { for gateway in local.internet_gateways : gateway.name => gateway }
  vpc_id   = aws_vpc.main.id

  tags = merge(
    var.project_tags,
    {
      Name = each.value.name
    },
    each.value
  )
}

resource "aws_eip" "nat_ips" {
  for_each = { for gateway in local.nat_gateways : gateway.name => gateway }
  vpc      = true
}

resource "aws_nat_gateway" "nat_gateway" {
  for_each = { for gateway in local.nat_gateways : gateway.name => gateway }

  allocation_id = aws_eip.nat_ips[each.value.name].id
  subnet_id     = aws_subnet.public[each.value.associate_with_subnet].id

  tags = merge(
    var.project_tags,
    {
      Name = each.value.name
    },
    each.value
  )
}

### Route Tables ###

resource "aws_route_table" "route_tables" {
  for_each = { for route_table in local.all_route_tables : route_table.name => route_table }
  vpc_id   = aws_vpc.main.id

  dynamic "route" {
    for_each = { for rule in local.all_route_table_rules : rule.name => rule if rule.associate_with_route_table == each.value.name }
    content {
      cidr_block     = route.value.cidr_block
      gateway_id     = route.value.gateway_type == "internet" ? aws_internet_gateway.internet[route.value.associate_with_gateway].id : null
      nat_gateway_id = route.value.gateway_type == "nat" ? aws_nat_gateway.nat_gateway[route.value.associate_with_gateway].id : null
    }
  }

  tags = merge(
    var.project_tags,
    {
      Name = each.value.name
    }
  )
}


resource "aws_route_table_association" "public" {
  for_each       = { for route_table in local.all_route_tables : route_table.name => route_table }
  subnet_id      = aws_subnet.public[each.value.associate_with_subnet].id
  route_table_id = aws_route_table.route_tables[each.value.name].id
}

### NACLs ###

resource "aws_network_acl" "nacls" {
  for_each = { for nacl in local.all_nacls : nacl.name => nacl }
  vpc_id   = aws_vpc.main.id

  dynamic "egress" {
    for_each = { for rule in local.all_nacl_rules : rule.name => rule if rule.rule_type == "egress" && rule.associate_with_nacl == each.value.name }
    content {
      protocol   = egress.value.protocol
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }

  dynamic "ingress" {
    for_each = { for rule in local.all_nacl_rules : rule.name => rule if rule.rule_type == "ingress" && rule.associate_with_nacl == each.value.name }
    content {
      protocol   = ingress.value.protocol
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      cidr_block = ingress.value.cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = var.ssh_ip_range
    from_port  = 22
    to_port    = 22
  }

  tags = merge(
    var.project_tags,
    {
      Name = each.value.name
    }
  )
}

resource "aws_network_acl_association" "nacl_association" {
  for_each       = { for nacl in local.all_nacls : nacl.name => nacl }
  network_acl_id = aws_network_acl.nacls[each.value.name].id
  subnet_id      = aws_subnet.public[each.value.associate_with_subnet].id
}
