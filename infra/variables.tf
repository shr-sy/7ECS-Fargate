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
  description = "GitHub repository name (without owner)"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch monitored by CodePipeline"
  type        = string
  default     = "main"
}

# ----------------------------------------------------------------------
# GitHub Secrets Manager Config (Names only)
# ----------------------------------------------------------------------
variable "github_oauth_token_secret_name" {
  description = "Name of Secrets Manager secret storing GitHub PAT"
  type        = string
  default     = "hcp-ecs-github-token"
}

variable "github_webhook_secret_name" {
  description = "Name of Secrets Manager secret storing webhook secret"
  type        = string
  default     = "github-webhook-secret"
}

# ----------------------------------------------------------------------
# Secrets Supplied by HCP Terraform (Actual values)
# ----------------------------------------------------------------------
variable "github_oauth_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_webhook_secret" {
  description = "Webhook secret for GitHub → CodePipeline"
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------------
# Microservices & Ports
# ----------------------------------------------------------------------
variable "services" {
  description = "List of microservices for ECS, ECR, and CodeBuild"
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
  description = "Primary microservice used by ALB"
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

############################################
# VARIABLES
############################################

variable "project_name" {
  description = "Project name prefix used for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev|qa|prod)"
  type        = string
  default     = "dev"
}

variable "bucket_suffix" {
  description = "Suffix used in the artifact bucket name"
  type        = string
  default     = "cp"
}

variable "github_owner" {
  type = string
}

variable "github_repo_name" {
  type = string
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "github_oauth_secret_id" {
  description = "Secrets Manager secret name or ARN containing GitHub OAuth token"
  type        = string
}

variable "github_webhook_secret" {
  type = string
}

variable "services" {
  description = "List/map of service names used in the Deploy stage"
  type        = any
}

