output "alb_dns_name" {
  description = "Endpoint público HTTP del Application Load Balancer"
  value       = "http://${module.alb.dns_name}"
}

output "standalone_ec2_ssh_command" {
  description = "Comando SSH para acceder a la EC2 standalone"
  value       = "ssh -i global-logic-key.pem ec2-user@${module.standalone_ec2.public_ip}"
}
