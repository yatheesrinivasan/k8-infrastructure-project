# Multi-Cloud Variables
# Supports AWS, GCP, and Azure deployments

variable "cluster_name" {
  description = "Base name for the clusters (will be suffixed with cloud provider)"
  type        = string
  default     = "yathee-k8s-multicloud"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for all clusters"
  type        = string
  default     = "1.29"
}

variable "cloud_providers" {
  description = "List of cloud providers to deploy to"
  type        = list(string)
  default     = ["aws", "gcp", "azure"]
  validation {
    condition = length(setintersection(var.cloud_providers, ["aws", "gcp", "azure"])) == length(var.cloud_providers)
    error_message = "Cloud providers must be from: aws, gcp, azure."
  }
}

variable "primary_cloud_provider" {
  description = "Primary cloud provider for centralized monitoring"
  type        = string
  default     = "aws"
  validation {
    condition     = contains(["aws", "gcp", "azure"], var.primary_cloud_provider)
    error_message = "Primary cloud provider must be one of: aws, gcp, azure."
  }
}

# AWS Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_availability_zones" {
  description = "AWS availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "aws_node_groups" {
  description = "AWS EKS node group configurations"
  type = map(object({
    desired_size    = number
    max_size        = number
    min_size        = number
    instance_types  = list(string)
    capacity_type   = string
    disk_size      = number
    ami_type       = string
  }))
  default = {
    main = {
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 30
      ami_type       = "AL2_x86_64"
    }
  }
}

# GCP Variables
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_subnet_cidr" {
  description = "CIDR block for GCP subnet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "gcp_pod_cidr" {
  description = "CIDR block for GCP pods"
  type        = string
  default     = "10.2.0.0/16"
}

variable "gcp_service_cidr" {
  description = "CIDR block for GCP services"
  type        = string
  default     = "10.3.0.0/16"
}

variable "gcp_node_pools" {
  description = "GCP GKE node pool configurations"
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
      node_count   = 2
      min_nodes    = 1
      max_nodes    = 4
      machine_type = "e2-standard-2"
      disk_size_gb = 50
      disk_type    = "pd-standard"
      preemptible  = false
    }
  }
}

# Azure Variables
variable "azure_location" {
  description = "Azure location"
  type        = string
  default     = "East US"
}

variable "azure_vnet_cidr" {
  description = "CIDR block for Azure VNet"
  type        = string
  default     = "10.10.0.0/16"
}

variable "azure_subnet_cidr" {
  description = "CIDR block for Azure subnet"
  type        = string
  default     = "10.10.1.0/24"
}

variable "azure_service_cidr" {
  description = "CIDR block for Azure services"
  type        = string
  default     = "10.11.0.0/16"
}

variable "azure_node_pools" {
  description = "Azure AKS node pool configurations"
  type = map(object({
    vm_size             = string
    node_count          = number
    enable_auto_scaling = bool
    min_count          = number
    max_count          = number
    max_pods           = number
    os_disk_size_gb    = number
    priority           = string
    spot_max_price     = number
    node_taints        = list(string)
  }))
  default = {
    workers = {
      vm_size             = "Standard_D2s_v3"
      node_count          = 2
      enable_auto_scaling = true
      min_count          = 1
      max_count          = 4
      max_pods           = 110
      os_disk_size_gb    = 50
      priority           = "Regular"
      spot_max_price     = -1
      node_taints        = []
    }
  }
}

# Monitoring Variables
variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "admin123"
  sensitive   = true
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

variable "storage_classes" {
  description = "Storage classes for each cloud provider"
  type        = map(string)
  default = {
    aws   = "gp3"
    gcp   = "standard-rwo"
    azure = "managed-csi"
  }
}

# Environment-specific overrides
variable "environment_configs" {
  description = "Environment-specific configurations"
  type = map(object({
    node_count = number
    node_size  = string
    monitoring = bool
  }))
  default = {
    dev = {
      node_count = 1
      node_size  = "small"
      monitoring = false
    }
    staging = {
      node_count = 2
      node_size  = "medium" 
      monitoring = true
    }
    prod = {
      node_count = 3
      node_size  = "large"
      monitoring = true
    }
  }
}