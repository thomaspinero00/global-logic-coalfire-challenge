output "alb_dns_name" {
  description = "Public HTTP endpoint of the Application Load Balancer"
  value       = "http://${module.alb.dns_name}"
}

output "standalone_ec2_ssh_command" {
  description = "SSH command to access the standalone EC2 instance"
  value       = "ssh -i global-logic-key.pem ec2-user@${module.standalone_ec2.public_ip}"
}
