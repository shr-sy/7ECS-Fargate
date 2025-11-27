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
# Terraform Cloud/HCP Execution Role
# ----------------------------------------------------------------------
variable "terraform_role_name" {
  description = "IAM role name used by HCP Terraform"
  type        = string
  default     = "terraform-execution-role"
}

# ----------------------------------------------------------------------
# GitHub Settings
# ----------------------------------------------------------------------
variable "github_owner" {
  description = "GitHub username or organization"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "Branch monitored by CodePipeline"
  type        = string
  default     = "main"
}

# ----------------------------------------------------------------------
# Secrets Manager — Secret Names (not values)
# These will be created if not existing
# ----------------------------------------------------------------------
variable "github_oauth_token_secret_name" {
  description = "Name of Secrets Manager secret storing GitHub PAT"
  type        = string
  default     = "hcp-ecs-github-token"
}

variable "github_webhook_secret_name" {
  description = "Name of Secrets Manager secret storing webhook shared secret"
  type        = string
  default     = "github-webhook-secret"
}

# ----------------------------------------------------------------------
# Actual secret values supplied via HCP Terraform variables
# ----------------------------------------------------------------------
variable "github_oauth_token" {
  description = "GitHub Personal Access Token (PAT)"
  type        = string
  sensitive   = true
}

variable "github_webhook_secret" {
  description = "Webhook secret used for GitHub → CodePipeline"
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------------
# ECS Microservices & Ports
# ----------------------------------------------------------------------
variable "services" {
  description = "List of microservices deployed to ECS"
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
  description = "Primary microservice used behind the ALB"
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
  description = "Public subnets used by ALB"
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

# ----------------------------------------------------------------------
# CodePipeline Bucket Suffix (optional)
# ----------------------------------------------------------------------
variable "bucket_suffix" {
  description = "Suffix used for CodePipeline artifact bucket"
  type        = string
  default     = "cp"
}
