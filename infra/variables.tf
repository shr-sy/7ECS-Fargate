# ---------------------------
# AWS & Project Settings
# ---------------------------
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base name for all resources"
  type        = string
  default     = "hcp-ecs-7svc"
}

# ---------------------------
# GitHub Settings
# ---------------------------
variable "github_repo" {
  description = "GitHub repository in owner/repo format"
  type        = string
  default     = "shr-sy/7ECS-Fargate"
}

variable "github_oauth_token" {
  description = "GitHub token (store securely in Terraform Cloud variables)"
  type        = string
}

# ---------------------------
# Microservices
# ---------------------------
variable "services" {
  description = "List of microservices"
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
    auth           = 3001
    users          = 3002
    orders         = 3003
    products       = 3004
    payments       = 3005
    notifications  = 3006
    reports        = 3007
  }
}

# 🚨 IMPORTANT: Tell ECS which service is the MAIN service to run
variable "main_service" {
  description = "Which service ECS should run as the main container/service"
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
