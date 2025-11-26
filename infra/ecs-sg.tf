resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = aws_vpc.this.id

  # Allow ALB to reach ECS tasks on all service ports
  dynamic "ingress" {
    for_each = var.service_ports
    content {
      description    = "Allow ALB to reach ${ingress.key} service"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.alb_sg.id]
    }
  }

  # Allow tasks to reach the internet (e.g., DB, external APIs)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
