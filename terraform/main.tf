terraform {terraform {

  required_version = ">= 1.0"  required_version = ">= 1.0"

    

  # TODO: Eventually move to remote state backend for team collaboration  # TODO: Eventually move to remote state backend for team collaboration

  # backend "s3" {  # backend "s3" {

  #   bucket = "yathee-terraform-state"  #   bucket = "my-terraform-state-bucket"

  #   key    = "k8s-infrastructure/terraform.tfstate"  #   key    = "k8s-infrastructure/terraform.tfstate"

  #   region = "us-west-2"  #   region = "us-west-2"

  # }  # }

    

  required_providers {  required_providers {

    aws = {    aws = {

      source  = "hashicorp/aws"      source  = "hashicorp/aws"

      version = "~> 5.0"  # Locked to major version to avoid breaking changes      version = "~> 5.0"  # Locked to major version to avoid breaking changes

    }    }

    kubernetes = {    kubernetes = {

      source  = "hashicorp/kubernetes"      source  = "hashicorp/kubernetes"

      version = "~> 2.23"      version = "~> 2.23"

    }    }

    helm = {    helm = {

      source  = "hashicorp/helm"      source  = "hashicorp/helm"

      version = "~> 2.10"      version = "~> 2.10"

    }    }

  }  }

}}



provider "aws" {provider "aws" {

  region = var.aws_region  region = var.aws_region



  # Default tags for all resources - helps with cost tracking and management  # Default tags for all resources - helps with cost tracking and management

  default_tags {  default_tags {

    tags = {    tags = {

      Project     = "k8s-infrastructure"      Project     = "k8s-infrastructure"

      Environment = var.environment      Environment = var.environment

      ManagedBy   = "terraform"      ManagedBy   = "terraform"

      Owner       = "yathee.srinivasan"  # Added for resource ownership tracking      Owner       = "yathee.srinivasan"  # Added for resource ownership tracking

    }    }

  }  }

}}data "aws_eks_cluster" "cluster" {

  name = module.eks.cluster_name

# Data sources to get cluster info for k8s and helm providers}

# Note: These depend on the EKS cluster existing first

data "aws_eks_cluster" "cluster" {data "aws_eks_cluster_auth" "cluster" {

  name = module.eks.cluster_name  name = module.eks.cluster_name

}}



data "aws_eks_cluster_auth" "cluster" {provider "kubernetes" {

  name = module.eks.cluster_name  host                   = data.aws_eks_cluster.cluster.endpoint

}  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)

  token                  = data.aws_eks_cluster_auth.cluster.token

# Kubernetes provider configuration}

# Had some issues with token refresh initially - this config seems stable

provider "kubernetes" {provider "helm" {

  host                   = data.aws_eks_cluster.cluster.endpoint  kubernetes {

  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)    host                   = data.aws_eks_cluster.cluster.endpoint

  token                  = data.aws_eks_cluster_auth.cluster.token    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)

}    token                  = data.aws_eks_cluster_auth.cluster.token

  }

# Helm provider for installing monitoring stack}

provider "helm" {

  kubernetes {# VPC Module

    host                   = data.aws_eks_cluster.cluster.endpointmodule "vpc" {

    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)  source = "./modules/vpc"

    token                  = data.aws_eks_cluster_auth.cluster.token

  }  cluster_name = var.cluster_name

}  environment  = var.environment

  vpc_cidr     = var.vpc_cidr

# VPC Module - Creates the networking foundation  

module "vpc" {  availability_zones = var.availability_zones

  source = "./modules/vpc"}



  cluster_name = var.cluster_name# EKS Cluster Module

  environment  = var.environmentmodule "eks" {

  vpc_cidr     = var.vpc_cidr  source = "./modules/eks"



  availability_zones = var.availability_zones  cluster_name       = var.cluster_name

}  environment        = var.environment

  kubernetes_version = var.kubernetes_version

# EKS Cluster Module - The main Kubernetes cluster  

module "eks" {  vpc_id         = module.vpc.vpc_id

  source = "./modules/eks"  subnet_ids     = module.vpc.private_subnet_ids

  

  cluster_name       = var.cluster_name  node_groups = var.node_groups

  environment        = var.environment  

  kubernetes_version = var.kubernetes_version  depends_on = [module.vpc]

}

  vpc_id         = module.vpc.vpc_id

  subnet_ids     = module.vpc.private_subnet_ids# Security Module

module "security" {

  node_groups = var.node_groups  source = "./modules/security"



  depends_on = [module.vpc]  cluster_name = var.cluster_name

}  environment  = var.environment

  

# Security Module - RBAC, network policies, scanning  cluster_endpoint = data.aws_eks_cluster.cluster.endpoint

module "security" {  cluster_ca_cert  = data.aws_eks_cluster.cluster.certificate_authority.0.data

  source = "./modules/security"  

  depends_on = [module.eks]

  cluster_name = var.cluster_name}

  environment  = var.environment

# Monitoring Module

  cluster_endpoint = data.aws_eks_cluster.cluster.endpointmodule "monitoring" {

  cluster_ca_cert  = data.aws_eks_cluster.cluster.certificate_authority.0.data  source = "./modules/monitoring"



  depends_on = [module.eks]  cluster_name = var.cluster_name

}  environment  = var.environment

  

# Monitoring Module - Prometheus, Grafana, custom dashboards  depends_on = [module.eks, module.security]

module "monitoring" {}
  source = "./modules/monitoring"

  cluster_name = var.cluster_name
  environment  = var.environment

  depends_on = [module.eks, module.security]
}