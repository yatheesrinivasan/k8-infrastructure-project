# PowerShell version of the deployment script for Windows users

param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    
    [Parameter(Position=1)]
    [string]$Environment = "dev",
    
    [Parameter(Position=2)]
    [string]$Service = "grafana"
)

# Configuration
$TerraformDir = "terraform"
$K8sDir = "kubernetes"
$SecurityDir = "security"

# Colors for output (Windows PowerShell)
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    $MissingTools = @()
    
    $RequiredTools = @("terraform", "kubectl", "aws", "helm")
    
    foreach ($Tool in $RequiredTools) {
        if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
            $MissingTools += $Tool
        }
    }
    
    if ($MissingTools.Count -gt 0) {
        Write-Error-Custom "Missing required tools: $($MissingTools -join ', ')"
        Write-Info "Please install the missing tools and try again."
        exit 1
    }
    
    Write-Info "All prerequisites are satisfied."
}

# Initialize Terraform
function Initialize-Terraform {
    param([string]$Env)
    
    Write-Info "Initializing Terraform for environment: $Env"
    
    Push-Location $TerraformDir
    
    try {
        terraform init
        
        $VarFile = "environments/$Env/terraform.tfvars"
        if (Test-Path $VarFile) {
            Write-Info "Using variables file: $VarFile"
        } else {
            Write-Error-Custom "Variables file not found: $VarFile"
            exit 1
        }
    }
    finally {
        Pop-Location
    }
}

# Plan Terraform deployment
function Plan-Terraform {
    param([string]$Env)
    
    Write-Info "Planning Terraform deployment for environment: $Env"
    
    Push-Location $TerraformDir
    
    try {
        $VarFile = "environments/$Env/terraform.tfvars"
        $PlanFile = "$Env.tfplan"
        terraform plan -var-file=$VarFile -out=$PlanFile
    }
    finally {
        Pop-Location
    }
}

# Apply Terraform
function Apply-Terraform {
    param([string]$Env)
    
    Write-Info "Applying Terraform configuration for environment: $Env"
    
    Push-Location $TerraformDir
    
    try {
        $PlanFile = "$Env.tfplan"
        
        if (Test-Path $PlanFile) {
            terraform apply $PlanFile
        } else {
            Write-Warn "Plan file not found. Running apply with var-file..."
            $VarFile = "environments/$Env/terraform.tfvars"
            terraform apply -var-file=$VarFile -auto-approve
        }
        
        # Get cluster name and update kubeconfig
        $ClusterName = terraform output -raw cluster_name
        $AwsRegion = "us-west-2"  # Default region
        
        try {
            $AwsRegion = (terraform output -json | ConvertFrom-Json).aws_region.value
        } catch {
            # Use default if output not available
        }
        
        Write-Info "Updating kubeconfig for cluster: $ClusterName"
        aws eks update-kubeconfig --region $AwsRegion --name $ClusterName
    }
    finally {
        Pop-Location
    }
}

# Deploy Kubernetes manifests
function Deploy-K8s {
    Write-Info "Deploying Kubernetes manifests..."
    
    # Apply network policies first
    $NetworkPolicies = "$K8sDir/network-policies.yaml"
    if (Test-Path $NetworkPolicies) {
        Write-Info "Applying network policies..."
        kubectl apply -f $NetworkPolicies
    }
    
    # Apply DaemonSet
    $DaemonSet = "$K8sDir/logging-daemonset.yaml"
    if (Test-Path $DaemonSet) {
        Write-Info "Applying logging DaemonSet..."
        kubectl apply -f $DaemonSet
    }
    
    # Wait for pods to be ready
    Write-Info "Waiting for DaemonSet pods to be ready..."
    kubectl rollout status daemonset/logging-daemon -n kube-system --timeout=300s
    
    Write-Info "Kubernetes manifests deployed successfully."
}

# Get cluster info
function Get-ClusterInfo {
    param([string]$Env)
    
    Write-Info "Getting cluster information for environment: $Env"
    
    Push-Location $TerraformDir
    
    try {
        # Check if Terraform state exists
        $StateCheck = terraform show 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Terraform state not found. Please deploy the infrastructure first."
            return
        }
        
        Write-Host ""
        Write-Host "=== Cluster Information ===" -ForegroundColor Cyan
        
        $ClusterName = try { terraform output -raw cluster_name 2>$null } catch { "N/A" }
        $ClusterEndpoint = try { terraform output -raw cluster_endpoint 2>$null } catch { "N/A" }
        $VpcId = try { terraform output -raw vpc_id 2>$null } catch { "N/A" }
        
        Write-Host "Cluster Name: $ClusterName"
        Write-Host "Cluster Endpoint: $ClusterEndpoint"
        Write-Host "VPC ID: $VpcId"
    }
    finally {
        Pop-Location
    }
    
    Write-Host ""
    Write-Host "=== Kubernetes Status ===" -ForegroundColor Cyan
    try {
        kubectl get nodes -o wide
    } catch {
        Write-Host "Unable to connect to cluster"
    }
    
    Write-Host ""
    Write-Host "=== Monitoring URLs ===" -ForegroundColor Cyan
    try {
        $GrafanaHost = kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
        Write-Host "Grafana: $GrafanaHost"
    } catch {
        Write-Host "Grafana: Not available"
    }
    Write-Host "Prometheus: Available via port-forward: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
}

# Port forward services
function Start-PortForward {
    param([string]$ServiceName)
    
    switch ($ServiceName.ToLower()) {
        "grafana" {
            Write-Info "Port forwarding Grafana (http://localhost:3000)"
            kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
        }
        "prometheus" {
            Write-Info "Port forwarding Prometheus (http://localhost:9090)"
            kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
        }
        "alertmanager" {
            Write-Info "Port forwarding AlertManager (http://localhost:9093)"
            kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
        }
        default {
            Write-Error-Custom "Unknown service: $ServiceName"
            Write-Host "Available services: grafana, prometheus, alertmanager"
            exit 1
        }
    }
}

# Show logs
function Show-Logs {
    param([string]$Component)
    
    switch ($Component.ToLower()) {
        "daemon" {
            Write-Info "Showing DaemonSet logs..."
            kubectl logs -n kube-system -l app=logging-daemon --tail=50 -f
        }
        "prometheus" {
            Write-Info "Showing Prometheus logs..."
            kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus --tail=50 -f
        }
        "grafana" {
            Write-Info "Showing Grafana logs..."
            kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50 -f
        }
        default {
            Write-Error-Custom "Unknown component: $Component"
            Write-Host "Available components: daemon, prometheus, grafana"
            exit 1
        }
    }
}

# Destroy infrastructure
function Remove-Terraform {
    param([string]$Env)
    
    Write-Warn "This will destroy all infrastructure for environment: $Env"
    $Confirm = Read-Host "Are you sure? (yes/no)"
    
    if ($Confirm -ne "yes") {
        Write-Info "Operation cancelled."
        return
    }
    
    Write-Info "Destroying Terraform infrastructure for environment: $Env"
    
    Push-Location $TerraformDir
    
    try {
        $VarFile = "environments/$Env/terraform.tfvars"
        terraform destroy -var-file=$VarFile -auto-approve
    }
    finally {
        Pop-Location
    }
    
    Write-Info "Infrastructure destroyed."
}

# Main logic
switch ($Command.ToLower()) {
    "check" {
        Test-Prerequisites
    }
    "init" {
        Test-Prerequisites
        Initialize-Terraform $Environment
    }
    "plan" {
        Test-Prerequisites
        Plan-Terraform $Environment
    }
    "apply" {
        Test-Prerequisites
        Initialize-Terraform $Environment
        Plan-Terraform $Environment
        Apply-Terraform $Environment
    }
    "deploy" {
        Test-Prerequisites
        Initialize-Terraform $Environment
        Apply-Terraform $Environment
        Deploy-K8s
    }
    "deploy-k8s" {
        Deploy-K8s
    }
    "info" {
        Get-ClusterInfo $Environment
    }
    "destroy" {
        Test-Prerequisites
        Remove-Terraform $Environment
    }
    "port-forward" {
        Start-PortForward $Service
    }
    "logs" {
        Show-Logs $Service
    }
    default {
        Write-Host "Kubernetes Infrastructure Management Script" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage: .\deploy.ps1 <command> [environment] [options]"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  check                    - Check prerequisites"
        Write-Host "  init [env]              - Initialize Terraform"
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