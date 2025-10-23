#!/bin/bash

# Multi-Cloud Kubernetes Deployment Script
# Supports AWS EKS, GCP GKE, and Azure AKS with enhanced monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="terraform"
K8S_DIR="kubernetes"
SECURITY_DIR="security"
MONITORING_DIR="monitoring"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

log_cloud() {
    echo -e "${PURPLE}[CLOUD]${NC} $1"
}

# Check prerequisites for multi-cloud
check_prerequisites() {
    local missing_tools=()
    
    # Check for required tools
    for tool in terraform kubectl helm; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    # Check cloud CLI tools
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    if ! command -v gcloud &> /dev/null; then
        missing_tools+=("gcloud")
    fi
    
    if ! command -v az &> /dev/null; then
        missing_tools+=("azure-cli")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Install missing tools:"
        for tool in "${missing_tools[@]}"; do
            case $tool in
                "aws-cli")
                    log_info "  AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
                    ;;
                "gcloud")
                    log_info "  Google Cloud CLI: https://cloud.google.com/sdk/docs/install"
                    ;;
                "azure-cli")
                    log_info "  Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
                    ;;
                *)
                    log_info "  $tool: Install via package manager or official website"
                    ;;
            esac
        done
        exit 1
    fi
    
    log_info "All prerequisites are satisfied."
}

# Check cloud authentication
check_cloud_auth() {
    log_info "Checking cloud authentication..."
    
    # Check AWS
    if aws sts get-caller-identity &> /dev/null; then
        log_cloud "✓ AWS authentication verified"
    else
        log_warn "AWS authentication not configured"
        log_info "Run: aws configure"
    fi
    
    # Check GCP
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        log_cloud "✓ GCP authentication verified"
    else
        log_warn "GCP authentication not configured"
        log_info "Run: gcloud auth login"
    fi
    
    # Check Azure
    if az account show &> /dev/null; then
        log_cloud "✓ Azure authentication verified"
    else
        log_warn "Azure authentication not configured"
        log_info "Run: az login"
    fi
}

# Initialize Terraform for multi-cloud
initialize_terraform() {
    local env=${1:-"dev"}
    local config_file=${2:-"multi_cloud_main.tf"}
    
    log_info "Initializing Terraform for multi-cloud deployment: $env"
    
    cd "$TERRAFORM_DIR"
    
    # Use multi-cloud configuration
    if [ ! -f "$config_file" ]; then
        log_error "Multi-cloud configuration file not found: $config_file"
        exit 1
    fi
    
    # Initialize with multi-cloud providers
    terraform init
    
    # Create environment-specific tfvars if it doesn't exist
    local env_dir="environments/$env"
    local tfvars_file="$env_dir/multi_cloud.tfvars"
    
    if [ ! -f "$tfvars_file" ]; then
        log_info "Creating environment configuration: $tfvars_file"
        mkdir -p "$env_dir"
        
        case $env in
            "dev")
                cat > "$tfvars_file" << EOF
# Multi-Cloud Development Environment
cluster_name = "yathee-k8s-dev"
environment  = "dev"

# Cloud providers to deploy (comment out to disable)
cloud_providers = ["aws"]  # Start with AWS only for dev
primary_cloud_provider = "aws"

# AWS Configuration
aws_region = "us-west-2"
aws_node_groups = {
  main = {
    desired_size   = 1
    max_size       = 2
    min_size       = 1
    instance_types = ["t3.small"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
    ami_type       = "AL2_x86_64"
  }
}

# Monitoring Configuration (lightweight for dev)
enable_jaeger = false
enable_loki = true
enable_elasticsearch = false
EOF
                ;;
            "staging")
                cat > "$tfvars_file" << EOF
# Multi-Cloud Staging Environment
cluster_name = "yathee-k8s-staging"
environment  = "staging"

# Deploy to multiple clouds for testing
cloud_providers = ["aws", "gcp"]
primary_cloud_provider = "aws"

# AWS Configuration
aws_region = "us-west-2"
aws_node_groups = {
  main = {
    desired_size   = 2
    max_size       = 3
    min_size       = 1
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 30
    ami_type       = "AL2_x86_64"
  }
}

# GCP Configuration (requires project_id)
gcp_project_id = "your-gcp-project-id"
gcp_region = "us-central1"

# Full monitoring stack
enable_jaeger = true
enable_loki = true
enable_elasticsearch = true
EOF
                ;;
            "prod")
                cat > "$tfvars_file" << EOF
# Multi-Cloud Production Environment
cluster_name = "yathee-k8s-prod"
environment  = "prod"

# Full multi-cloud deployment
cloud_providers = ["aws", "gcp", "azure"]
primary_cloud_provider = "aws"

# AWS Configuration
aws_region = "us-west-2"
aws_node_groups = {
  main = {
    desired_size   = 3
    max_size       = 6
    min_size       = 2
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
    ami_type       = "AL2_x86_64"
  }
  spot = {
    desired_size   = 2
    max_size       = 4
    min_size       = 0
    instance_types = ["t3.medium", "t3.large"]
    capacity_type  = "SPOT"
    disk_size      = 30
    ami_type       = "AL2_x86_64"
  }
}

# GCP Configuration
gcp_project_id = "your-gcp-project-id"
gcp_region = "us-central1"

# Azure Configuration
azure_location = "East US"

# Full observability stack
enable_jaeger = true
enable_loki = true
enable_elasticsearch = true
EOF
                ;;
        esac
        
        log_warn "Created default configuration. Please review and update: $tfvars_file"
        log_warn "Especially update GCP project_id if deploying to GCP"
    fi
    
    cd ..
}

# Plan multi-cloud deployment
plan_terraform() {
    local env=${1:-"dev"}
    
    log_info "Planning multi-cloud deployment for environment: $env"
    
    cd "$TERRAFORM_DIR"
    
    local tfvars_file="environments/$env/multi_cloud.tfvars"
    local plan_file="$env-multicloud.tfplan"
    
    if [ ! -f "$tfvars_file" ]; then
        log_error "Environment configuration not found: $tfvars_file"
        exit 1
    fi
    
    terraform plan \
        -var-file="$tfvars_file" \
        -out="$plan_file" \
        -input=false
    
    cd ..
}

# Apply multi-cloud deployment
apply_terraform() {
    local env=${1:-"dev"}
    
    log_info "Applying multi-cloud deployment for environment: $env"
    
    cd "$TERRAFORM_DIR"
    
    local plan_file="$env-multicloud.tfplan"
    
    if [ ! -f "$plan_file" ]; then
        log_error "Plan file not found: $plan_file. Run plan first."
        exit 1
    fi
    
    terraform apply "$plan_file"
    
    # Update kubeconfigs for all deployed clusters
    update_kubeconfigs "$env"
    
    cd ..
}

# Update kubeconfigs for all clusters
update_kubeconfigs() {
    local env=${1:-"dev"}
    
    log_info "Updating kubeconfigs for deployed clusters..."
    
    cd "$TERRAFORM_DIR"
    
    # Get deployed cloud providers from Terraform state
    local deployed_clouds=$(terraform output -json 2>/dev/null | jq -r 'keys[]' | grep "_cluster" | sed 's/_cluster//')
    
    for cloud in $deployed_clouds; do
        case $cloud in
            "aws")
                if terraform output aws_cluster_name &> /dev/null; then
                    local cluster_name=$(terraform output -raw aws_cluster_name)
                    local region=$(terraform output -raw aws_region)
                    log_cloud "Updating AWS kubeconfig: $cluster_name"
                    aws eks update-kubeconfig --region "$region" --name "$cluster_name" --alias "aws-$env"
                fi
                ;;
            "gcp")
                if terraform output gcp_cluster_name &> /dev/null; then
                    local cluster_name=$(terraform output -raw gcp_cluster_name)
                    local region=$(terraform output -raw gcp_region)
                    local project=$(terraform output -raw gcp_project_id)
                    log_cloud "Updating GCP kubeconfig: $cluster_name"
                    gcloud container clusters get-credentials "$cluster_name" \
                        --region "$region" --project "$project"
                    kubectl config rename-context "$cluster_name" "gcp-$env"
                fi
                ;;
            "azure")
                if terraform output azure_cluster_name &> /dev/null; then
                    local cluster_name=$(terraform output -raw azure_cluster_name)
                    local resource_group=$(terraform output -raw azure_resource_group)
                    log_cloud "Updating Azure kubeconfig: $cluster_name"
                    az aks get-credentials --resource-group "$resource_group" \
                        --name "$cluster_name" --context "azure-$env"
                fi
                ;;
        esac
    done
    
    cd ..
    
    log_info "Available contexts:"
    kubectl config get-contexts
}

# Deploy enhanced monitoring and observability
deploy_monitoring() {
    local env=${1:-"dev"}
    local cloud=${2:-"aws"}
    
    log_info "Deploying enhanced monitoring stack to $cloud cluster..."
    
    # Switch to primary cluster context
    kubectl config use-context "$cloud-$env"
    
    # Create monitoring namespaces
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespaces for monitoring
    kubectl label namespace monitoring name=monitoring --overwrite
    kubectl label namespace observability name=observability --overwrite
    
    # Deploy custom monitoring dashboards
    if [ -d "$MONITORING_DIR/dashboards" ]; then
        log_info "Deploying custom Grafana dashboards..."
        kubectl create configmap grafana-dashboards \
            --from-file="$MONITORING_DIR/dashboards/" \
            -n monitoring --dry-run=client -o yaml | kubectl apply -f -
    fi
    
    # Deploy service monitors for multi-cloud metrics
    if [ -f "$MONITORING_DIR/multi-cloud-servicemonitor.yaml" ]; then
        log_info "Deploying multi-cloud service monitors..."
        kubectl apply -f "$MONITORING_DIR/multi-cloud-servicemonitor.yaml"
    fi
    
    log_info "Enhanced monitoring deployment completed"
}

# Deploy Kubernetes manifests to all clusters
deploy_k8s() {
    local env=${1:-"dev"}
    
    log_info "Deploying Kubernetes manifests to all clusters..."
    
    # Get all cluster contexts
    local contexts=$(kubectl config get-contexts -o name | grep "$env")
    
    for context in $contexts; do
        log_cloud "Deploying to context: $context"
        kubectl config use-context "$context"
        
        # Apply network policies
        if [ -f "$K8S_DIR/network-policies.yaml" ]; then
            log_info "Applying network policies..."
            kubectl apply -f "$K8S_DIR/network-policies.yaml"
        fi
        
        # Apply DaemonSet
        if [ -f "$K8S_DIR/logging-daemonset.yaml" ]; then
            log_info "Applying logging DaemonSet..."
            kubectl apply -f "$K8S_DIR/logging-daemonset.yaml"
        fi
        
        # Apply security policies
        if [ -f "$SECURITY_DIR/gatekeeper-policies.yaml" ]; then
            log_info "Applying Gatekeeper policies..."
            kubectl apply -f "$SECURITY_DIR/gatekeeper-policies.yaml"
        fi
        
        # Wait for DaemonSet rollout
        kubectl rollout status daemonset/logging-daemon -n kube-system --timeout=300s || log_warn "DaemonSet rollout timed out on $context"
    done
    
    log_info "Kubernetes manifests deployed to all clusters"
}

# Get multi-cluster information
get_cluster_info() {
    local env=${1:-"dev"}
    
    log_info "Getting multi-cluster information for environment: $env"
    
    cd "$TERRAFORM_DIR"
    
    if ! terraform show > /dev/null 2>&1; then
        log_error "Terraform state not found. Deploy infrastructure first."
        cd ..
        return 1
    fi
    
    echo ""
    echo "=== Multi-Cloud Cluster Information ==="
    
    # AWS cluster info
    if terraform output aws_cluster_name &> /dev/null; then
        echo ""
        echo "🔶 AWS EKS Cluster:"
        echo "  Name: $(terraform output -raw aws_cluster_name 2>/dev/null || echo 'N/A')"
        echo "  Endpoint: $(terraform output -raw aws_cluster_endpoint 2>/dev/null || echo 'N/A')"
        echo "  Region: $(terraform output -raw aws_region 2>/dev/null || echo 'N/A')"
    fi
    
    # GCP cluster info
    if terraform output gcp_cluster_name &> /dev/null; then
        echo ""
        echo "🔵 GCP GKE Cluster:"
        echo "  Name: $(terraform output -raw gcp_cluster_name 2>/dev/null || echo 'N/A')"
        echo "  Endpoint: $(terraform output -raw gcp_cluster_endpoint 2>/dev/null || echo 'N/A')"
        echo "  Region: $(terraform output -raw gcp_region 2>/dev/null || echo 'N/A')"
    fi
    
    # Azure cluster info
    if terraform output azure_cluster_name &> /dev/null; then
        echo ""
        echo "🔷 Azure AKS Cluster:"
        echo "  Name: $(terraform output -raw azure_cluster_name 2>/dev/null || echo 'N/A')"
        echo "  Endpoint: $(terraform output -raw azure_cluster_endpoint 2>/dev/null || echo 'N/A')"
        echo "  Location: $(terraform output -raw azure_location 2>/dev/null || echo 'N/A')"
    fi
    
    cd ..
    
    echo ""
    echo "=== Kubernetes Contexts ==="
    kubectl config get-contexts
    
    echo ""
    echo "=== Monitoring URLs ==="
    echo "Access monitoring via port-forward:"
    echo "  Grafana: ./scripts/deploy-multicloud.sh port-forward grafana"
    echo "  Prometheus: ./scripts/deploy-multicloud.sh port-forward prometheus"
    echo "  Jaeger: ./scripts/deploy-multicloud.sh port-forward jaeger"
}

# Port forward services
port_forward() {
    local service=${1:-"grafana"}
    local env=${2:-"dev"}
    local cloud=${3:-"aws"}
    
    # Switch to primary monitoring cluster
    kubectl config use-context "$cloud-$env"
    
    case $service in
        "grafana")
            log_info "Port forwarding Grafana (http://localhost:3000)"
            log_info "Default credentials: admin / admin123"
            kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
            ;;
        "prometheus")
            log_info "Port forwarding Prometheus (http://localhost:9090)"
            kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
            ;;
        "jaeger")
            log_info "Port forwarding Jaeger (http://localhost:16686)"
            kubectl port-forward -n observability svc/jaeger-query 16686:16686
            ;;
        "loki")
            log_info "Port forwarding Loki (http://localhost:3100)"
            kubectl port-forward -n observability svc/loki-gateway 3100:80
            ;;
        *)
            log_error "Unknown service: $service"
            log_info "Available services: grafana, prometheus, jaeger, loki"
            exit 1
            ;;
    esac
}

# Destroy multi-cloud infrastructure
destroy_terraform() {
    local env=${1:-"dev"}
    
    log_warn "This will destroy ALL multi-cloud infrastructure for environment: $env"
    read -p "Are you absolutely sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_info "Operation cancelled."
        return 0
    fi
    
    log_info "Destroying multi-cloud infrastructure for environment: $env"
    
    cd "$TERRAFORM_DIR"
    
    local tfvars_file="environments/$env/multi_cloud.tfvars"
    
    if [ ! -f "$tfvars_file" ]; then
        log_error "Environment configuration not found: $tfvars_file"
        exit 1
    fi
    
    terraform destroy -var-file="$tfvars_file" -auto-approve
    
    cd ..
    
    log_info "Multi-cloud infrastructure destroyed."
}

# Main script logic
main() {
    local command=${1:-"help"}
    local env=${2:-"dev"}
    local param3=${3:-""}
    
    case $command in
        "check")
            check_prerequisites
            check_cloud_auth
            ;;
        "init")
            initialize_terraform "$env"
            ;;
        "plan")
            plan_terraform "$env"
            ;;
        "apply")
            apply_terraform "$env"
            ;;
        "deploy")
            check_prerequisites
            initialize_terraform "$env"
            plan_terraform "$env"
            apply_terraform "$env"
            deploy_k8s "$env"
            deploy_monitoring "$env" "$param3"
            ;;
        "deploy-k8s")
            deploy_k8s "$env"
            ;;
        "deploy-monitoring")
            deploy_monitoring "$env" "$param3"
            ;;
        "info")
            get_cluster_info "$env"
            ;;
        "port-forward")
            port_forward "$param3" "$env"
            ;;
        "destroy")
            destroy_terraform "$env"
            ;;
        "help"|*)
            echo "Multi-Cloud Kubernetes Deployment Script"
            echo ""
            echo "Usage: $0 <command> [environment] [options]"
            echo ""
            echo "Commands:"
            echo "  check                    - Check prerequisites and cloud authentication"
            echo "  init <env>              - Initialize Terraform for environment"
            echo "  plan <env>              - Plan multi-cloud deployment"
            echo "  apply <env>             - Apply multi-cloud deployment"
            echo "  deploy <env> [cloud]    - Full deployment (init + plan + apply + k8s + monitoring)"
            echo "  deploy-k8s <env>        - Deploy Kubernetes manifests only"
            echo "  deploy-monitoring <env> [cloud] - Deploy monitoring stack only"
            echo "  info <env>              - Get multi-cluster information"
            echo "  port-forward <service> <env> - Port forward services (grafana, prometheus, jaeger, loki)"
            echo "  destroy <env>           - Destroy all infrastructure"
            echo "  help                    - Show this help"
            echo ""
            echo "Environments: dev, staging, prod"
            echo "Cloud providers: aws, gcp, azure"
            echo ""
            echo "Examples:"
            echo "  $0 check"
            echo "  $0 deploy dev"
            echo "  $0 deploy prod aws"
            echo "  $0 port-forward grafana dev"
            echo "  $0 info staging"
            ;;
    esac
}

# Run main function with all arguments
main "$@"