#########################################
# CodeBuild Role & Policy
#########################################

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.project_name}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",

      # logs
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",

      # s3 (store artifacts)
      "s3:*",

      # ECS deploy
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices",

      # roles
      "iam:PassRole",

      # secrets
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_policy_attach" {
  name   = "${var.project_name}-codebuild-inline-policy"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

#########################################
# ECS Task Execution Role
#########################################

data "aws_iam_policy_document" "ecs_task_exec_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_exec" {
  name               = "${var.project_name}-ecs-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy_attach" {
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#########################################
# CodePipeline Role
#########################################

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.project_name}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json

  lifecycle {
    create_before_destroy = true
  }
}

#########################################
# CodePipeline IAM Policy
#########################################

data "aws_iam_policy_document" "codepipeline_policy_doc" {

  # Allow CodePipeline to use Connection
  statement {
    actions = [
      "codestar-connections:UseConnection",
      "codestar-connections:GetConnection",
      "codestar-connections:ListConnections"
    ]
    resources = [
      aws_codestarconnections_connection.github.arn
    ]
  }

  # Allow triggering CodeBuild
  statement {
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:BatchGetProjects"
    ]
    resources = ["*"]
  }

  # Allow ECS deployment
  statement {
    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = ["*"]
  }

  # S3 access for pipeline artifacts
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = ["*"]
  }

  # Pass IAM roles to ECS
  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "codepipeline_policy" {
  name   = "${var.project_name}-codepipeline-policy"
  policy = data.aws_iam_policy_document.codepipeline_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}
