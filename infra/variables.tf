# ----------------------------------------------------------------------
# AWS & Project Settings
# ----------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region where all resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base prefix for naming all AWS resources"
  type        = string
  default     = "hcp-ecs-7svc"
}

variable "environment" {
  description = "Deployment environment (dev, qa, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, prod."
  }
}

# ----------------------------------------------------------------------
# Terraform Cloud User ARN (Required for IAM Assume Role)
# ----------------------------------------------------------------------
variable "terraform_user_arn" {
  description = "ARN of the Terraform Cloud/HCP Terraform user/role"
  type        = string
}

# ----------------------------------------------------------------------
# GitHub Settings
# ----------------------------------------------------------------------
variable "github_owner" {
  description = "GitHub username or organization"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name (without owner)"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch monitored by CodePipeline"
  type        = string
  default     = "main"
}

# ----------------------------------------------------------------------
# GitHub Personal Access Token (PAT) - Stored in Secrets Manager
# ----------------------------------------------------------------------
variable "github_oauth_token_secret_name" {
  description = "Name of AWS Secrets Manager secret storing GitHub PAT"
  type        = string
}

variable "github_oauth_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------------
# GitHub Webhook Secret (HMAC Key)
# ----------------------------------------------------------------------
variable "github_webhook_secret_name" {
  description = "Name of AWS Secrets Manager secret storing webhook secret"
  type        = string
}

variable "github_webhook_secret" {
  description = "HMAC secret for GitHub → CodePipeline webhook"
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------------
# Microservices & Ports
# ----------------------------------------------------------------------
variable "services" {
  description = "List of microservices for ECS, ECR, CodeBuild"
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
  description = "Primary microservice used by ALB for routing"
  type        = string
  default     = "auth"
}

# ----------------------------------------------------------------------
# Networking
# ----------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnets used for ALB"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnets" {
  description = "Private subnets used for ECS Fargate"
  type        = list(string)
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}
