resource "aws_s3_bucket" "cp_bucket" {
  bucket = lower("${var.project_name}-codepipeline-${random_id.bucket_id.hex}")
  acl    = "private"
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.cp_bucket.id
    type     = "S3"
  }

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

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
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
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        # FileName is used by the ECS plugin to read imagedefinitions.json produced by build
        FileName    = "imagedefinitions.json"
        # ServiceName left intentionally blank here; pipeline will use imagedefinitions.json
        # to update task definitions. If you want to target a specific service, set it here.
        ServiceName = ""
      }
    }
  }
}
