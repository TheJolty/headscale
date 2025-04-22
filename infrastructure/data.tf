data "aws_availability_zones" "available" {}

data "aws_ec2_instance_type" "architecture" {
  for_each      = { for index, instance_type in local.ec2_instance_types : instance_type => instance_type }
  instance_type = each.value
}

data "aws_ami" "ubuntu" {
  for_each = { for index, instance_type in local.ec2_instance_types : instance_type => instance_type }

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = [local.ec2_architecture[each.value]]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-${local.ec2_architecture[each.value]}-server-*"
    ]
  }
}

data "aws_route53_zone" "this" {
  name         = var.domain
  private_zone = false
}
