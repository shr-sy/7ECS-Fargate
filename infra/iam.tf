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
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",

      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",

      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",

      "ecs:RegisterTaskDefinition",
      "ecs:DescribeServices",
      "ecs:UpdateService",

      "iam:PassRole",
      "secretsmanager:GetSecretValue",
      "ssm:GetParameters"
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
# CodePipeline Inline Policy
#########################################

data "aws_iam_policy_document" "codepipeline_policy_doc" {
  statement {
    actions = [
      "codepipeline:GetPipeline",
      "codepipeline:GetPipelineState",
      "codepipeline:GetPipelineExecution",
      "codepipeline:StartPipelineExecution"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "codepipeline:PutWebhook",
      "codepipeline:DeleteWebhook",
      "codepipeline:RegisterWebhookWithThirdParty",
      "codepipeline:DeregisterWebhookWithThirdParty"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "codebuild:BatchGetProjects",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = ["*"]
  }

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

resource "aws_iam_policy" "s3_force_delete_policy" {
  name        = "s3-force-delete-policy"
  description = "Allows Terraform to delete versioned S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketLocation",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:DeleteBucket"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.cp_bucket.bucket}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:ListBucketVersions",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.cp_bucket.bucket}/*"
      }
    ]
  })
}

# Attach the policy to your Terraform IAM role
resource "aws_iam_role_policy_attachment" "attach_s3_force_delete" {
  role       = var.terraform_role_name   # <-- You must define this variable
  policy_arn = aws_iam_policy.s3_force_delete_policy.arn
}
