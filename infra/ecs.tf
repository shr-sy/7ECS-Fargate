#########################################
# ECS Cluster
#########################################
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

#########################################
# CloudWatch Logs
#########################################
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

#########################################
# ECS Task Definitions - One per microservice
#########################################
resource "aws_ecs_task_definition" "task" {
  for_each = toset(var.services)

  family                   = "${var.project_name}-${each.value}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  # IAM Roles
  execution_role_arn = aws_iam_role.ecs_task_exec.arn
  task_role_arn      = aws_iam_role.ecs_task_exec.arn

  container_definitions = jsonencode([
    {
      name      = each.value
      image     = "${aws_ecr_repository.services[each.value].repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.service_ports[each.value]
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = each.value
        }
      }
    }
  ])
}

#########################################
# ECS Services - One per microservice
#########################################
resource "aws_ecs_service" "svc" {
  for_each            = toset(var.services)
  name                = "${var.project_name}-${each.value}-svc"
  cluster             = aws_ecs_cluster.main.id
  task_definition     = aws_ecs_task_definition.task[each.value].arn
  desired_count       = 1
  launch_type         = "FARGATE"
  propagate_tags      = "SERVICE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnets     # 🔥 FIXED: Correct variable name
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg[each.value].arn
    container_name   = each.value
    container_port   = var.service_ports[each.value]
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.tg
  ]
}

#########################################
# ECS Task Security Group
#########################################
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Allow ALB to reach ECS tasks"
  vpc_id      = aws_vpc.this.id

  # ALB → ECS Inbound rules dynamically per-port
  dynamic "ingress" {
    for_each = var.service_ports
    content {
      description     = "Allow ALB traffic to ${ingress.key}"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.alb_sg.id]
    }
  }

  # Outbound: Allow tasks to reach internet (pull images)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#########################################
# Output - ECS Service Info
#########################################
output "ecs_services" {
  value = {
    for k, svc in aws_ecs_service.svc :
    k => {
      id   = svc.id
      name = svc.name
      arn  = svc.id
    }
  }
}
