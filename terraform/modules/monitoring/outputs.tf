data "kubernetes_service" "grafana" {
  metadata {
    name      = "prometheus-grafana"
    namespace = "monitoring"
  }
  
  depends_on = [helm_release.prometheus]
}

output "prometheus_url" {
  description = "Prometheus service URL"
  value       = "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"
}

output "grafana_url" {
  description = "Grafana service URL"
  value       = "http://${data.kubernetes_service.grafana.status.0.load_balancer.0.ingress.0.hostname}"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "alertmanager_url" {
  description = "AlertManager service URL"
  value       = "http://prometheus-kube-prometheus-alertmanager.monitoring.svc.cluster.local:9093"
}