###############################################
# GitHub OAuth Token Secret (USED BY CODEPIPELINE)
###############################################
resource "aws_secretsmanager_secret" "github_oauth_secret" {
  name = "hcp-ecs-github-token"
}

resource "aws_secretsmanager_secret_version" "github_oauth_secret_version" {
  secret_id     = aws_secretsmanager_secret.github_oauth_secret.id
  secret_string = var.github_oauth_token
}

###############################################
# GitHub Webhook Secret
###############################################
resource "aws_secretsmanager_secret" "github_webhook_secret" {
  name = var.github_webhook_secret_name
}

resource "aws_secretsmanager_secret_version" "github_webhook_secret_version" {
  secret_id     = aws_secretsmanager_secret.github_webhook_secret.id
  secret_string = var.github_webhook_secret
}
