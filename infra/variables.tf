# ----------------------------------------------------------------------
# AWS & Project Settings
# ----------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region where all resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base prefix for naming resources"
  type        = string
  default     = "hcp-ecs-7svc"
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  default     = "dev"
}

# ----------------------------------------------------------------------
# GitHub Settings (CodePipeline + Webhook)
# ----------------------------------------------------------------------
variable "github_owner" {
  description = "GitHub username or organization name"
  type        = string
}

variable "github_repo_name" {
  description = "Repository name only (without owner)"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch CodePipeline will monitor"
  type        = string
  default     = "main"
}

# ----------------------------------------------------------------------
# GitHub OAuth Token (PAT) stored in AWS Secrets Manager
# ----------------------------------------------------------------------
variable "github_oauth_token_secret_name" {
  description = "Name of secret in AWS Secrets Manager storing the PAT"
  type        = string
}

variable "github_oauth_token" {
  description = "GitHub Personal Access Token (PAT) value"
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------------
# GitHub Webhook Secret (HMAC)
# ----------------------------------------------------------------------
variable "github_webhook_secret_name" {
  description = "Name of the secret that stores GitHub webhook HMAC secret"
  type        = string
}

variable "github_webhook_secret" {
  description = "Webhook secret (HMAC) for GitHub → CodePipeline triggers"
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------------
# Microservices List & Ports
# ----------------------------------------------------------------------
variable "services" {
  description = "List of microservices (used for ECR, ECS, CodeBuild)"
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
  description = "Primary microservice that ALB forwards traffic to"
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
  description = "Private subnets for ECS Fargate tasks"
  type        = list(string)

  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

variable "terraform_role_name" {
  description = "IAM role Terraform is using"
  type        = string
}
