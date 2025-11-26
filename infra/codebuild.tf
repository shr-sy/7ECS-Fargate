data "aws_caller_identity" "current" {}

resource "aws_codebuild_project" "build_all" {
  name         = "${var.project_name}-build-all"
  description  = "Build Docker images and push to ECR"
  service_role = aws_iam_role.codebuild.arn

  # ----------------------------
  # ENVIRONMENT (Docker enabled)
  # ----------------------------
  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true # required for docker build

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
  }

  # ----------------------------
  # SOURCE FROM CODEPIPELINE
  # ----------------------------
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec.yml"
  }

  # ----------------------------
  # ARTIFACTS BACK TO PIPELINE
  # ----------------------------
  artifacts {
    type = "CODEPIPELINE"
  }

  # Optional — improves stability
  cache {
    type     = "LOCAL"
    modes    = ["LOCAL_DOCKER_LAYER_CACHE"]
  }
}
