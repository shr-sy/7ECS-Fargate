# ----------------------------------------------------------------------
# AWS & Project Settings
# ----------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region where all resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base prefix for naming resources (keeps infra organized)"
  type        = string
  default     = "hcp-ecs-7svc"
}

# ----------------------------------------------------------------------
# GitHub Settings (for AWS CodeStar Connection + CodePipeline)
# ----------------------------------------------------------------------
variable "github_repo" {
  description = "GitHub repository in owner/repo format"
  type        = string
  default     = "shr-sy/7ECS-Fargate"
}

variable "github_branch" {
  description = "GitHub branch CodePipeline will listen to"
  type        = string
  default     = "main"
}

# ----------------------------------------------------------------------
# Microservices List & Runtime Ports
# ----------------------------------------------------------------------
variable "services" {
  description = "List of microservices used for ECR, ECS & CodeBuild"
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
  description = "Port mapping for each microservice container"
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

# ECS needs to know which service is deployed behind ALB
variable "main_service" {
  description = "Primary microservice deployed behind ALB"
  type        = string
  default     = "auth"
}

# ----------------------------------------------------------------------
# Networking Variables
# ----------------------------------------------------------------------
variable "vpc_cidr" {
  description = "VPC CIDR block"
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
  description = "Private subnets for ECS tasks"
  type        = list(string)
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}
