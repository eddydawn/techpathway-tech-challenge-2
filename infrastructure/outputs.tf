
# Jenkins public IP address
output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.public_ip
}

# Jenkins URL
output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

# Application Load Balancer DNS
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

# Application URL
output "application_url" {
  description = "Public URL of the application"
  value       = "http://${aws_lb.main.dns_name}"
}

# Frontend ECR repository
output "frontend_ecr_url" {
  description = "Frontend Docker image repository"
  value       = aws_ecr_repository.frontend.repository_url
}

# Backend ECR repository
output "backend_ecr_url" {
  description = "Backend Docker image repository"
  value       = aws_ecr_repository.backend.repository_url
}

# ECS Cluster name
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}
