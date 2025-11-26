############################################
# Store GitHub OAuth Token in Secrets Manager
############################################

resource "aws_secretsmanager_secret" "github_token" {
  name = "${var.project_name}-github-token"
}

resource "aws_secretsmanager_secret_version" "github_token_value" {
  secret_id     = aws_secretsmanager_secret.github_token.id
  secret_string = var.github_oauth_token  # coming from HCP variable
}
