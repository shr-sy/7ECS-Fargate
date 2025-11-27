############################################
# RANDOM ID FOR ARTIFACT BUCKET
############################################
resource "random_id" "bucket_id" {
  byte_length = 4
}

############################################
# PIPELINE S3 BUCKET
############################################
resource "aws_s3_bucket" "cp_bucket" {
  bucket = lower("${var.project_name}-cp-${random_id.bucket_id.hex}")
  force_destroy = true
  tags = {
    Name        = "${var.project_name}-cp-bucket"
    Environment = var.environment
  }
}

############################################
# FETCH GITHUB OAUTH TOKEN FROM SECRETS MANAGER
############################################
data "aws_secretsmanager_secret_version" "github_token" {
  secret_id  = aws_secretsmanager_secret.github_oauth_secret.id
  depends_on = [aws_secretsmanager_secret_version.github_oauth_secret_version]
}

############################################
# CODEPIPELINE RESOURCE
############################################
resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.cp_bucket.bucket
  }

  #########################
  # SOURCE (GitHub)
  #########################
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
        Owner                = var.github_owner
        Repo                 = var.github_repo_name
        Branch               = var.github_branch
        OAuthToken           = data.aws_secretsmanager_secret_version.github_token.secret_string
        PollForSourceChanges = false
      }
    }
  }

  #########################
  # BUILD (CodeBuild)
  #########################
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

  #########################
  # DEPLOY (ECS)
  #########################
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
        ServiceName = aws_ecs_service.svc[var.main_service].name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

############################################
# CODEPIPELINE WEBHOOK
############################################
resource "aws_codepipeline_webhook" "github_webhook" {
  name            = "${var.project_name}-github-webhook"
  target_pipeline = aws_codepipeline.pipeline.name
  target_action   = "GitHubSource"
  authentication  = "GITHUB_HMAC"

  authentication_configuration {
    secret_token = var.github_webhook_secret
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/${var.github_branch}"
  }
}

############################################
# EXPORT WEBHOOK URL
############################################
output "github_webhook_url" {
  value = aws_codepipeline_webhook.github_webhook.url
}
