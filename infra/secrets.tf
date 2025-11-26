# ----------------------------------------------------------------------
# GitHub OAuth Token Secret (PAT)
# ----------------------------------------------------------------------
resource "aws_secretsmanager_secret" "github_oauth_secret" {
  name = var.github_oauth_token_secret_name
}

resource "aws_secretsmanager_secret_version" "github_oauth_secret_version" {
  secret_id = aws_secretsmanager_secret.github_oauth_secret.id

  secret_string = jsonencode({
    github_oauth_token = var.github_oauth_token
  })
}

# ----------------------------------------------------------------------
# GitHub Webhook HMAC Secret
# ----------------------------------------------------------------------
resource "aws_secretsmanager_secret" "github_webhook_secret" {
  name = var.github_webhook_secret_name
}

resource "aws_secretsmanager_secret_version" "github_webhook_secret_version" {
  secret_id = aws_secretsmanager_secret.github_webhook_secret.id

  secret_string = jsonencode({
    webhook_secret = var.github_webhook_secret
  })
}

# ----------------------------------------------------------------------
# Outputs (Optional)
# ----------------------------------------------------------------------
output "github_oauth_secret_arn" {
  value = aws_secretsmanager_secret.github_oauth_secret.arn
}

output "github_webhook_secret_arn" {
  value = aws_secretsmanager_secret.github_webhook_secret.arn
}
