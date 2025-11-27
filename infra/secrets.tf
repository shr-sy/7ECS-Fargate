############################################################
# GitHub OAuth Token Secret (USED BY CODEPIPELINE)
############################################################
resource "aws_secretsmanager_secret" "github_oauth_secret" {
  name                    = var.github_oauth_token_secret_name
  description             = "GitHub OAuth/PAT token for CodePipeline"
  recovery_window_in_days = 0

  tags = {
    Name        = "GitHub OAuth PAT Secret"
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "github_oauth_secret_version" {
  secret_id     = aws_secretsmanager_secret.github_oauth_secret.id
  secret_string = var.github_oauth_token

  lifecycle {
    # Allows updating PAT in console without causing Terraform drift
    ignore_changes = [ secret_string ]
  }
}

############################################################
# GitHub Webhook Secret (HMAC)
############################################################
resource "aws_secretsmanager_secret" "github_webhook_secret" {
  name                    = var.github_webhook_secret_name
  description             = "GitHub Webhook HMAC Secret"
  recovery_window_in_days = 0

  tags = {
    Name        = "GitHub Webhook Secret"
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "github_webhook_secret_version" {
  secret_id     = aws_secretsmanager_secret.github_webhook_secret.id
  secret_string = var.github_webhook_secret

  lifecycle {
    ignore_changes = [ secret_string ]
  }
}
