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

resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.cp_bucket.id
  }

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
        ConnectionArn     = aws_codestarconnections_connection.github.arn
        FullRepositoryId  = var.github_repo
        BranchName        = "main"
      }
    }
  }

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
