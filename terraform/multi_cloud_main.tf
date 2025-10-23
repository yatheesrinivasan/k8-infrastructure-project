# Multi-Cloud Kubernetes Infrastructure
# Supports AWS EKS, GCP GKE, and Azure AKS
# Enhanced with comprehensive monitoring and observability

terraform {
  required_version = ">= 1.0"

  # TODO: Configure remote state backend for team collaboration
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "multi-cloud-k8s/terraform.tfstate"
  #   region = "us-west-2"
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
  }
}

# Provider configurations for each cloud
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "multi-cloud-k8s"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "yathee.srinivasan"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Local values for conditional deployment
locals {
  deploy_aws   = contains(var.cloud_providers, "aws")
  deploy_gcp   = contains(var.cloud_providers, "gcp")  
  deploy_azure = contains(var.cloud_providers, "azure")
}

# AWS EKS Module (conditional)
module "aws_cluster" {
  count  = local.deploy_aws ? 1 : 0
  source = "./modules/eks"

  cluster_name       = "${var.cluster_name}-aws"
  environment        = var.environment
  kubernetes_version = var.kubernetes_version

  vpc_cidr           = var.aws_vpc_cidr
  availability_zones = var.aws_availability_zones
  node_groups        = var.aws_node_groups
}

# GCP GKE Module (conditional)
module "gcp_cluster" {
  count  = local.deploy_gcp ? 1 : 0
  source = "./modules/gcp"

  project_id   = var.gcp_project_id
  cluster_name = "${var.cluster_name}-gcp"
  environment  = var.environment
  region       = var.gcp_region

  subnet_cidr  = var.gcp_subnet_cidr
  pod_cidr     = var.gcp_pod_cidr
  service_cidr = var.gcp_service_cidr
  node_pools   = var.gcp_node_pools
}

# Azure AKS Module (conditional)
module "azure_cluster" {
  count  = local.deploy_azure ? 1 : 0
  source = "./modules/azure"

  cluster_name       = "${var.cluster_name}-azure"
  environment        = var.environment
  location           = var.azure_location
  kubernetes_version = var.kubernetes_version

  vnet_cidr    = var.azure_vnet_cidr
  subnet_cidr  = var.azure_subnet_cidr
  service_cidr = var.azure_service_cidr
  node_pools   = var.azure_node_pools
}

# Enhanced Monitoring Module (deployed on primary cluster)
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name    = var.cluster_name
  environment     = var.environment
  cloud_provider  = var.primary_cloud_provider
  
  storage_class          = var.storage_classes[var.primary_cloud_provider]
  grafana_admin_password = var.grafana_admin_password
  
  enable_jaeger        = var.enable_jaeger
  enable_loki          = var.enable_loki
  enable_elasticsearch = var.enable_elasticsearch

  # Deploy monitoring on the primary cluster
  depends_on = [
    module.aws_cluster,
    module.gcp_cluster,
    module.azure_cluster
  ]
}

# Security Module (deployed on all clusters)
module "security_aws" {
  count  = local.deploy_aws ? 1 : 0
  source = "./modules/security"

  cluster_name = module.aws_cluster[0].cluster_name
  environment  = var.environment

  depends_on = [module.aws_cluster]
}

module "security_gcp" {
  count  = local.deploy_gcp ? 1 : 0
  source = "./modules/security"

  cluster_name = module.gcp_cluster[0].cluster_name
  environment  = var.environment

  depends_on = [module.gcp_cluster]
}

module "security_azure" {
  count  = local.deploy_azure ? 1 : 0
  source = "./modules/security"

  cluster_name = module.azure_cluster[0].cluster_name
  environment  = var.environment

  depends_on = [module.azure_cluster]
}

# Multi-cloud service mesh configuration
resource "kubernetes_namespace" "istio_system" {
  count = length(var.cloud_providers)
  
  metadata {
    name = "istio-system"
    labels = {
      "istio-injection" = "disabled"
      "name"           = "istio-system"
    }
  }

  # Apply to each cluster
  provider = kubernetes.multi_cloud
}

# Cross-cluster service discovery configuration
resource "kubernetes_config_map" "multi_cloud_config" {
  count = length(var.cloud_providers)

  metadata {
    name      = "multi-cloud-config"
    namespace = "kube-system"
  }

  data = {
    "clusters" = jsonencode({
      aws = local.deploy_aws ? {
        endpoint = module.aws_cluster[0].cluster_endpoint
        region   = var.aws_region
      } : null
      
      gcp = local.deploy_gcp ? {
        endpoint = module.gcp_cluster[0].cluster_endpoint
        region   = var.gcp_region
        project  = var.gcp_project_id
      } : null
      
      azure = local.deploy_azure ? {
        endpoint       = module.azure_cluster[0].cluster_endpoint
        location       = var.azure_location
        resource_group = module.azure_cluster[0].resource_group_name
      } : null
    })
    
    "monitoring" = jsonencode({
      primary_cluster = var.primary_cloud_provider
      grafana_url     = "http://grafana.monitoring.svc.cluster.local:3000"
      prometheus_url  = "http://prometheus.monitoring.svc.cluster.local:9090"
      jaeger_url      = "http://jaeger-query.observability.svc.cluster.local:16686"
    })
  }

  provider = kubernetes.multi_cloud
}