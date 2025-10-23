variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the AKS subnet"
  type        = string
  default     = "10.10.1.0/24"
}

variable "service_cidr" {
  description = "CIDR block for services"
  type        = string
  default     = "10.11.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for the DNS service"
  type        = string
  default     = "10.11.0.10"
}

variable "admin_cidr" {
  description = "CIDR block for admin access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.29"
}

variable "system_node_count" {
  description = "Number of system nodes"
  type        = number
  default     = 3
}

variable "system_node_size" {
  description = "VM size for system nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "system_min_nodes" {
  description = "Minimum number of system nodes"
  type        = number
  default     = 1
}

variable "system_max_nodes" {
  description = "Maximum number of system nodes"
  type        = number
  default     = 5
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admin access"
  type        = list(string)
  default     = []
}

variable "node_pools" {
  description = "Map of additional node pool configurations"
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
      vm_size             = "Standard_D4s_v3"
      node_count          = 2
      enable_auto_scaling = true
      min_count          = 1
      max_count          = 10
      max_pods           = 110
      os_disk_size_gb    = 100
      priority           = "Regular"
      spot_max_price     = -1
      node_taints        = []
    }
  }
}

variable "enable_acr" {
  description = "Enable Azure Container Registry"
  type        = bool
  default     = true
}