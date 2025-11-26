############################################
# Get AWS Account ID
############################################
data "aws_caller_identity" "current" {}

############################################
# CodeBuild Project
############################################
resource "aws_codebuild_project" "build_all" {
  name         = "${var.project_name}-build-all"
  description  = "Build Docker images and push to ECR"
  service_role = aws_iam_role.codebuild.arn

  ############################################
  # ENVIRONMENT — Docker-enabled Build Env
  ############################################
  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true  # Required for Docker builds

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }
  }

  ############################################
  # SOURCE — From CodePipeline Artifact
  ############################################
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  ############################################
  # ARTIFACTS — Deliver Back to Pipeline
  ############################################
  artifacts {
    type = "CODEPIPELINE"
  }

  ############################################
  # LOCAL CACHE — Faster Docker Builds
  ############################################
  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  ############################################
  # Stability: Avoid recreation on minor change
  ############################################
  lifecycle {
    create_before_destroy = true
  }
}
