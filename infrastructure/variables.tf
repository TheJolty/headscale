variable "domain" {
  description = "Domain managed by Route53"
  type        = string
}

##############################
##### AWS RELATED
##############################
variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
}

variable "tags" {
  description = "Default tags used to tag all resources created in this module"
  type        = map(string)
  default     = {}
}

##############################
##### NETWORKING
##############################
variable "vpc_name" {
  description = "Name of the VPN to create"
  type        = string
  default     = "my-vpc"
}

variable "vpc_azs_number" {
  description = "Number of AZs to use when deploying the VPC"
  type        = number
  default     = 2
}

variable "vpc_cidr" {
  description = "CIDR of the VPC"
  type        = string
  default     = "10.100.0.0/16"
}

##############################
##### DNS
##############################
variable "internal_hosted_zone" {
  description = "Name of the internal Hosted zone to create"
  type        = string
  default     = "internal"
}

##############################
##### DATABASE
##############################
variable "rds_name" {
  description = "Name of the RDS to create"
  type        = string
  default     = "my-rds"
}

variable "rds_engine" {
  description = "RDS Engine to select. Check available engines at https://docs.aws.amazon.com/cli/latest/reference/rds/describe-db-engine-versions.html"
  type        = string
  default     = "mysql"
}

variable "rds_engine_version" {
  description = "RDS engine version to select. Check available engine versions at https://docs.aws.amazon.com/cli/latest/reference/rds/describe-db-engine-versions.html"
  type        = string
  default     = "8.0"
}

variable "rds_family" {
  description = "The family of the DB parameter group. Check available DB parameter group at https://docs.aws.amazon.com/cli/latest/reference/rds/describe-db-engine-versions.html"
  type        = string
  default     = "mysql"
}

variable "rds_instance_type" {
  description = "Instance type of RDS"
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_db_name" {
  description = "Name of the RDS database to create"
  type        = string
  default     = "mydb"
}

##############################
##### Headscale
##############################
variable "private_service_instance_type" {
  description = "Instance type to create the instance that will host a private website (NGINX)"
  type        = string
  default     = "t4g.nano"
}

##############################
##### Headscale
##############################
variable "headscale_instance_type" {
  description = "Required if 'deployment_mode' is EC2. Instance type to deploy Headscale server"
  type        = string
  default     = "t4g.small"
}

variable "headscale_version" {
  description = "Headscale version to install. All versions available at https://github.com/juanfont/headscale/releases"
  type        = string
  default     = "0.25.1"
}

variable "headscale_admin" {
  description = "Headscale Admin version to install. All versions available at https://github.com/GoodiesHQ/headscale-admin/releases"
  type        = string
  default     = "0.25.6"
}

variable "headscale_acme_email" {
  description = "ACME email to use to send emails about HTTP-01 certification using Let's Encrypt. All versions available at https://github.com/juanfont/headscale/releases"
  type        = string
}

variable "headscale_hostname" {
  description = "Hostname used to access Headscale."
  type        = string
}

##############################
##### Headscale EC2 Subnet Router
##############################
variable "subnet_router_instance_type" {
  description = "Instance type of the EC2 that will serve as subnet router"
  type        = string
  default     = "t4g.small"
}

##############################
##### DERP server
##############################
variable "go_version" {
  description = "Go version used to install DERP server. Check available versions here: https://go.dev/dl/"
  type        = string
  default     = "1.24.2"
}

variable "derp_instance_type" {
  description = "Instance type of the EC2 that will serve as DERP server"
  type        = string
  default     = "t4g.small"
}

variable "derp_version" {
  description = "Version to install DERP server. Check available versions here: https://pkg.go.dev/tailscale.com/cmd/derper?tab=versions"
  type        = string
  default     = "v1.82.4"
}
