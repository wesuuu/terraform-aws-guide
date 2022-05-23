output "public_dns" {
  value = aws_eip.instance.public_dns
}

output "instance_id" {
  value = aws_instance.instance.id
}
