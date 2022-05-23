### Required ###

variable "vpc_id" {
  type        = string
  description = "The VPC the instance will live in"
}

variable "public_key" {
  type = object({
    name  = string
    value = string
  })
  description = "Public key data for our instance. 'name' = key name, 'value' = public key data"
}

variable "instance_tags" {
  type        = map(any)
  description = "Any tags you'd like to associate with the instance"
}

variable "ami_id" {
  type        = string
  description = "AMI ID used by the EC2 instance"
}

variable "subnet_id" {
  type        = string
  description = "Subnet which the EC2 instance will reside"
}

variable "project_tags" {
  type        = map(any)
  description = "Any tags you want to associate with this module"
}

### Optional ###

variable "cloud_init_vars" {
  type        = map(any)
  description = "variables used by cloud_init script"
  default     = {}
}

variable "cloud_init_filepath" {
  type        = string
  description = "filepath to cloud-init script"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type"
}

variable "aws_security_group_rules" {
  type = list(object({
    type        = string
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "AWS Security Groups for instance"
}
