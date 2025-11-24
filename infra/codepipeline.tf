########################################
# Random ID for S3 Bucket
########################################
resource "random_id" "bucket_id" {
  byte_length = 4
}

########################################
# S3 Bucket for CodePipeline Artifacts
########################################
resource "aws_s3_bucket" "cp_bucket" {
  bucket = lower("${var.project_name}-cp-${random_id.bucket_id.hex}")
}

resource "aws_s3_bucket_acl" "cp_bucket_acl" {
  bucket = aws_s3_bucket.cp_bucket.id
  acl    = "private"
}

########################################
# CodeStar Connection for GitHub (v2 Source Action)
########################################
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-github-connection"
  provider_type = "GitHub"
}

########################################
# CodePipeline
########################################
resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.cp_bucket.id
  }

  ########################################
  # SOURCE Stage (GitHub v2)
  ########################################
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
        ConnectionArn = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repo       # "shr-sy/7ECS-Fargate"
        BranchName       = "main"
      }
    }
  }

  ########################################
  # BUILD Stage (CodeBuild)
  ########################################
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
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  ########################################
  # DEPLOY Stage — ECS Deploy via imagedefinitions.json
  ########################################
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
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

########################################
# Permissions Required for CodePipeline
########################################
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "cp_policy_attach" {
  name       = "${var.project_name}-cp-policy-attach"
  roles      = [aws_iam_role.codepipeline_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipelineFullAccess"
}
