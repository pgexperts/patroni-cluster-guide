output "postgres_password" {
  description = "postgres user password"
  value       = random_password.postgres.result
  sensitive   = true
}
