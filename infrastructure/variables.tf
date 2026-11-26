
variable "aws_region" {
  description = "AWS region where project infrastructure will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for project resources"
  type        = string
  default     = "techpathway-challenge-2"
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.small"
}

variable "my_ip" {
  description = "Your public IPv4 address with /32 CIDR suffix"
  type        = string
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
}
