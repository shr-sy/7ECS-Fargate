resource "random_id" "bucket_id" {
  byte_length = 4
}

# --- S3 Bucket for CodePipeline Artifacts ---
resource "aws_s3_bucket" "cp_bucket" {
  bucket = lower("${var.project_name}-codepipeline-${random_id.bucket_id.hex}")
}

# ACL must be separate (AWS requirement)
resource "aws_s3_bucket_acl" "cp_bucket_acl" {
  bucket = aws_s3_bucket.cp_bucket.id
  acl    = "private"
}

# --- GitHub CodeStar Connection ---
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-github"
  provider_type = "GitHub"
}

# --- CodePipeline ---
resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.cp_bucket.id
    type     = "S3"
  }

  # ==============================
  # SOURCE STAGE (GitHub V2)
  # ==============================
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repo     # example: shruti/myrepo
        BranchName       = "main"
      }
    }
  }

  # ==============================
  # BUILD STAGE
  # ==============================
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

  # ==============================
  # DEPLOY STAGE (ECS)
  # ==============================
  stage {
    name = "Deploy"

    action {
      name             = "DeployToECS"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      version          = "1"
      input_artifacts  = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.main.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
