provider "aws" {
  region = var.aws_region
  skip_metadata_api_check = true

  default_tags {
    tags = {
      Project = var.project_name
    }
  }
}
