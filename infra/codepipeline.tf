############################################
# RANDOM ID FOR ARTIFACT BUCKET
############################################
resource "random_id" "bucket_id" {
  byte_length = 4
}

############################################
# PIPELINE S3 BUCKET (for CodePipeline artifacts)
############################################
resource "aws_s3_bucket" "cp_bucket" {
  bucket        = lower("${var.project_name}-cp-${random_id.bucket_id.hex}")
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-cp-bucket"
    Environment = var.environment
  }
}

# Recommended bucket ACL (private)
resource "aws_s3_bucket_acl" "cp_bucket_acl" {
  bucket = aws_s3_bucket.cp_bucket.id
  acl    = "private"
}

# Ownership controls (prevents cross-account issues when CodePipeline uploads objects)
resource "aws_s3_bucket_ownership_controls" "cp_bucket_controls" {
  bucket = aws_s3_bucket.cp_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
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
# CODEPIPELINE RESOURCE (Source, Build, Deploy per-service)
############################################
resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.cp_bucket.bucket
  }

  # SOURCE stage (GitHub)
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

  # BUILD stage (CodeBuild)
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

  # DEPLOY stage — one action per service (multi-service)
  stage {
    name = "Deploy"

    dynamic "action" {
      for_each = var.services
      content {
        name            = "ECSDeploy-${action.value}"
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

  # Ensure pipeline creation happens after CodeBuild/Cluster/Services exist
  depends_on = [
    aws_codebuild_project.build_all,
    aws_ecs_cluster.main
  ]
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

  depends_on = [aws_codepipeline.pipeline]
}

############################################
# EXPORT WEBHOOK URL
############################################
output "github_webhook_url" {
  value = aws_codepipeline_webhook.github_webhook.url
}
