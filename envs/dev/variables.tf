variable "my_ip" {
  description = "Your public IP address to allow SSH"
  type        = string
}

variable "aws_region" {
  description = "La región AWS donde desplegar los recursos"
  type        = string
  default     = "us-east-1"
}
