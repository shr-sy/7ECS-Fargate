variable "aws_region" { default = "ap-south-1" }
variable "project_name" { default = "hcp-ecs-7svc" }
variable "github_repo" { description = "owner/repo" }
variable "github_oauth_token" { description = "GitHub OAuth token (sensitive)" }

variable "services" {
  type = list(string)
  default = ["auth","users","orders","products","payments","notifications","reports"]
}

variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "public_subnets" { default = ["10.0.1.0/24","10.0.2.0/24"] }
variable "private_subnets" { default = ["10.0.11.0/24","10.0.12.0/24"] }
