# ----------------------------
# ECS Cluster
# ----------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

# ----------------------------
# CloudWatch Log Group
# ----------------------------
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

# ----------------------------
# ECS Task Definitions
# One per microservice
# ----------------------------
resource "aws_ecs_task_definition" "task" {
  for_each = toset(var.services)

  family                   = "${var.project_name}-${each.value}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn

  container_definitions = jsonencode([
    {
      name      = each.value
      image     = "${aws_ecr_repository.services[each.value].repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.service_ports[each.value]
          hostPort      = var.service_ports[each.value]
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = each.value
        }
      }
    }
  ])
}

# ----------------------------
# ECS Services (One for each microservice)
# ----------------------------
resource "aws_ecs_service" "svc" {
  for_each = toset(var.services)

  name            = "${var.project_name}-${each.value}-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.task[each.value].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for s in aws_subnet.private : s.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg[each.value].arn
    container_name   = each.value
    container_port   = var.service_ports[each.value]
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener_rule.rules
  ]
}
