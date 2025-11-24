resource "random_id" "bucket_id" {
  byte_length = 4
}

# --- S3 Bucket for CodePipeline Artifacts ---
resource "aws_s3_bucket" "cp_bucket" {
  bucket = lower("${var.project_name}-codepipeline-${random_id.bucket_id.hex}")
}

# AWS now requires a separate bucket ACL resource
resource "aws_s3_bucket_acl" "cp_bucket_acl" {
  bucket = aws_s3_bucket.cp_bucket.id
  acl    = "private"
}

# --- CodePipeline ---
resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.cp_bucket.id
    type     = "S3"
  }

  # --- Source Stage ---
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = split("/", var.github_repo)[0]
        Repo       = split("/", var.github_repo)[1]
        Branch     = "main"
        OAuthToken = var.github_oauth_token
      }
    }
  }

  # --- Build Stage ---
  stage {
    name = "Build"

    action {
      name             = "Build"
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

  # --- Deploy Stage ---
  stage {
    name = "Deploy"

    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        FileName    = "imagedefinitions.json"
        ServiceName = ""
      }
    }
  }
}
