# infrastructure

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.65.0 |
| <a name="requirement_template"></a> [template](#requirement\_template) | ~> 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.65.0 |
| <a name="provider_template"></a> [template](#provider\_template) | ~> 2.2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ec2_derp"></a> [ec2\_derp](#module\_ec2\_derp) | terraform-aws-modules/ec2-instance/aws | 5.7.0 |
| <a name="module_ec2_headscale"></a> [ec2\_headscale](#module\_ec2\_headscale) | terraform-aws-modules/ec2-instance/aws | 5.7.0 |
| <a name="module_ec2_private_service"></a> [ec2\_private\_service](#module\_ec2\_private\_service) | terraform-aws-modules/ec2-instance/aws | 5.7.0 |
| <a name="module_ec2_subnet_router"></a> [ec2\_subnet\_router](#module\_ec2\_subnet\_router) | terraform-aws-modules/ec2-instance/aws | 5.7.0 |
| <a name="module_headscale_admin_api_key"></a> [headscale\_admin\_api\_key](#module\_headscale\_admin\_api\_key) | terraform-aws-modules/ssm-parameter/aws | 1.1.1 |
| <a name="module_headscale_policy"></a> [headscale\_policy](#module\_headscale\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.44.0 |
| <a name="module_rds"></a> [rds](#module\_rds) | terraform-aws-modules/rds/aws | 6.9.0 |
| <a name="module_sg_derp"></a> [sg\_derp](#module\_sg\_derp) | terraform-aws-modules/security-group/aws | 5.2.0 |
| <a name="module_sg_headscale"></a> [sg\_headscale](#module\_sg\_headscale) | terraform-aws-modules/security-group/aws | 5.2.0 |
| <a name="module_sg_private_service"></a> [sg\_private\_service](#module\_sg\_private\_service) | terraform-aws-modules/security-group/aws | 5.2.0 |
| <a name="module_sg_rds"></a> [sg\_rds](#module\_sg\_rds) | terraform-aws-modules/security-group/aws | 5.2.0 |
| <a name="module_sg_subnet_router"></a> [sg\_subnet\_router](#module\_sg\_subnet\_router) | terraform-aws-modules/security-group/aws | 5.2.0 |
| <a name="module_subnet_router_policy"></a> [subnet\_router\_policy](#module\_subnet\_router\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.44.0 |
| <a name="module_subnet_router_pre_auth_key"></a> [subnet\_router\_pre\_auth\_key](#module\_subnet\_router\_pre\_auth\_key) | terraform-aws-modules/ssm-parameter/aws | 1.1.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | v5.13.0 |

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.derp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.headscale](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.private_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_ec2_instance_type.architecture](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [template_file.caddyfile](https://registry.terraform.io/providers/cloudposse/template/latest/docs/data-sources/file) | data source |
| [template_file.derp](https://registry.terraform.io/providers/cloudposse/template/latest/docs/data-sources/file) | data source |
| [template_file.derp_map](https://registry.terraform.io/providers/cloudposse/template/latest/docs/data-sources/file) | data source |
| [template_file.headscale_config](https://registry.terraform.io/providers/cloudposse/template/latest/docs/data-sources/file) | data source |
| [template_file.headscale_user_data](https://registry.terraform.io/providers/cloudposse/template/latest/docs/data-sources/file) | data source |
| [template_file.private_service](https://registry.terraform.io/providers/cloudposse/template/latest/docs/data-sources/file) | data source |
| [template_file.subnet_router](https://registry.terraform.io/providers/cloudposse/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region to deploy resources | `string` | n/a | yes |
| <a name="input_derp_instance_type"></a> [derp\_instance\_type](#input\_derp\_instance\_type) | Instance type of the EC2 that will serve as DERP server | `string` | `"t4g.small"` | no |
| <a name="input_derp_version"></a> [derp\_version](#input\_derp\_version) | Version to install DERP server. Check available versions here: https://pkg.go.dev/tailscale.com/cmd/derper?tab=versions | `string` | `"v1.82.4"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain managed by Route53 | `string` | n/a | yes |
| <a name="input_go_version"></a> [go\_version](#input\_go\_version) | Go version used to install DERP server. Check available versions here: https://go.dev/dl/ | `string` | `"1.24.2"` | no |
| <a name="input_headscale_acme_email"></a> [headscale\_acme\_email](#input\_headscale\_acme\_email) | ACME email to use to send emails about HTTP-01 certification using Let's Encrypt. All versions available at https://github.com/juanfont/headscale/releases | `string` | n/a | yes |
| <a name="input_headscale_admin"></a> [headscale\_admin](#input\_headscale\_admin) | Headscale Admin version to install. All versions available at https://github.com/GoodiesHQ/headscale-admin/releases | `string` | `"0.25.6"` | no |
| <a name="input_headscale_hostname"></a> [headscale\_hostname](#input\_headscale\_hostname) | Hostname used to access Headscale. | `string` | n/a | yes |
| <a name="input_headscale_instance_type"></a> [headscale\_instance\_type](#input\_headscale\_instance\_type) | Required if 'deployment\_mode' is EC2. Instance type to deploy Headscale server | `string` | `"t4g.small"` | no |
| <a name="input_headscale_version"></a> [headscale\_version](#input\_headscale\_version) | Headscale version to install. All versions available at https://github.com/juanfont/headscale/releases | `string` | `"0.25.1"` | no |
| <a name="input_internal_hosted_zone"></a> [internal\_hosted\_zone](#input\_internal\_hosted\_zone) | Name of the internal Hosted zone to create | `string` | `"internal"` | no |
| <a name="input_private_service_instance_type"></a> [private\_service\_instance\_type](#input\_private\_service\_instance\_type) | Instance type to create the instance that will host a private website (NGINX) | `string` | `"t4g.nano"` | no |
| <a name="input_rds_db_name"></a> [rds\_db\_name](#input\_rds\_db\_name) | Name of the RDS database to create | `string` | `"mydb"` | no |
| <a name="input_rds_engine"></a> [rds\_engine](#input\_rds\_engine) | RDS Engine to select. Check available engines at https://docs.aws.amazon.com/cli/latest/reference/rds/describe-db-engine-versions.html | `string` | `"mysql"` | no |
| <a name="input_rds_engine_version"></a> [rds\_engine\_version](#input\_rds\_engine\_version) | RDS engine version to select. Check available engine versions at https://docs.aws.amazon.com/cli/latest/reference/rds/describe-db-engine-versions.html | `string` | `"8.0"` | no |
| <a name="input_rds_family"></a> [rds\_family](#input\_rds\_family) | The family of the DB parameter group. Check available DB parameter group at https://docs.aws.amazon.com/cli/latest/reference/rds/describe-db-engine-versions.html | `string` | `"mysql"` | no |
| <a name="input_rds_instance_type"></a> [rds\_instance\_type](#input\_rds\_instance\_type) | Instance type of RDS | `string` | `"db.t4g.micro"` | no |
| <a name="input_rds_name"></a> [rds\_name](#input\_rds\_name) | Name of the RDS to create | `string` | `"my-rds"` | no |
| <a name="input_subnet_router_instance_type"></a> [subnet\_router\_instance\_type](#input\_subnet\_router\_instance\_type) | Instance type of the EC2 that will serve as subnet router | `string` | `"t4g.small"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Default tags used to tag all resources created in this module | `map(string)` | `{}` | no |
| <a name="input_vpc_azs_number"></a> [vpc\_azs\_number](#input\_vpc\_azs\_number) | Number of AZs to use when deploying the VPC | `number` | `2` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR of the VPC | `string` | `"10.100.0.0/16"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name of the VPN to create | `string` | `"my-vpc"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_amis"></a> [amis](#output\_amis) | All AMI used based on the instance type selected |
| <a name="output_headscale_ec2"></a> [headscale\_ec2](#output\_headscale\_ec2) | EC2 that has Headscale installed |
| <a name="output_headscale_ip"></a> [headscale\_ip](#output\_headscale\_ip) | Public IP of the Headscale server |
<!-- END_TF_DOCS -->
