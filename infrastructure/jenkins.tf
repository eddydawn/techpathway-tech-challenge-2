
# Find the latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Jenkins EC2 Instance
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.jenkins_instance_type
  subnet_id                   = aws_subnet.jenkins_public.id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  associate_public_ip_address = true

  # Install Jenkins, Java 21 and Docker automatically
  user_data = <<-EOF
    #!/bin/bash
    set -e

    apt-get update -y

    apt-get install -y \
      fontconfig \
      openjdk-21-jre \
      docker.io \
      awscli \
      wget \
      curl \
      ca-certificates

    systemctl enable docker
    systemctl start docker

    mkdir -p /usr/share/keyrings

    wget -qO- https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
      > /usr/share/keyrings/jenkins-keyring.asc

    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
      > /etc/apt/sources.list.d/jenkins.list

    apt-get update -y
    apt-get install -y jenkins

    usermod -aG docker jenkins

    systemctl enable jenkins
    systemctl restart jenkins
  EOF

  user_data_replace_on_change = false

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-jenkins-server"
  }
}
