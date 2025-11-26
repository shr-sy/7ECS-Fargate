output "alb_dns" { 
  value = aws_lb.alb.dns_name 
}

output "ecr_repos" { 
  value = { for k, r in aws_ecr_repository.services : k => r.repository_url } 
}

output "ecs_cluster" { 
  value = aws_ecs_cluster.main.id 
}
