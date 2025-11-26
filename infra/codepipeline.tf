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
  # NEW SOURCE STAGE — GitHub Webhook
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
        Owner                = var.github_owner          # NEW
        Repo                 = var.github_repo_name      # NEW
        Branch               = var.github_branch         # existing
        OAuthToken           = var.github_oauth_token    # NEW
        PollForSourceChanges = false                     # REQUIRED for webhook
      }
    }
  }

  ################################
  # BUILD STAGE
  ################################
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

  ################################
  # DEPLOY STAGE
  ################################
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
}

############################################
# WEBHOOK RESOURCE (Triggers Pipeline on Push)
############################################
resource "aws_codepipeline_webhook" "github_webhook" {
  name            = "${var.project_name}-github-webhook"
  authentication  = "GITHUB_HMAC"
  target_action   = "GitHubSource"
  target_pipeline = aws_codepipeline.pipeline.name

  authentication_configuration {
    secret_token = var.github_webhook_secret
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/${var.github_branch}"
  }
}

