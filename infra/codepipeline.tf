############################################
# RANDOM ID FOR ARTIFACT BUCKET
############################################
resource "random_id" "bucket_id" {
  byte_length = 4
}

############################################
# S3 BUCKET FOR CODEPIPELINE ARTIFACTS
############################################
resource "aws_s3_bucket" "cp_bucket" {
  bucket        = lower("${var.project_name}-cp-${random_id.bucket_id.hex}")
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-cp-bucket"
    Environment = var.environment
  }
}

# Recommended — bucket ACL disabled (modern AWS best practice)
resource "aws_s3_bucket_public_access_block" "cp_bucket_block" {
  bucket                  = aws_s3_bucket.cp_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Required for cross-account CodePipeline object uploads
resource "aws_s3_bucket_ownership_controls" "cp_bucket_controls" {
  bucket = aws_s3_bucket.cp_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

############################################
# FETCH GITHUB TOKEN FROM SECRETS MANAGER
############################################
data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = aws_secretsmanager_secret.github_oauth_secret.id
}

############################################
# CODEPIPELINE
############################################
resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  ############################################
  # ARTIFACT STORE (S3)
  ############################################
  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.cp_bucket.bucket
  }

  ############################################
  # SOURCE STAGE — GitHub
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
        Owner                = var.github_owner
        Repo                 = var.github_repo_name
        Branch               = var.github_branch
        OAuthToken           = data.aws_secretsmanager_secret_version.github_token.secret_string
        PollForSourceChanges = "false"
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
  # DEPLOY STAGE — One ECS Deploy per service
  ############################################
  stage {
    name = "Deploy"

    dynamic "action" {
      for_each = var.services
      content {
        name            = "Deploy-${action.value}"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "ECS"
        version         = "1"
        input_artifacts = ["build_output"]

        configuration = {
          ClusterName = aws_ecs_cluster.main.name
          ServiceName = aws_ecs_service.svc[action.value].name
          FileName    = "imagedefinitions.json"
        }
      }
    }
  }

  depends_on = [
    aws_codebuild_project.build_all,
    aws_ecs_cluster.main,
    aws_ecs_service.svc,
  ]
}

############################################
# PIPELINE WEBHOOK (GITHUB → CODEPIPELINE)
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

  depends_on = [aws_codepipeline.pipeline]
}

############################################
# EXPORT WEBHOOK URL
############################################
output "github_webhook_url" {
  value = aws_codepipeline_webhook.github_webhook.url
}
