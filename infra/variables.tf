variable "aws_region" { default = "us-east-1" }
variable "project_name" { default = "hcp-ecs-7svc" }
variable "github_repo" { description = "shr-sy/7ECS-Fargate" }
variable "github_oauth_token" { description = "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" }

variable "services" {
  type = list(string)
  default = ["auth","users","orders","products","payments","notifications","reports"]
}

variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "public_subnets" { default = ["10.0.1.0/24","10.0.2.0/24"] }
variable "private_subnets" { default = ["10.0.11.0/24","10.0.12.0/24"] }
