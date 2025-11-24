resource "aws_codebuild_project" "build_all" {
  name          = "${var.project_name}-build-all"
  description   = "Build all microservices and push images to ECR"
  service_role  = aws_iam_role.codebuild.arn

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable { name = "AWS_DEFAULT_REGION"; value = var.aws_region }
  }

  source {
    type = "GITHUB"
    location = "https://github.com/${var.github_repo}.git"
    buildspec = file("${path.module}/../buildspec.yml")
  }

  artifacts { type = "NO_ARTIFACTS" }
}

data "aws_caller_identity" "current" {}
