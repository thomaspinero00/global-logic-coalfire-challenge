variable "my_ip" {
  description = "Your public IP address to allow SSH"
  type        = string
}

variable "aws_region" {
  description = "The AWS region where the resources will be deployed"
  type        = string
  default     = "us-east-1"
}
