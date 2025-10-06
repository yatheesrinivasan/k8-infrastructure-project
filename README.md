# Kubernetes Infrastructure Project

A comprehensive Kubernetes cluster provisioning and monitoring solution with security best practices, built using Terraform and cloud-native technologies.

## 🏗️ Architecture Overview

This project provides a complete enterprise-grade Kubernetes infrastructure solution featuring:

- **Infrastructure as Code**: Modular Terraform configurations for AWS EKS
- **Monitoring Stack**: Prometheus + Grafana for comprehensive observability  
- **Security First**: Container scanning, RBAC, network policies, and secrets management
- **Production Ready**: Separate configurations for development and production environments
- **Automated Deployment**: Scripts and automation for easy cluster management

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Deployment Guide](#-deployment-guide)
- [Monitoring & Observability](#-monitoring--observability)
- [Security Implementation](#-security-implementation)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## ✨ Features

### Infrastructure
- 🚀 **AWS EKS Cluster**: Managed Kubernetes with auto-scaling node groups
- 🌐 **VPC Configuration**: Secure networking with public/private subnets
- 🔒 **Security Groups**: Properly configured ingress/egress rules
- 📊 **Multi-Environment**: Separate dev/prod configurations
- 💾 **Persistent Storage**: EBS CSI driver with encrypted volumes

### Monitoring & Observability
- 📈 **Prometheus**: Metrics collection and alerting
- 📊 **Grafana**: Rich dashboards and visualizations
- 🚨 **AlertManager**: Intelligent alert routing and notifications
- 📋 **Custom Dashboards**: Pre-configured cluster and application metrics
- 🔍 **DaemonSet Monitoring**: Node-level log and metric collection via Filebeat

### Security
- 🛡️ **Container Scanning**: Trivy integration for vulnerability assessment
- 🔐 **RBAC**: Role-based access control with least privilege principles
- 🌐 **Network Policies**: Micro-segmentation and traffic control
- 🔑 **Secrets Management**: Kubernetes secrets with encryption at rest
- 📋 **Pod Security Standards**: Enforced security contexts and policies
- 🔍 **OPA Gatekeeper**: Policy enforcement for compliance

### Automation
- 🤖 **Deployment Scripts**: Automated cluster provisioning and management
- 🔧 **Security Scanning**: Automated container vulnerability assessments
- 📦 **Helm Integration**: Package management for applications
- 🔄 **GitOps Ready**: Structured for continuous deployment workflows

## 🔧 Prerequisites

Before starting, ensure you have the following tools installed:

### Required Tools
- **Terraform** >= 1.0
- **kubectl** >= 1.24
- **AWS CLI** >= 2.0
- **Helm** >= 3.8
- **Git** >= 2.30

### Optional Tools
- **Docker** (for local development and testing)
- **jq** (for JSON processing in scripts)
- **Trivy** (will be auto-installed by security scripts)

### AWS Configuration
```bash
# Configure AWS credentials
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

### Required AWS Permissions
Your AWS user/role needs the following services:
- EC2 (VPC, Subnets, Security Groups, Load Balancers)
- EKS (Cluster and Node Group management)
- IAM (Role and Policy management)
- KMS (Key management for encryption)

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone <your-repo-url>
cd k8s-infrastructure-project

# Make scripts executable (Linux/macOS)
chmod +x scripts/*.sh
```

### 2. Deploy Development Environment
```bash
# Check prerequisites
./scripts/deploy.sh check

# Deploy complete infrastructure
./scripts/deploy.sh deploy dev
```

### 3. Access Services
```bash
# Get cluster information
./scripts/deploy.sh info dev

# Access Grafana dashboard
./scripts/deploy.sh port-forward grafana
# Open http://localhost:3000 (admin/admin123)

# Access Prometheus
./scripts/deploy.sh port-forward prometheus  
# Open http://localhost:9090
```

### 4. Windows Users
```powershell
# Use PowerShell script
.\scripts\deploy.ps1 check
.\scripts\deploy.ps1 deploy dev
.\scripts\deploy.ps1 port-forward grafana
```

## 📁 Project Structure

```
k8s-infrastructure-project/
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                  # Root Terraform configuration
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── modules/                 # Reusable Terraform modules
│   │   ├── vpc/                 # VPC and networking
│   │   ├── eks/                 # EKS cluster configuration
│   │   ├── security/            # Security policies and RBAC
│   │   └── monitoring/          # Monitoring stack deployment
│   └── environments/            # Environment-specific configurations
│       ├── dev/                 # Development environment
│       └── prod/                # Production environment
├── kubernetes/                  # Kubernetes manifests
│   ├── logging-daemonset.yaml   # Custom logging DaemonSet
│   └── network-policies.yaml    # Network security policies
├── monitoring/                  # Monitoring configurations
│   ├── grafana-dashboards/      # Custom Grafana dashboards
│   └── prometheus-rules/        # Custom alerting rules
├── security/                    # Security configurations
│   ├── istio-config.yaml        # Service mesh security
│   └── gatekeeper-policies.yaml # Policy enforcement
├── scripts/                     # Automation scripts
│   ├── deploy.sh               # Main deployment script (Linux/macOS)
│   ├── deploy.ps1              # Main deployment script (Windows)
│   └── security-scan.sh        # Security scanning utilities
└── README.md                   # This file
```

## 🚀 Deployment Guide

### Environment Configuration

#### Development Environment
- **Cluster Size**: 2 nodes (t3.medium)
- **Scaling**: 1-3 nodes
- **Storage**: 20GB EBS volumes
- **Network**: 2 Availability Zones

#### Production Environment  
- **Cluster Size**: 3 nodes (t3.large) + 2 spot instances
- **Scaling**: 2-6 nodes for main group, 1-4 for spot
- **Storage**: 50GB EBS volumes
- **Network**: 3 Availability Zones for high availability

### Step-by-Step Deployment

#### 1. Initialize Infrastructure
```bash
# Initialize Terraform
./scripts/deploy.sh init dev

# Review the deployment plan
./scripts/deploy.sh plan dev
```

#### 2. Deploy Infrastructure
```bash
# Deploy AWS infrastructure only
./scripts/deploy.sh apply dev

# Or deploy everything (infrastructure + K8s)
./scripts/deploy.sh deploy dev
```

#### 3. Deploy Kubernetes Components
```bash
# Deploy only Kubernetes manifests
./scripts/deploy.sh deploy-k8s
```

#### 4. Verify Deployment
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Verify monitoring stack
kubectl get pods -n monitoring
```

### Production Deployment

For production, use the prod environment configuration:

```bash
./scripts/deploy.sh deploy prod
```

Key production differences:
- **Higher resource limits** and node counts
- **Multi-AZ deployment** for high availability
- **Mixed instance types** (on-demand + spot instances)
- **Enhanced monitoring** and alerting thresholds

## 📊 Monitoring & Observability

### Prometheus Configuration

**Metrics Collection:**
- Node-level metrics via node-exporter
- Kubernetes API metrics
- Custom application metrics via DaemonSet
- Container resource utilization

**Key Metrics Monitored:**
- CPU utilization per node and pod
- Memory usage and availability
- Disk I/O and storage utilization
- Network traffic and latency
- Pod restart counts and failure rates

### Grafana Dashboards

**Pre-configured Dashboards:**
1. **Cluster Overview** - High-level cluster health and resource usage
2. **Node Metrics** - Detailed node-level monitoring
3. **Pod Monitoring** - Application and workload metrics
4. **DaemonSet Metrics** - Custom logging agent performance

**Access Grafana:**
```bash
# Port forward to local machine
./scripts/deploy.sh port-forward grafana

# Access at http://localhost:3000
# Default credentials: admin / admin123
```

### Custom Alerting Rules

**Critical Alerts:**
- **High CPU Usage**: >80% for 5+ minutes
- **High Memory Usage**: >85% for 5+ minutes  
- **DaemonSet Pod Down**: Critical monitoring component failure
- **Node Unready**: Kubernetes node availability issues

**Alert Routing:**
- Configure AlertManager webhooks for Slack, email, or PagerDuty
- Different severity levels with appropriate escalation paths

### DaemonSet Monitoring

The custom DaemonSet provides:

**Filebeat Agent:**
- Collects container and system logs
- Structured logging with Kubernetes metadata
- Health monitoring via HTTP endpoints

**Node Exporter:**
- Hardware and OS metrics
- Filesystem and network statistics
- Process and system load monitoring

**Monitoring Features:**
- **Health Checks**: Liveness and readiness probes
- **Resource Limits**: Controlled CPU and memory usage
- **Security Context**: Non-root execution with minimal privileges
- **Metrics Endpoint**: Prometheus integration on port 9100

## 🔒 Security Implementation

### Container Security

**Image Scanning with Trivy:**
```bash
# Scan individual images
./scripts/security-scan.sh scan-image nginx:latest

# Scan all project images
./scripts/security-scan.sh scan-common

# Scan Kubernetes manifests  
./scripts/security-scan.sh scan-k8s kubernetes/
```

**Security Policies:**
- **No root containers**: All containers run as non-root users
- **Read-only root filesystems**: Immutable container filesystems
- **Resource limits**: CPU and memory constraints
- **Security contexts**: Dropped capabilities and restricted privileges

### Network Security

**Network Policies:**
- **Default deny-all**: Explicit allow-lists for traffic
- **DNS access**: Controlled DNS resolution
- **Monitoring ingress**: Restricted access to metrics endpoints
- **Namespace isolation**: Traffic segmentation by workload type

**Implementation:**
```yaml
# Example: Deny all ingress traffic by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

### RBAC Configuration

**Service Accounts:**
- Dedicated service accounts per workload
- Minimum required permissions
- Scoped to specific namespaces where possible

**Cluster Roles:**
- **Monitoring access**: Read-only access to cluster resources
- **DaemonSet permissions**: Node-level access for log collection
- **Security scanning**: Limited access for vulnerability assessment

### Secrets Management

**Encryption:**
- **At-rest encryption**: AWS KMS integration for etcd
- **In-transit encryption**: TLS for all API communication  
- **Secret rotation**: Kubernetes secret lifecycle management

**Best Practices:**
- No hardcoded secrets in configurations
- Environment-specific secret management
- Automated secret rotation where possible

### Compliance Features

**Pod Security Standards:**
```yaml
# Namespace-level enforcement
apiVersion: v1
kind: Namespace
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

**OPA Gatekeeper Policies:**
- Security context enforcement
- Resource requirement validation
- Image policy compliance
- Network policy compliance

## ⚙️ Configuration

### Customizing Environments

Edit the environment-specific variables in `terraform/environments/`:

**Development (`terraform/environments/dev/terraform.tfvars`):**
```hcl
cluster_name = "my-k8s-dev"
environment  = "dev"

node_groups = {
  main = {
    desired_size   = 2
    max_size       = 3
    min_size       = 1
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
  }
}
```

**Production (`terraform/environments/prod/terraform.tfvars`):**
```hcl
cluster_name = "my-k8s-prod"  
environment  = "prod"

node_groups = {
  main = {
    desired_size   = 3
    max_size       = 6
    min_size       = 2
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
  }
  spot = {
    desired_size   = 2
    max_size       = 4
    min_size       = 1
    instance_types = ["t3.medium", "t3.large"] 
    capacity_type  = "SPOT"
    disk_size      = 30
  }
}
```

### Monitoring Configuration

**Custom Grafana Dashboards:**
Add dashboard JSON files to `monitoring/grafana-dashboards/`

**Custom Prometheus Rules:**  
Add alerting rules to `monitoring/prometheus-rules/`

**DaemonSet Configuration:**
Modify `kubernetes/logging-daemonset.yaml` to adjust:
- Resource limits and requests
- Log collection paths
- Monitoring intervals
- Health check configurations

### Security Configuration

**Network Policies:**
Customize `kubernetes/network-policies.yaml` for your traffic patterns

**RBAC Policies:**  
Modify service accounts and cluster roles in the security module

**Container Scanning:**
Configure Trivy scanning policies in `scripts/security-scan.sh`

## 🔧 Troubleshooting

### Common Issues

#### 1. AWS Authentication Errors
```bash
# Check AWS configuration
aws sts get-caller-identity

# Verify permissions
aws eks describe-cluster --name <cluster-name>
```

#### 2. Terraform State Issues
```bash
# Refresh Terraform state
cd terraform
terraform refresh -var-file=environments/dev/terraform.tfvars

# Import existing resources if needed
terraform import aws_eks_cluster.main <cluster-name>
```

#### 3. kubectl Connection Issues
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name <cluster-name>

# Verify connection
kubectl get nodes
```

#### 4. Pod Startup Issues
```bash
# Check pod status
kubectl get pods --all-namespaces

# View pod logs
kubectl logs -n kube-system -l app=logging-daemon

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>
```

#### 5. Monitoring Stack Issues
```bash
# Check Helm releases
helm list -n monitoring

# Verify PVCs
kubectl get pvc -n monitoring

# Check storage class
kubectl get storageclass
```

### Performance Tuning

#### Node Optimization
- Adjust instance types based on workload requirements
- Configure auto-scaling policies for traffic patterns
- Use spot instances for cost optimization (non-critical workloads)

#### Monitoring Optimization  
- Adjust Prometheus retention periods
- Configure appropriate resource limits
- Use remote storage for long-term retention

### Logs and Debugging

```bash
# View DaemonSet logs
./scripts/deploy.sh logs daemon

# View Prometheus logs  
./scripts/deploy.sh logs prometheus

# View Grafana logs
./scripts/deploy.sh logs grafana

# Get cluster information
./scripts/deploy.sh info dev
```

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/new-feature`
3. **Make changes** and test thoroughly
4. **Run security scans**: `./scripts/security-scan.sh scan-common`
5. **Commit changes**: `git commit -m "Add new feature"`
6. **Push to branch**: `git push origin feature/new-feature`
7. **Create Pull Request**

### Testing Guidelines

**Infrastructure Testing:**
- Test Terraform plans before applying
- Validate configurations in development environment first
- Run security scans on all changes

**Security Testing:**
```bash
# Run comprehensive security scan
./scripts/security-scan.sh scan-common
./scripts/security-scan.sh scan-k8s kubernetes/
```

**Monitoring Testing:**
- Verify all dashboards load correctly
- Test alert rules with synthetic data
- Validate metric collection across all nodes

### Code Standards

- **Terraform**: Follow HashiCorp style guidelines
- **Kubernetes**: Use official API version recommendations  
- **Documentation**: Update README for any configuration changes
- **Security**: Run vulnerability scans before merging

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Prometheus Community** for excellent monitoring tools
- **Grafana Labs** for visualization platform
- **Aqua Security** for Trivy vulnerability scanner
- **AWS** for EKS and cloud infrastructure
- **Kubernetes Community** for the orchestration platform

---

## 📞 Support

For questions, issues, or contributions:
- 🐛 **Issues**: Create an issue in this repository
- 💬 **Discussions**: Use GitHub Discussions for questions
- 📧 **Security**: Report security issues privately via email

---

**⭐ If this project helped you, please consider giving it a star!**