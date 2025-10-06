# Enterprise Kubernetes Infrastructure Project

**Personal Project by Yatheesha Srinivasan**

A production-ready Kubernetes infrastructure built from scratch, demonstrating enterprise-grade DevOps practices, infrastructure as code, and cloud-native technologies. This project showcases my expertise in Kubernetes, Terraform, AWS, and security best practices.

## 🏗️ Architecture Overview

I designed and implemented this comprehensive enterprise-grade Kubernetes infrastructure solution featuring:

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

## ✨ Technical Features & My Implementation

### Infrastructure Design & Implementation
- 🚀 **AWS EKS Cluster**: I architected a managed Kubernetes solution with custom auto-scaling node groups
- 🌐 **VPC Configuration**: Designed secure multi-tier networking with public/private subnets across multiple AZs
- 🔒 **Security Groups**: Implemented least-privilege security group rules and network access controls
- 📊 **Multi-Environment**: Created modular Terraform configurations supporting dev/staging/prod environments
- 💾 **Persistent Storage**: Configured EBS CSI driver with encryption at rest for data protection

### Monitoring & Observability Stack
- 📈 **Prometheus**: Implemented comprehensive metrics collection with custom recording rules and alerting
- 📊 **Grafana**: Built custom dashboards for infrastructure and application monitoring
- 🚨 **AlertManager**: Configured intelligent alert routing with severity-based escalation
- 📋 **Custom Dashboards**: Created specialized views for cluster health, resource utilization, and performance
- 🔍 **DaemonSet Monitoring**: Developed custom logging solution with Filebeat for node-level observability

### Security Implementation
- 🛡️ **Container Scanning**: Integrated Trivy for automated vulnerability assessment in CI/CD pipeline
- 🔐 **RBAC**: Designed role-based access control following principle of least privilege
- 🌐 **Network Policies**: Implemented micro-segmentation with deny-by-default network policies
- 🔑 **Secrets Management**: Configured encrypted secret storage with KMS integration
- 📋 **Pod Security Standards**: Enforced security contexts and resource constraints
- 🔍 **OPA Gatekeeper**: Created policy-as-code framework for compliance automation

### DevOps Automation
- 🤖 **Infrastructure as Code**: Built modular Terraform architecture with reusable components
- 🔧 **Automated Deployment**: Created cross-platform scripts (Bash/PowerShell) for streamlined operations
- 📦 **Package Management**: Integrated Helm for application lifecycle management
- 🔄 **GitOps Ready**: Structured repository for continuous deployment workflows

## 🎯 Project Motivation & Approach

This project was born from my desire to create a production-ready Kubernetes infrastructure that demonstrates real-world enterprise practices. I focused on:

- **Scalability**: Designed to handle production workloads with auto-scaling capabilities
- **Security First**: Implemented defense-in-depth security strategy from day one  
- **Observability**: Built comprehensive monitoring to ensure system reliability
- **Automation**: Created tooling to reduce operational overhead and human error
- **Best Practices**: Applied industry standards and learned from enterprise implementations

## 🔧 Prerequisites

To deploy this infrastructure, ensure you have the following tools installed:

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

## 📁 Project Architecture & Structure

I designed this project with modularity and reusability in mind:

```
k8s-infrastructure-project/
├── terraform/                    # Infrastructure as Code (My Terraform Architecture)
│   ├── main.tf                  # Root configuration orchestrating all modules
│   ├── variables.tf             # Parameterized inputs for environment flexibility
│   ├── outputs.tf               # Exposed values for integration and debugging
│   ├── modules/                 # My custom reusable Terraform modules
│   │   ├── vpc/                 # Multi-AZ VPC with public/private subnets
│   │   ├── eks/                 # EKS cluster with managed node groups
│   │   ├── security/            # RBAC, network policies, and security contexts
│   │   └── monitoring/          # Prometheus/Grafana stack via Helm
│   └── environments/            # Environment-specific configurations
│       ├── dev/                 # Cost-optimized development environment
│       └── prod/                # High-availability production setup
├── kubernetes/                  # Custom Kubernetes Resources
│   ├── logging-daemonset.yaml   # My custom node-level monitoring solution
│   └── network-policies.yaml    # Zero-trust network security policies
├── monitoring/                  # Observability Configuration
│   ├── grafana-dashboards/      # Custom dashboards I created
│   └── prometheus-rules/        # Alerting rules based on SRE practices
├── security/                    # Security-First Configurations
│   ├── istio-config.yaml        # Service mesh security policies
│   └── gatekeeper-policies.yaml # Policy-as-code enforcement rules
├── scripts/                     # DevOps Automation (My Custom Scripts)
│   ├── deploy.sh               # Cross-platform deployment automation
│   ├── deploy.ps1              # Windows-compatible version
│   └── security-scan.sh        # Integrated vulnerability scanning
└── README.md                   # Project documentation and architecture decisions
```

### 🧠 Design Decisions

**Modular Terraform Architecture**: I chose to break infrastructure into logical modules (VPC, EKS, Security, Monitoring) to promote reusability and maintainability across environments.

**Environment Separation**: Created distinct configurations for dev/prod to optimize costs in development while ensuring production reliability.

**Security by Design**: Implemented network policies, RBAC, and container scanning from the beginning rather than as an afterthought.

**Cross-Platform Scripts**: Built both Bash and PowerShell versions to ensure the project works across different development environments.

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

### My Custom DaemonSet Implementation

I developed a custom DaemonSet solution that provides:

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

## 🎓 Skills Demonstrated

This project showcases my expertise in:

### Infrastructure & Cloud
- **AWS Services**: EKS, VPC, EC2, IAM, KMS, Load Balancers
- **Infrastructure as Code**: Terraform modules, state management, and best practices
- **Kubernetes**: Custom resources, operators, networking, and security

### DevOps & Automation  
- **CI/CD Thinking**: GitOps-ready structure and automated deployments
- **Scripting**: Cross-platform automation (Bash, PowerShell)
- **Container Security**: Vulnerability scanning and policy enforcement

### Monitoring & Observability
- **Metrics**: Prometheus configuration and custom recording rules
- **Visualization**: Grafana dashboard design and alerting
- **Logging**: Centralized log collection and analysis

### Security
- **Defense in Depth**: Network policies, RBAC, container security
- **Compliance**: Policy-as-code with OPA Gatekeeper
- **Encryption**: At-rest and in-transit data protection

## 🤝 Learning & Iteration

### My Development Approach

1. **Research & Planning**: Studied enterprise Kubernetes patterns and AWS best practices
2. **Incremental Development**: Built and tested each module independently  
3. **Security Integration**: Implemented security controls throughout the development process
4. **Documentation**: Maintained comprehensive documentation for knowledge sharing
5. **Testing**: Validated each component in isolation and as an integrated system

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

## � Future Enhancements

Areas I plan to expand this project:

- **Multi-Cloud Support**: Extend Terraform modules for Azure and GCP
- **Advanced Networking**: Implement Istio service mesh for advanced traffic management  
- **GitOps Integration**: Add ArgoCD for continuous deployment workflows
- **Cost Optimization**: Implement cluster autoscaling and spot instance strategies
- **Disaster Recovery**: Cross-region backup and failover capabilities

## � Project Metrics

- **Infrastructure Components**: 25+ AWS resources managed via Terraform
- **Security Policies**: 15+ network policies and RBAC rules implemented
- **Monitoring Coverage**: 50+ metrics collected with custom alerting rules
- **Automation Scripts**: 3 deployment scripts supporting multiple environments
- **Documentation**: Comprehensive README with troubleshooting guides

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💼 Professional Context

This project represents my approach to building production-grade infrastructure:

- **Enterprise Mindset**: Designed for scalability, security, and maintainability
- **Best Practices**: Applied industry standards and lessons learned from real-world implementations  
- **Documentation First**: Comprehensive documentation ensures knowledge transfer and maintenance
- **Security Focus**: Implemented security controls as foundational requirements, not afterthoughts
- **Operational Excellence**: Built tooling and automation to reduce manual operations

---

## 📞 Contact

**Yatheesha Srinivasan**
- 📧 **Email**: yathee.srinivasan.s@gmail.com
- 💼 **LinkedIn**: [Connect with me](https://linkedin.com/in/yatheesrinivasan)
- 🚀 **GitHub**: [@yatheesrinivasan](https://github.com/yatheesrinivasan)

---

**⭐ If this project demonstrates valuable skills for your team, I'd love to discuss how I can contribute!**