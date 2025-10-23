variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "gp3"
}

variable "cloud_provider" {
  description = "Cloud provider (aws, gcp, azure)"
  type        = string
  default     = "aws"
}

variable "enable_jaeger" {
  description = "Enable Jaeger distributed tracing"
  type        = bool
  default     = true
}

variable "enable_loki" {
  description = "Enable Loki log aggregation"
  type        = bool
  default     = true
}

variable "enable_elasticsearch" {
  description = "Enable Elasticsearch for Jaeger backend"
  type        = bool
  default     = true
}