# K8s Infrastructure Project

**Personal project by Yathee Srinivasan**  
*Building production-grade Kubernetes infrastructure from scratch*

## What This Project Is About

I built this Kubernetes infrastructure project to demonstrate my skills with container orchestration, infrastructure as code, and DevOps practices. The main goal was to create a production-ready EKS cluster with proper monitoring and security - something I could actually deploy in a real environment.

## What I Built

- **AWS EKS Cluster**: Using Terraform modules I wrote myself
- **Monitoring Setup**: Prometheus and Grafana (took some time to get the configs right)
- **Security Layer**: RBAC policies, network policies, and vulnerability scanning
- **Custom DaemonSet**: For logging and metrics collection across all nodes
- **Multiple Environments**: Separate dev and prod configurations

## Quick Overview

```
terraform/           # My Terraform modules and configs
├── modules/        # VPC, EKS, monitoring, security modules
├── environments/   # Dev and prod environment settings
└── main.tf        # Main orchestration file

kubernetes/         # Kubernetes manifests
├── logging-daemonset.yaml    # Custom logging solution
└── network-policies.yaml     # Security policies

scripts/           # Deployment automation
├── deploy.sh      # Main deployment script (Linux/Mac)
└── deploy.ps1     # Windows version

monitoring/        # Grafana dashboards and Prometheus configs
security/          # Security policies and configs
```

## Getting Started

### Prerequisites
You'll need:
- Terraform (>= 1.0)
- AWS CLI configured
- kubectl 
- Helm (for monitoring stack)

### Deploy Development Environment

1. **Clone and setup:**
   ```bash
   git clone <repo-url>
   cd k8s-infrastructure-project
   chmod +x scripts/deploy.sh
   ```

2. **Check prerequisites:**
   ```bash
   ./scripts/deploy.sh check
   ```

3. **Deploy everything:**
   ```bash
   ./scripts/deploy.sh deploy dev
   ```

### Windows Users
```powershell
.\scripts\deploy.ps1 check
.\scripts\deploy.ps1 deploy dev
```

## Architecture Details

### Infrastructure Layout
The Terraform setup creates:
- **VPC**: Multi-AZ setup with public/private subnets
- **EKS Cluster**: Managed K8s with auto-scaling node groups
- **Security Groups**: Least privilege access rules
- **IAM Roles**: Proper service account bindings

### Monitoring Stack
I set up Prometheus and Grafana via Helm charts:
- **Metrics Collection**: Node metrics, K8s API metrics, custom app metrics
- **Dashboards**: Created custom dashboards for cluster health and resource usage
- **Alerting**: Basic alert rules for high CPU/memory and pod failures

### Security Approach
- **Network Policies**: Default deny-all with explicit allow rules
- **RBAC**: Service accounts with minimal required permissions  
- **Container Scanning**: Trivy integration for vulnerability detection
- **Pod Security**: Security contexts, resource limits, non-root users

## Development Notes

### Custom DaemonSet Implementation
I built a custom DaemonSet that runs on every node to collect:
- Container logs via Filebeat
- Node metrics via node-exporter
- Health status reporting

Had to work through some permission issues with the service accounts, but got it working properly.

### Environment Differences

**Dev Environment:**
- 2 t3.medium nodes (cost optimization)
- Smaller storage volumes
- Relaxed resource limits for testing

**Production Environment:**
- 3 t3.large nodes + spot instances
- Multi-AZ deployment
- Stricter security policies
- Enhanced monitoring thresholds

## Key Commands

### Deployment Management
```bash
# Deploy infrastructure only
./scripts/deploy.sh apply dev

# Deploy K8s manifests only  
./scripts/deploy.sh deploy-k8s

# Get cluster info
./scripts/deploy.sh info dev

# Port forward to services
./scripts/deploy.sh port-forward grafana
./scripts/deploy.sh port-forward prometheus
```

### Monitoring Access
```bash
# Grafana: http://localhost:3000 (admin/admin123)
# Prometheus: http://localhost:9090
```

### Security Scanning
```bash
./scripts/security-scan.sh scan-image nginx:latest
./scripts/security-scan.sh scan-k8s kubernetes/
```

## Configuration

### Customizing Environments
Edit the `.tfvars` files in `terraform/environments/`:

**Dev config:**
```hcl
cluster_name = "yathee-k8s-dev"
environment  = "dev"
node_groups = {
  main = {
    desired_size   = 2
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
  }
}
```

**Prod config:**
```hcl
cluster_name = "yathee-k8s-prod"  
environment  = "prod"
node_groups = {
  main = {
    desired_size   = 3
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
  }
  spot = {
    desired_size   = 2
    instance_types = ["t3.medium", "t3.large"]
    capacity_type  = "SPOT"
  }
}
```

## Troubleshooting

### Common Issues I Ran Into

**AWS Authentication:**
```bash
# Check your AWS config
aws sts get-caller-identity
aws eks describe-cluster --name <cluster-name>
```

**Kubectl Connection:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name <cluster-name>
```

**Pod Issues:**
```bash
# Check pod status and logs
kubectl get pods --all-namespaces
kubectl logs -n kube-system -l app=logging-daemon
kubectl describe pod <pod-name>
```

**Monitoring Stack Not Starting:**
- Check if PVCs are bound
- Verify storage class exists
- Look at Helm release status

## What I Learned

Building this project taught me a lot about:
- **Terraform Best Practices**: Modular design, state management, variable organization
- **Kubernetes Networking**: How network policies actually work in practice
- **Monitoring Setup**: Getting Prometheus configs right, creating useful dashboards
- **Security**: Implementing defense-in-depth without breaking functionality
- **DevOps Automation**: Writing scripts that handle edge cases and provide good UX

## Future Improvements

Things I want to add:
- GitOps with ArgoCD for continuous deployment
- Istio service mesh for advanced traffic management
- Multi-region setup for disaster recovery
- Cost optimization with cluster autoscaler
- Integration with external secrets management

## Project Stats

- **AWS Resources**: ~25 resources managed via Terraform
- **Kubernetes Objects**: 15+ custom manifests  
- **Lines of Code**: ~2000 lines across Terraform, YAML, and scripts
- **Development Time**: Built over several weekends and evenings

## Technical Skills Demonstrated

- Infrastructure as Code (Terraform)
- Container orchestration (Kubernetes)
- Cloud services (AWS EKS, VPC, IAM)
- Monitoring and observability (Prometheus, Grafana)
- Security best practices (RBAC, network policies, scanning)
- Automation and scripting (Bash, PowerShell)
- DevOps practices and tooling

---

## About This Project

I built this as a personal learning project to understand production Kubernetes deployments. It represents real-world skills I've developed and demonstrates my ability to work with modern cloud-native technologies.

**Contact:**
- Email: yathee.srinivasan.s@gmail.com  
- LinkedIn: [linkedin.com/in/yatheesrinivasan](https://linkedin.com/in/yatheesrinivasan)
- GitHub: [@yatheesrinivasan](https://github.com/yatheesrinivasan)

---

*This project is ready for production use and demonstrates enterprise-grade practices.*