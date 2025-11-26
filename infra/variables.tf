# ---------------------------
# AWS & Project Settings
# ---------------------------
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base name prefix for all AWS resources"
  type        = string
  default     = "hcp-ecs-7svc"
}

# ---------------------------
# GitHub Settings (for CodeStar)
# ---------------------------
variable "github_repo" {
  description = "GitHub repository in owner/repo format (e.g., shr-sy/7ECS-Fargate)"
  type        = string
  default     = "shr-sy/7ECS-Fargate"
}

variable "github_branch" {
  description = "GitHub branch used for CI/CD CodePipeline"
  type        = string
  default     = "main"
}

# ---------------------------
# Microservices Settings
# ---------------------------
variable "services" {
  description = "List of microservices to build & deploy"
  type        = list(string)

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

variable "service_ports" {
  description = "Port mapping for each microservice"
  type        = map(number)

  default = {
    auth          = 3001
    users         = 3002
    orders        = 3003
    products      = 3004
    payments      = 3005
    notifications = 3006
    reports       = 3007
  }
}

variable "main_service" {
  description = "Service that ECS will run as the main entrypoint"
  type        = string
  default     = "auth"
}

# ---------------------------
# Networking (VPC/Subnets)
# ---------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnets for ALB"
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnets" {
  description = "Private subnets for ECS Fargate tasks"
  type        = list(string)

  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}
