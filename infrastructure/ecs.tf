
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# Frontend CloudWatch Log Group
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}/frontend"
  retention_in_days = 7
}

# Backend CloudWatch Log Group
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}/backend"
  retention_in_days = 7
}

# Frontend ECS Task Definition
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name = "${var.project_name}-frontend-task"
  }
}

# Backend ECS Task Definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.backend.repository_url}:latest"
      essential = true

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "CORS_ORIGIN"
          value = "http://${aws_lb.main.dns_name}"
        }
      ]

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name = "${var.project_name}-backend-task"
  }
}

# Frontend ECS Service
resource "aws_ecs_service" "frontend" {
  name             = "${var.project_name}-frontend-service"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.frontend.arn
  desired_count    = 0
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets = [
      aws_subnet.jenkins_public.id,
      aws_subnet.public_2.id
    ]

    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http
  ]

  tags = {
    Name = "${var.project_name}-frontend-service"
  }
}

# Backend ECS Service
resource "aws_ecs_service" "backend" {
  name             = "${var.project_name}-backend-service"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.backend.arn
  desired_count    = 0
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets = [
      aws_subnet.jenkins_public.id,
      aws_subnet.public_2.id
    ]

    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8080
  }

  depends_on = [
    aws_lb_listener_rule.backend_api
  ]

  tags = {
    Name = "${var.project_name}-backend-task"
  }
}
