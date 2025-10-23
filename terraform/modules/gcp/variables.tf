variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "pod_cidr" {
  description = "CIDR block for pods"
  type        = string
  default     = "10.2.0.0/16"
}

variable "service_cidr" {
  description = "CIDR block for services"
  type        = string
  default     = "10.3.0.0/16"
}

variable "master_cidr" {
  description = "CIDR block for master nodes"
  type        = string
  default     = "10.4.0.0/28"
}

variable "authorized_networks" {
  description = "List of authorized networks for master access"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  ]
}

variable "node_pools" {
  description = "Map of node pool configurations"
  type = map(object({
    node_count     = number
    min_nodes      = number
    max_nodes      = number
    machine_type   = string
    disk_size_gb   = number
    disk_type      = string
    preemptible    = bool
  }))
  default = {
    primary = {
      node_count   = 3
      min_nodes    = 1
      max_nodes    = 5
      machine_type = "e2-standard-2"
      disk_size_gb = 50
      disk_type    = "pd-standard"
      preemptible  = false
    }
  }
}

variable "maintenance_start_time" {
  description = "Maintenance window start time"
  type        = string
  default     = "2023-01-01T02:00:00Z"
}

variable "maintenance_end_time" {
  description = "Maintenance window end time"
  type        = string
  default     = "2023-01-01T06:00:00Z"
}

variable "maintenance_recurrence" {
  description = "Maintenance window recurrence"
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SA"
}