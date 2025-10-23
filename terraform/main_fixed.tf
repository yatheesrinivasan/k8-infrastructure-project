terraform {
  required_version = ">= 1.0"

  # TODO: Eventually move to remote state backend for team collaboration
  # backend "s3" {
  #   bucket = "yathee-terraform-state"
  #   key    = "k8s-infrastructure/terraform.tfstate"
  #   region = "us-west-2"
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"  # Updated to current stable version
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"  # Updated to current stable version
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"  # Updated to current stable version
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Default tags for all resources - helps with cost tracking and management
  default_tags {
    tags = {
      Project     = "k8s-infrastructure"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "yathee.srinivasan"  # Added for resource ownership tracking
    }
  }
}

# Data sources to get cluster info for k8s and helm providers
# Note: These depend on the EKS cluster existing first
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# Kubernetes provider configuration
# Had some issues with token refresh initially - this config seems stable
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Helm provider for installing monitoring stack
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# VPC Module - Creates the networking foundation
module "vpc" {
  source = "./modules/vpc"

  cluster_name = var.cluster_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr

  availability_zones = var.availability_zones
}

# EKS Cluster Module - The main Kubernetes cluster
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  environment        = var.environment
  kubernetes_version = var.kubernetes_version

  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids

  node_groups = var.node_groups

  depends_on = [module.vpc]
}

# Security Module - RBAC, network policies, scanning
module "security" {
  source = "./modules/security"

  cluster_name = var.cluster_name
  environment  = var.environment

  cluster_endpoint = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_cert  = data.aws_eks_cluster.cluster.certificate_authority.0.data

  depends_on = [module.eks]
}

# Monitoring Module - Prometheus, Grafana, custom dashboards
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name = var.cluster_name
  environment  = var.environment

  depends_on = [module.eks, module.security]
}