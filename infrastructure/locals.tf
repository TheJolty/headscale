locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.vpc_azs_number)
  ec2_instance_types = distinct([
    var.headscale_instance_type,
    var.subnet_router_instance_type,
    var.derp_instance_type
  ])
  ec2_architecture = {
    for index, instance_type in local.ec2_instance_types :
    instance_type => contains(data.aws_ec2_instance_type.architecture[instance_type].supported_architectures, "arm64") ? "arm64" : "amd64"
  }

  private_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 4)]
  database_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 8)]

  subnet_router_private_ip = cidrhost(local.public_subnets[0], 30)

  derp_hostname = "derp.${var.domain}"
}

