# --- ALB ---
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for s in aws_subnet.public : s.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

# --- Target Groups for 7 Microservices ---
resource "aws_lb_target_group" "tg" {
  for_each = toset(var.services)

  name        = "${var.project_name}-${each.value}-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path     = "/health"
    interval = 30
  }
}

# --- ALB Listener ---
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No route"
      status_code  = "404"
    }
  }
}

# --- Listener Rules for Each Service ---
resource "aws_lb_listener_rule" "rules" {
  for_each = toset(var.services)

  listener_arn = aws_lb_listener.http.arn

  # Priority must be unique
  priority = 100 + index(var.services, each.value)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.value].arn
  }

  condition {
    path_pattern {
      values = [
        "/${each.value}/*",
        "/${each.value}"
      ]
    }
  }
}
