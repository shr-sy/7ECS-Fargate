############################################
# Pipeline S3 Bucket
############################################
resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "cp_bucket" {
  bucket = lower("${var.project_name}-cp-${random_id.bucket_id.hex}")
}

resource "aws_s3_bucket_acl" "cp_bucket_acl" {
  bucket = aws_s3_bucket.cp_bucket.id
  acl    = "private"
}

############################################
# Get GitHub OAuth Token from Secrets Manager
############################################
data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = var.github_oauth_token_secret_name
}

############################################
# AWS CodePipeline
############################################
resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.cp_bucket.bucket
  }

  ############################################
  # SOURCE STAGE — GitHub Webhook
  ############################################
  stage {
    name = "Source"

    action {
      name             = "GitHubSource"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner                  = split("/", var.github_repo)[0]
        Repo                   = split("/", var.github_repo)[1]
        Branch                 = var.github_branch
        OAuthToken             = data.aws_secretsmanager_secret_version.github_token.secret_string
        PollForSourceChanges   = false
      }
    }
  }

  ############################################
  # BUILD STAGE — CodeBuild
  ############################################
  stage {
    name = "Build"

    action {
      name             = "RunBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build_all.name
      }
    }
  }

  ############################################
  # DEPLOY STAGE — ECS Fargate
  ############################################
  stage {
    name = "Deploy"

    action {
      name            = "ECSDeploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.main.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

############################################
# GitHub Webhook — Triggers Pipeline on Push
############################################
resource "aws_codepipeline_webhook" "github_webhook" {
  name            = "${var.project_name}-github-webhook"
  target_pipeline = aws_codepipeline.pipeline.name   # FIXED
  target_action   = "GitHubSource"

  authentication = "GITHUB_HMAC"

  ### Added role binding (required by AWS)
  role_arn = aws_iam_role.codepipeline_role.arn

  authentication_configuration {
    secret_token = var.github_webhook_secret
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/${var.github_branch}"
  }
}

############################################
# Register Webhook with GitHub
############################################
resource "aws_codepipeline_webhook_registration" "github_registration" {
  webhook = aws_codepipeline_webhook.github_webhook.id

  depends_on = [
    aws_codepipeline.pipeline,
    aws_codepipeline_webhook.github_webhook
  ]
}
