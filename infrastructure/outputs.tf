output "headscale_ip" {
  description = "Public IP of the Headscale server"
  value       = try(module.ec2_headscale.public_ip, "")
}

output "headscale_ec2" {
  description = "EC2 that has Headscale installed"
  value       = try(module.ec2_headscale.id, "")
}

output "amis" {
  description = "All AMI used based on the instance type selected"
  value       = { for instance_type, values in data.aws_ami.ubuntu : instance_type => values.id }
}
