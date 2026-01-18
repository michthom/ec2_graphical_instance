output "password_secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}

output "password_secret_id" {
  value = aws_secretsmanager_secret.this.id
}
