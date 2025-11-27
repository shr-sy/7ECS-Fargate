provider "aws" {
  region                  = var.aws_region
  skip_metadata_api_check = true

  # HCP Terraform automatically assumes the IAM role created in iam.tf
  assume_role {
    role_arn = aws_iam_role.terraform_execution_role.arn
  }

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
    }
  }
}
