##############################
##### Networking
##############################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v5.13.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs              = local.azs
  private_subnets  = local.private_subnets
  public_subnets   = local.public_subnets
  database_subnets = local.database_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = var.tags
}

##############################
##### Database
##############################
module "sg_rds" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "${var.rds_name}-sg"
  description = "Security group of RDS ${var.rds_name}"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "Allow VPC CIDR to connect to RDS"
      cidr_blocks = var.vpc_cidr
    }
  ]
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.9.0"

  subnet_ids             = module.vpc.database_subnets
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.sg_rds.security_group_id]

  identifier = var.rds_name

  username             = "root"
  engine               = var.rds_engine
  family               = "${var.rds_family}${var.rds_engine_version}"
  engine_version       = var.rds_engine_version
  major_engine_version = var.rds_engine_version # split(".", var.rds_engine_version)[0]
  instance_class       = var.rds_instance_type
  db_name              = var.rds_db_name
  allocated_storage    = "10"
  skip_final_snapshot  = true
}

##############################
##### Headscale
##############################
module "headscale_admin_api_key" {
  source               = "terraform-aws-modules/ssm-parameter/aws"
  version              = "1.1.1"
  ignore_value_changes = true
  secure_type          = true
  name                 = "/headscale/headscale-admin/api-key"
  value                = "This will be modified by Headscale server during user_data execution"
  tags                 = var.tags
}

module "sg_headscale" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "headscale-sg"
  description = "Security group of EC2 Headscale"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 41641
      to_port     = 41641
      protocol    = "udp"
      description = "Headscale port UDP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 3478
      to_port     = 3478
      protocol    = "udp"
      description = "DERP relay port UDP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Headscale port TCP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Headscale port HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Headscale port HTTPS"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  egress_rules = ["all-all"]

  tags = var.tags
}

module "headscale_policy" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version     = "5.44.0"
  description = "Allows Headscale EC2 write a value to an SSM Parameter"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:PutParameter"
      ],
      "Effect": "Allow",
      "Resource": [
        "${module.subnet_router_pre_auth_key.ssm_parameter_arn}",
        "${module.headscale_admin_api_key.ssm_parameter_arn}"
      ]
    }
  ]
}
EOF
  tags        = var.tags
}

data "template_file" "derp_map" {
  template = file("./configs/derp_map.tpl")
  vars = {
    DERP_HOSTNAME         = local.derp_hostname
    DERP_SERVER_PUBLIC_IP = module.ec2_derp.public_ip
  }
}

data "template_file" "headscale_config" {
  template = file("./configs/headscale_config.tpl")
  vars = {
    HEADSCALE_HOSTNAME       = var.headscale_hostname
    SUBNET_ROUTER_PRIVATE_IP = local.subnet_router_private_ip
    PRIVATE_DOMAIN           = var.internal_hosted_zone
  }
}

data "template_file" "caddyfile" {
  template = file("./configs/caddyfile.tpl")
  vars = {
    ACME_EMAIL         = var.headscale_acme_email
    HEADSCALE_HOSTNAME = var.headscale_hostname
  }
}

data "template_file" "headscale_user_data" {
  template = file("./configs/headscale_server_user_data.tpl")
  vars = {
    HEADSCALE_CONFIG          = data.template_file.headscale_config.rendered
    HEADSCALE_VERSION         = var.headscale_version
    HEADSCALE_ADMIN_VERSION   = var.headscale_admin
    HEADSCALE_ARCH            = local.ec2_architecture[var.headscale_instance_type]
    HEADSCALE_HOSTNAME        = var.headscale_hostname
    PRE_AUTH_KEY_PARAMETER    = module.subnet_router_pre_auth_key.ssm_parameter_name
    HEADSCALE_ADMIN_PARAMETER = module.headscale_admin_api_key.ssm_parameter_name
    CADDYFILE                 = data.template_file.caddyfile.rendered
    DERP_MAP                  = data.template_file.derp_map.rendered
  }
}

module "ec2_headscale" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.0"

  name                   = "headscale"
  instance_type          = var.headscale_instance_type
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.sg_headscale.security_group_id]
  create_eip             = true
  ami                    = data.aws_ami.ubuntu[var.headscale_instance_type].id
  ignore_ami_changes     = true

  create_iam_instance_profile = true
  iam_role_policies = ({
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    SSMParameter                 = module.headscale_policy.arn
  })
  user_data_base64 = base64encode(data.template_file.headscale_user_data.rendered)

  metadata_options = {
    http_tokens = "required"
  }
  root_block_device = [
    { encrypted = true }
  ]

  tags = var.tags
}

resource "aws_route53_record" "headscale" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.headscale_hostname
  type    = "A"
  ttl     = "300"
  records = [module.ec2_headscale.public_ip]
}
##############################
##### Headscale Subnet Router
##############################
module "subnet_router_pre_auth_key" {
  source               = "terraform-aws-modules/ssm-parameter/aws"
  version              = "1.1.1"
  ignore_value_changes = true
  secure_type          = true
  name                 = "/headscale/subnet-router/pre-auth-key"
  value                = "This will be modified by Headscale server during user_data execution"
  tags                 = var.tags
}

module "sg_subnet_router" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "headscale-subnet-router-sg"
  description = "Security group of EC2 headscale-subnet-router"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 41641
      to_port     = 41641
      protocol    = "udp"
      description = "Enable direct connections to minimize latency - Headscale"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  ingress_with_ipv6_cidr_blocks = [
    {
      from_port        = 41641
      to_port          = 41641
      protocol         = "udp"
      description      = "Enable direct connections to minimize latency - Headscale IPv6"
      ipv6_cidr_blocks = "::/0"
    },
  ]
  egress_rules = ["all-all"]

  tags = var.tags
}

module "subnet_router_policy" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version     = "5.44.0"
  description = "Allows Subnet Router EC2 pull value from SSM Parameter"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter*"
      ],
      "Effect": "Allow",
      "Resource": "${module.subnet_router_pre_auth_key.ssm_parameter_arn}"
    }
  ]
}
EOF

  tags = var.tags
}

data "template_file" "subnet_router" {
  template = file("./configs/subnet_router_user_data.tpl")
  vars = {
    VPC_CIDR                 = var.vpc_cidr
    HEADSCALE_HOSTNAME       = var.headscale_hostname
    PRE_AUTH_KEY_PARAMETER   = module.subnet_router_pre_auth_key.ssm_parameter_name
    SUBNET_ROUTER_PRIVATE_IP = local.subnet_router_private_ip
  }
}

module "ec2_subnet_router" {
  source     = "terraform-aws-modules/ec2-instance/aws"
  version    = "5.7.0"
  depends_on = [module.ec2_headscale]

  name                        = "headscale-subnet-router"
  instance_type               = var.subnet_router_instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  private_ip                  = local.subnet_router_private_ip
  vpc_security_group_ids      = [module.sg_subnet_router.security_group_id]
  associate_public_ip_address = true
  ami                         = data.aws_ami.ubuntu[var.subnet_router_instance_type].id

  create_iam_instance_profile = true
  iam_role_policies = ({
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    SSMParameter                 = module.subnet_router_policy.arn
  })
  user_data_base64 = base64encode(data.template_file.subnet_router.rendered)

  metadata_options = {
    http_tokens = "required"
  }
  root_block_device = [
    { encrypted = true }
  ]

  tags = var.tags
}

##############################
##### Private Hosted Zone
##############################
resource "aws_route53_zone" "private" {
  name = var.internal_hosted_zone
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

##############################
##### Private Service
##############################
module "sg_private_service" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "private-service-sg"
  description = "Security group of EC2 Private Service"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Access to NGINX"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_rules = ["all-all"]

  tags = var.tags
}


data "template_file" "private_service" {
  template = file("./configs/private_service.tpl")
}

module "ec2_private_service" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.0"

  name                   = "private-service"
  instance_type          = var.private_service_instance_type
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [module.sg_private_service.security_group_id]

  ami                = data.aws_ami.ubuntu[var.headscale_instance_type].id
  ignore_ami_changes = true

  create_iam_instance_profile = true
  iam_role_policies = ({
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  })
  user_data_base64 = base64encode(data.template_file.private_service.rendered)

  metadata_options = {
    http_tokens = "required"
  }
  root_block_device = [
    { encrypted = true }
  ]

  tags = var.tags
}

resource "aws_route53_record" "private_service" {
  depends_on = [aws_route53_zone.private]

  zone_id = aws_route53_zone.private.id
  name    = "service.${var.internal_hosted_zone}"
  type    = "A"
  ttl     = "300"
  records = [module.ec2_private_service.private_ip]
}

##############################
##### DERP Server
##############################
module "sg_derp" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "derp-sg"
  description = "Security group of EC2 Derp"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP connections from clients"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS connections from clients"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "ICMP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 3478
      to_port     = 3478
      protocol    = "udp"
      description = "STUN"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_rules = ["all-all"]

  tags = var.tags
}

data "template_file" "derp" {
  template = file("./configs/derp_user_data.tpl")
  vars = {
    GO_VERSION    = var.go_version
    DERP_VERSION  = var.derp_version
    DERP_HOSTNAME = local.derp_hostname
    DERP_ARCH     = local.ec2_architecture[var.derp_instance_type]
  }
}

module "ec2_derp" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.0"

  name                   = "derp"
  instance_type          = var.derp_instance_type
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.sg_derp.security_group_id]
  create_eip             = true

  ami = data.aws_ami.ubuntu[var.derp_instance_type].id

  create_iam_instance_profile = true
  iam_role_policies = ({
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  })
  user_data_base64 = base64encode(data.template_file.derp.rendered)

  metadata_options = {
    http_tokens = "required"
  }
  root_block_device = [
    { encrypted = true }
  ]

  tags = var.tags
}

resource "aws_route53_record" "derp" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.derp_hostname
  type    = "A"
  ttl     = "300"
  records = [module.ec2_derp.public_ip]
}
