resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for s in aws_subnet.public : s.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  for_each = toset(var.services)

  name     = "${var.project_name}-${each.key}-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    path     = "/health"
    interval = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
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

resource "aws_lb_listener_rule" "rules" {
  for_each = toset(var.services)

  listener_arn = aws_lb_listener.http.arn
  priority     = 100 + tonumber(format("%d", index(var.services, each.key)))

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }

  condition {
    path_pattern {
      values = ["/${each.key}/*", "/${each.key}"]
    }
  }
}
