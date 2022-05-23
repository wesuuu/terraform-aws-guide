terraform {
  required_version = ">= 0.14.9"
}

data "template_file" "init" {
  template = file(var.cloud_init_filepath)

  vars = var.cloud_init_vars
}

### Security Groups ###

resource "aws_security_group" "instance" {
  name        = "dev_security"
  description = "Allow traffic to flow to port 443"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = { for rule in var.aws_security_group_rules : rule.description => rule if rule.type == "ingress" }

    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = { for rule in var.aws_security_group_rules : rule.description => rule if rule.type == "egress" }

    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

### SSH Key ###

resource "aws_key_pair" "instance" {
  key_name   = var.public_key.name
  public_key = var.public_key.value
}

### EC2 ###

resource "aws_eip" "instance" {
  instance = aws_instance.instance.id
  vpc      = true
}

resource "aws_instance" "instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [
    aws_security_group.instance.id,
  ]
  key_name  = var.public_key.name
  user_data = data.template_file.init.rendered

  tags = merge(var.project_tags, var.instance_tags)
}
