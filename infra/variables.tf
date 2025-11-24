variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "hcp-ecs-7svc"
}

variable "github_repo" {
  description = "GitHub repository in owner/repo format"
  default     = "shr-sy/7ECS-Fargate"
}

# DO NOT store token in variables.tf — put it in TF Cloud or TFVars
variable "github_oauth_token" {
  description = "GitHub token (store securely in Terraform Cloud variables)"
  type        = string
}

# List of microservices
variable "services" {
  type = list(string)
  default = [
    "auth",
    "users",
    "orders",
    "products",
    "payments",
    "notifications",
    "reports"
  ]
}

# Port mapping for each service (required for ALB target groups)
variable "service_ports" {
  type = map(number)

  default = {
    auth           = 3001
    users          = 3002
    orders         = 3003
    products       = 3004
    payments       = 3005
    notifications  = 3006
    reports        = 3007
  }
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}
