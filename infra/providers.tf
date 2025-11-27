provider "aws" {
  region                  = var.aws_region
  skip_metadata_api_check = true

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
