############################################
# Store GitHub OAuth Token in Secrets Manager
############################################

resource "aws_secretsmanager_secret" "github_oauth_secret" {
  name = var.github_oauth_token_secret_name
}

resource "aws_secretsmanager_secret_version" "github_oauth_secret_version" {
  secret_id     = aws_secretsmanager_secret.github_oauth_secret.id
  secret_string = var.github_oauth_token
}
