# Contributing to K8s Infrastructure Project

Thanks for your interest in this project! While this is primarily a personal learning project, I'm open to suggestions and improvements.

## Development Setup

If you want to test or modify this infrastructure:

### Prerequisites
- AWS Account with appropriate permissions
- Terraform >= 1.0
- kubectl configured
- Helm 3.x

### Local Development

1. **Clone the repository:**
   ```bash
   git clone <repo-url>
   cd k8s-infrastructure-project
   ```

2. **Set up AWS credentials:**
   ```bash
   aws configure
   # or export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
   ```

3. **Test in dev environment first:**
   ```bash
   ./scripts/deploy.sh check
   ./scripts/deploy.sh deploy dev
   ```

## Making Changes

### Terraform Modifications
- All changes should be made in the appropriate module under `terraform/modules/`
- Test with `terraform plan` before applying
- Use consistent variable naming and add descriptions
- Update module outputs if you add new resources

### Kubernetes Manifests
- Follow Kubernetes best practices for YAML formatting
- Include resource limits and security contexts
- Test manifests with `kubectl apply --dry-run=client`

### Scripts
- Maintain compatibility with both Bash and PowerShell versions
- Add error handling for new operations
- Test on multiple platforms when possible

## Testing

### Infrastructure Testing
```bash
# Always test in dev first
./scripts/deploy.sh plan dev

# Deploy and verify
./scripts/deploy.sh deploy dev
kubectl get nodes
kubectl get pods --all-namespaces
```

### Security Testing
```bash
# Run security scans
./scripts/security-scan.sh scan-k8s kubernetes/
./scripts/security-scan.sh scan-common
```

## Code Style

### Terraform
- Use meaningful resource names
- Include comments for complex configurations
- Group related resources logically
- Use locals for repeated values

### Kubernetes YAML
- Use consistent indentation (2 spaces)
- Include metadata labels for resource management
- Add comments for non-obvious configurations

### Shell Scripts
- Include error handling with `set -e`
- Use descriptive function names
- Add comments for complex logic

## Submitting Changes

Since this is a personal project, I'm not accepting large PRs, but feel free to:

1. **Open an issue** for bugs or suggestions
2. **Fork the repository** to experiment with your own modifications
3. **Share feedback** about the architecture or implementation

## Known Issues

Things I'm aware of but haven't fixed yet:

- [ ] Terraform state should be remote (S3 backend)
- [ ] Could use more comprehensive alerting rules
- [ ] Network policies could be more granular
- [ ] Should add resource quotas for better resource management
- [ ] Deployment script error handling could be improved

## Learning Resources

If you're new to any of these technologies, here are resources I found helpful:

- **Kubernetes**: Official documentation and "Kubernetes Up & Running" book
- **Terraform**: HashiCorp Learn tutorials
- **AWS EKS**: AWS documentation and workshops
- **Prometheus/Grafana**: CNCF documentation and community guides

## Questions?

Feel free to reach out if you have questions about the implementation:
- Email: yathee.srinivasan.s@gmail.com
- LinkedIn: [yatheesrinivasan](https://linkedin.com/in/yatheesrinivasan)

---

**Note:** This project is primarily for learning and demonstration purposes. Use in production environments at your own discretion and ensure you understand all security implications.