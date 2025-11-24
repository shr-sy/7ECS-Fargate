#########################################
# Random ID for S3 Bucket
#########################################
resource "random_id" "bucket_id" {
  byte_length = 4
}

#########################################
# S3 Bucket for CodePipeline Artifacts
#########################################
resource "aws_s3_bucket" "cp_bucket" {
  bucket        = "${var.project_name}-cp-${random_id.bucket_id.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-cp-bucket"
  }
}

# Ownership Controls (required for ACL-disabled buckets)
resource "aws_s3_bucket_ownership_controls" "cp_bucket_ownership" {
  bucket = aws_s3_bucket.cp_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "cp_bucket_pab" {
  bucket = aws_s3_bucket.cp_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#########################################
# GitHub CodeStar Connection (Source)
#########################################
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-github-connection"
  provider_type = "GitHub"
}

#########################################
# CodePipeline
#########################################
resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.cp_bucket.id
  }

  # Source Stage
  stage {
    name = "Source"

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repo
        BranchName       = "main"
      }
    }
  }

  # Build Stage
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

  # Deploy Stage
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
