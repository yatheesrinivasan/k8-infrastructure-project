# Multi-Cloud Kubernetes Deployment Script (PowerShell)
# Supports AWS EKS, GCP GKE, and Azure AKS with enhanced monitoring

param(
    [Parameter(Position=0)]
    [ValidateSet("check", "init", "plan", "apply", "deploy", "deploy-k8s", "deploy-monitoring", "info", "port-forward", "destroy", "help")]
    [string]$Command = "help",
    
    [Parameter(Position=1)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",
    
    [Parameter(Position=2)]
    [string]$Parameter3 = ""
)

# Configuration
$TerraformDir = "terraform"
$K8sDir = "kubernetes"
$SecurityDir = "security"
$MonitoringDir = "monitoring"

# Color functions
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Debug { param($Message) Write-Host "[DEBUG] $Message" -ForegroundColor Blue }
function Write-Cloud { param($Message) Write-Host "[CLOUD] $Message" -ForegroundColor Magenta }

# Check prerequisites for multi-cloud
function Test-Prerequisites {
    Write-Info "Checking prerequisites for multi-cloud deployment..."
    
    $missingTools = @()
    
    # Check for required tools
    $requiredTools = @("terraform", "kubectl", "helm")
    foreach ($tool in $requiredTools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            $missingTools += $tool
        }
    }
    
    # Check cloud CLI tools
    $cloudTools = @{
        "aws" = "AWS CLI"
        "gcloud" = "Google Cloud CLI"
        "az" = "Azure CLI"
    }
    
    foreach ($tool in $cloudTools.Keys) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            $missingTools += $cloudTools[$tool]
        }
    }
    
    if ($missingTools.Count -gt 0) {
        Write-Error "Missing required tools: $($missingTools -join ', ')"
        Write-Info "Install missing tools:"
        foreach ($tool in $missingTools) {
            switch ($tool) {
                "AWS CLI" { Write-Info "  AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" }
                "Google Cloud CLI" { Write-Info "  Google Cloud CLI: https://cloud.google.com/sdk/docs/install" }
                "Azure CLI" { Write-Info "  Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" }
                default { Write-Info "  $tool: Install via package manager or official website" }
            }
        }
        throw "Prerequisites not met"
    }
    
    Write-Info "All prerequisites are satisfied."
}

# Check cloud authentication
function Test-CloudAuth {
    Write-Info "Checking cloud authentication..."
    
    # Check AWS
    try {
        $null = aws sts get-caller-identity 2>$null
        Write-Cloud "✓ AWS authentication verified"
    }
    catch {
        Write-Warn "AWS authentication not configured"
        Write-Info "Run: aws configure"
    }
    
    # Check GCP
    try {
        $null = gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>$null
        Write-Cloud "✓ GCP authentication verified"
    }
    catch {
        Write-Warn "GCP authentication not configured"
        Write-Info "Run: gcloud auth login"
    }
    
    # Check Azure
    try {
        $null = az account show 2>$null
        Write-Cloud "✓ Azure authentication verified"
    }
    catch {
        Write-Warn "Azure authentication not configured"
        Write-Info "Run: az login"
    }
}

# Initialize Terraform for multi-cloud
function Initialize-Terraform {
    param(
        [string]$Env = "dev",
        [string]$ConfigFile = "multi_cloud_main.tf"
    )
    
    Write-Info "Initializing Terraform for multi-cloud deployment: $Env"
    
    Push-Location $TerraformDir
    
    try {
        # Use multi-cloud configuration
        if (-not (Test-Path $ConfigFile)) {
            Write-Error "Multi-cloud configuration file not found: $ConfigFile"
            throw "Configuration file missing"
        }
        
        # Initialize with multi-cloud providers
        terraform init
        
        # Create environment-specific tfvars if it doesn't exist
        $envDir = "environments/$Env"
        $tfvarsFile = "$envDir/multi_cloud.tfvars"
        
        if (-not (Test-Path $tfvarsFile)) {
            Write-Info "Creating environment configuration: $tfvarsFile"
            New-Item -ItemType Directory -Force -Path $envDir | Out-Null
            
            $content = switch ($Env) {
                "dev" { @"
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
"@ }
                "staging" { @"
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
"@ }
                "prod" { @"
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
"@ }
            }
            
            Set-Content -Path $tfvarsFile -Value $content
            Write-Warn "Created default configuration. Please review and update: $tfvarsFile"
            Write-Warn "Especially update GCP project_id if deploying to GCP"
        }
    }
    finally {
        Pop-Location
    }
}

# Plan multi-cloud deployment
function New-TerraformPlan {
    param([string]$Env = "dev")
    
    Write-Info "Planning multi-cloud deployment for environment: $Env"
    
    Push-Location $TerraformDir
    
    try {
        $tfvarsFile = "environments/$Env/multi_cloud.tfvars"
        $planFile = "$Env-multicloud.tfplan"
        
        if (-not (Test-Path $tfvarsFile)) {
            Write-Error "Environment configuration not found: $tfvarsFile"
            throw "Configuration file missing"
        }
        
        terraform plan -var-file="$tfvarsFile" -out="$planFile" -input=false
    }
    finally {
        Pop-Location
    }
}

# Apply multi-cloud deployment
function Invoke-TerraformApply {
    param([string]$Env = "dev")
    
    Write-Info "Applying multi-cloud deployment for environment: $Env"
    
    Push-Location $TerraformDir
    
    try {
        $planFile = "$Env-multicloud.tfplan"
        
        if (-not (Test-Path $planFile)) {
            Write-Error "Plan file not found: $planFile. Run plan first."
            throw "Plan file missing"
        }
        
        terraform apply $planFile
        
        # Update kubeconfigs for all deployed clusters
        Update-Kubeconfigs -Env $Env
    }
    finally {
        Pop-Location
    }
}

# Update kubeconfigs for all clusters
function Update-Kubeconfigs {
    param([string]$Env = "dev")
    
    Write-Info "Updating kubeconfigs for deployed clusters..."
    
    Push-Location $TerraformDir
    
    try {
        # Get deployed cloud providers from Terraform state
        $outputs = terraform output -json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
        
        if ($outputs) {
            # AWS
            if ($outputs.aws_cluster_name) {
                $clusterName = $outputs.aws_cluster_name.value
                $region = $outputs.aws_region.value
                Write-Cloud "Updating AWS kubeconfig: $clusterName"
                aws eks update-kubeconfig --region $region --name $clusterName --alias "aws-$Env"
            }
            
            # GCP
            if ($outputs.gcp_cluster_name) {
                $clusterName = $outputs.gcp_cluster_name.value
                $region = $outputs.gcp_region.value
                $project = $outputs.gcp_project_id.value
                Write-Cloud "Updating GCP kubeconfig: $clusterName"
                gcloud container clusters get-credentials $clusterName --region $region --project $project
                kubectl config rename-context $clusterName "gcp-$Env"
            }
            
            # Azure
            if ($outputs.azure_cluster_name) {
                $clusterName = $outputs.azure_cluster_name.value
                $resourceGroup = $outputs.azure_resource_group.value
                Write-Cloud "Updating Azure kubeconfig: $clusterName"
                az aks get-credentials --resource-group $resourceGroup --name $clusterName --context "azure-$Env"
            }
        }
    }
    finally {
        Pop-Location
    }
    
    Write-Info "Available contexts:"
    kubectl config get-contexts
}

# Deploy enhanced monitoring and observability
function Deploy-Monitoring {
    param(
        [string]$Env = "dev",
        [string]$Cloud = "aws"
    )
    
    Write-Info "Deploying enhanced monitoring stack to $Cloud cluster..."
    
    # Switch to primary cluster context
    kubectl config use-context "$Cloud-$Env"
    
    # Create monitoring namespaces
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespaces for monitoring
    kubectl label namespace monitoring name=monitoring --overwrite
    kubectl label namespace observability name=observability --overwrite
    
    # Deploy custom monitoring dashboards
    if (Test-Path "$MonitoringDir/dashboards") {
        Write-Info "Deploying custom Grafana dashboards..."
        kubectl create configmap grafana-dashboards --from-file="$MonitoringDir/dashboards/" -n monitoring --dry-run=client -o yaml | kubectl apply -f -
    }
    
    # Deploy service monitors for multi-cloud metrics
    if (Test-Path "$MonitoringDir/multi-cloud-servicemonitor.yaml") {
        Write-Info "Deploying multi-cloud service monitors..."
        kubectl apply -f "$MonitoringDir/multi-cloud-servicemonitor.yaml"
    }
    
    Write-Info "Enhanced monitoring deployment completed"
}

# Deploy Kubernetes manifests to all clusters
function Deploy-KubernetesManifests {
    param([string]$Env = "dev")
    
    Write-Info "Deploying Kubernetes manifests to all clusters..."
    
    # Get all cluster contexts
    $contexts = kubectl config get-contexts -o name | Where-Object { $_ -like "*$Env*" }
    
    foreach ($context in $contexts) {
        Write-Cloud "Deploying to context: $context"
        kubectl config use-context $context
        
        # Apply network policies
        if (Test-Path "$K8sDir/network-policies.yaml") {
            Write-Info "Applying network policies..."
            kubectl apply -f "$K8sDir/network-policies.yaml"
        }
        
        # Apply DaemonSet
        if (Test-Path "$K8sDir/logging-daemonset.yaml") {
            Write-Info "Applying logging DaemonSet..."
            kubectl apply -f "$K8sDir/logging-daemonset.yaml"
        }
        
        # Apply security policies
        if (Test-Path "$SecurityDir/gatekeeper-policies.yaml") {
            Write-Info "Applying Gatekeeper policies..."
            kubectl apply -f "$SecurityDir/gatekeeper-policies.yaml"
        }
        
        # Wait for DaemonSet rollout
        try {
            kubectl rollout status daemonset/logging-daemon -n kube-system --timeout=300s
        }
        catch {
            Write-Warn "DaemonSet rollout timed out on $context"
        }
    }
    
    Write-Info "Kubernetes manifests deployed to all clusters"
}

# Get multi-cluster information
function Get-ClusterInfo {
    param([string]$Env = "dev")
    
    Write-Info "Getting multi-cluster information for environment: $Env"
    
    Push-Location $TerraformDir
    
    try {
        $null = terraform show 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform state not found. Deploy infrastructure first."
            return
        }
        
        Write-Host ""
        Write-Host "=== Multi-Cloud Cluster Information ===" -ForegroundColor Cyan
        
        $outputs = terraform output -json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
        
        if ($outputs) {
            # AWS cluster info
            if ($outputs.aws_cluster_name) {
                Write-Host ""
                Write-Host "🔶 AWS EKS Cluster:" -ForegroundColor Yellow
                Write-Host "  Name: $($outputs.aws_cluster_name.value)"
                Write-Host "  Endpoint: $($outputs.aws_cluster_endpoint.value)"
                Write-Host "  Region: $($outputs.aws_region.value)"
            }
            
            # GCP cluster info
            if ($outputs.gcp_cluster_name) {
                Write-Host ""
                Write-Host "🔵 GCP GKE Cluster:" -ForegroundColor Blue
                Write-Host "  Name: $($outputs.gcp_cluster_name.value)"
                Write-Host "  Endpoint: $($outputs.gcp_cluster_endpoint.value)"
                Write-Host "  Region: $($outputs.gcp_region.value)"
            }
            
            # Azure cluster info
            if ($outputs.azure_cluster_name) {
                Write-Host ""
                Write-Host "🔷 Azure AKS Cluster:" -ForegroundColor Cyan
                Write-Host "  Name: $($outputs.azure_cluster_name.value)"
                Write-Host "  Endpoint: $($outputs.azure_cluster_endpoint.value)"
                Write-Host "  Location: $($outputs.azure_location.value)"
            }
        }
    }
    finally {
        Pop-Location
    }
    
    Write-Host ""
    Write-Host "=== Kubernetes Contexts ===" -ForegroundColor Cyan
    kubectl config get-contexts
    
    Write-Host ""
    Write-Host "=== Monitoring URLs ===" -ForegroundColor Cyan
    Write-Host "Access monitoring via port-forward:"
    Write-Host "  Grafana: .\scripts\deploy.ps1 port-forward grafana"
    Write-Host "  Prometheus: .\scripts\deploy.ps1 port-forward prometheus"
    Write-Host "  Jaeger: .\scripts\deploy.ps1 port-forward jaeger"
}

# Port forward services
function Start-PortForward {
    param(
        [string]$Service = "grafana",
        [string]$Env = "dev",
        [string]$Cloud = "aws"
    )
    
    # Switch to primary monitoring cluster
    kubectl config use-context "$Cloud-$Env"
    
    switch ($Service) {
        "grafana" {
            Write-Info "Port forwarding Grafana (http://localhost:3000)"
            Write-Info "Default credentials: admin / admin123"
            kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
        }
        "prometheus" {
            Write-Info "Port forwarding Prometheus (http://localhost:9090)"
            kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
        }
        "jaeger" {
            Write-Info "Port forwarding Jaeger (http://localhost:16686)"
            kubectl port-forward -n observability svc/jaeger-query 16686:16686
        }
        "loki" {
            Write-Info "Port forwarding Loki (http://localhost:3100)"
            kubectl port-forward -n observability svc/loki-gateway 3100:80
        }
        default {
            Write-Error "Unknown service: $Service"
            Write-Info "Available services: grafana, prometheus, jaeger, loki"
            throw "Invalid service"
        }
    }
}

# Destroy multi-cloud infrastructure
function Remove-TerraformInfrastructure {
    param([string]$Env = "dev")
    
    Write-Warn "This will destroy ALL multi-cloud infrastructure for environment: $Env"
    $confirm = Read-Host "Are you absolutely sure? (yes/no)"
    
    if ($confirm -ne "yes") {
        Write-Info "Operation cancelled."
        return
    }
    
    Write-Info "Destroying multi-cloud infrastructure for environment: $Env"
    
    Push-Location $TerraformDir
    
    try {
        $tfvarsFile = "environments/$Env/multi_cloud.tfvars"
        
        if (-not (Test-Path $tfvarsFile)) {
            Write-Error "Environment configuration not found: $tfvarsFile"
            throw "Configuration file missing"
        }
        
        terraform destroy -var-file="$tfvarsFile" -auto-approve
    }
    finally {
        Pop-Location
    }
    
    Write-Info "Multi-cloud infrastructure destroyed."
}

# Show help information
function Show-Help {
    Write-Host "Multi-Cloud Kubernetes Deployment Script (PowerShell)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\deploy.ps1 <command> [environment] [options]"
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Yellow
    Write-Host "  check                    - Check prerequisites and cloud authentication"
    Write-Host "  init <env>              - Initialize Terraform for environment"
    Write-Host "  plan <env>              - Plan multi-cloud deployment"
    Write-Host "  apply <env>             - Apply multi-cloud deployment"
    Write-Host "  deploy <env> [cloud]    - Full deployment (init + plan + apply + k8s + monitoring)"
    Write-Host "  deploy-k8s <env>        - Deploy Kubernetes manifests only"
    Write-Host "  deploy-monitoring <env> [cloud] - Deploy monitoring stack only"
    Write-Host "  info <env>              - Get multi-cluster information"
    Write-Host "  port-forward <service> <env> - Port forward services (grafana, prometheus, jaeger, loki)"
    Write-Host "  destroy <env>           - Destroy all infrastructure"
    Write-Host "  help                    - Show this help"
    Write-Host ""
    Write-Host "Environments: dev, staging, prod" -ForegroundColor Green
    Write-Host "Cloud providers: aws, gcp, azure" -ForegroundColor Green
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\deploy.ps1 check"
    Write-Host "  .\deploy.ps1 deploy dev"
    Write-Host "  .\deploy.ps1 deploy prod aws"
    Write-Host "  .\deploy.ps1 port-forward grafana dev"
    Write-Host "  .\deploy.ps1 info staging"
}
# Main script execution
try {
    switch ($Command) {
        "check" {
            Test-Prerequisites
            Test-CloudAuth
        }
        "init" {
            Initialize-Terraform -Env $Environment
        }
        "plan" {
            New-TerraformPlan -Env $Environment
        }
        "apply" {
            Invoke-TerraformApply -Env $Environment
        }
        "deploy" {
            Test-Prerequisites
            Initialize-Terraform -Env $Environment
            New-TerraformPlan -Env $Environment
            Invoke-TerraformApply -Env $Environment
            Deploy-KubernetesManifests -Env $Environment
            Deploy-Monitoring -Env $Environment -Cloud $Parameter3
        }
        "deploy-k8s" {
            Deploy-KubernetesManifests -Env $Environment
        }
        "deploy-monitoring" {
            Deploy-Monitoring -Env $Environment -Cloud $Parameter3
        }
        "info" {
            Get-ClusterInfo -Env $Environment
        }
        "port-forward" {
            Start-PortForward -Service $Parameter3 -Env $Environment
        }
        "destroy" {
            Remove-TerraformInfrastructure -Env $Environment
        }
        default {
            Show-Help
        }
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}
        Write-Host "  plan [env]              - Plan Terraform deployment"
        Write-Host "  apply [env]             - Apply Terraform (infrastructure only)"
        Write-Host "  deploy [env]            - Full deployment (infrastructure + K8s)"
        Write-Host "  deploy-k8s              - Deploy Kubernetes manifests only"
        Write-Host "  info [env]              - Show cluster information"
        Write-Host "  destroy [env]           - Destroy infrastructure"
        Write-Host "  port-forward <service>  - Port forward services (grafana|prometheus|alertmanager)"
        Write-Host "  logs <component>        - Show component logs (daemon|prometheus|grafana)"
        Write-Host "  help                    - Show this help"
        Write-Host ""
        Write-Host "Environments: dev, prod (default: dev)"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\deploy.ps1 deploy dev           - Deploy development environment"
        Write-Host "  .\deploy.ps1 deploy prod          - Deploy production environment"
        Write-Host "  .\deploy.ps1 port-forward grafana - Access Grafana locally"
        Write-Host "  .\deploy.ps1 logs daemon          - Show DaemonSet logs"
    }
}