output "monitoring_namespace" {
  description = "Monitoring namespace name"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "security_namespace" {
  description = "Security namespace name"
  value       = kubernetes_namespace.security.metadata[0].name
}

output "monitoring_service_account" {
  description = "Monitoring service account name"
  value       = kubernetes_service_account.monitoring.metadata[0].name
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = random_password.grafana_admin.result
  sensitive   = true
}