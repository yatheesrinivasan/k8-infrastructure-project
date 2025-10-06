# Contributing to Kubernetes Infrastructure Project

Thank you for your interest in contributing! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- AWS Account with appropriate permissions
- Terraform >= 1.0
- kubectl >= 1.24
- AWS CLI >= 2.0
- Helm >= 3.8

### Development Setup
1. Fork the repository
2. Clone your fork: `git clone <your-fork-url>`
3. Create a feature branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## 🧪 Testing

### Infrastructure Testing
- Always run `terraform plan` before applying changes
- Test in development environment first
- Validate security configurations

### Security Testing
```bash
# Run security scans
./scripts/security-scan.sh scan-common
./scripts/security-scan.sh scan-k8s kubernetes/
```

### Monitoring Testing
- Verify dashboards load correctly
- Test alert rules
- Validate metrics collection

## 📝 Code Standards

### Terraform
- Follow HashiCorp configuration style
- Use meaningful resource names
- Include proper tags
- Document variables and outputs

### Kubernetes
- Use official API versions
- Follow security best practices
- Include resource limits
- Add proper labels and annotations

### Documentation
- Update README for configuration changes
- Document new features
- Include troubleshooting steps

## 🔒 Security Guidelines

- Never commit secrets or credentials
- Run vulnerability scans on container images
- Follow least privilege principles
- Review security policies before changes

## 🐛 Reporting Issues

- Use GitHub Issues for bug reports
- Include environment details
- Provide reproduction steps
- Add relevant logs or error messages

## 📋 Pull Request Process

1. Ensure CI checks pass
2. Update documentation if needed
3. Add tests for new features
4. Request review from maintainers
5. Address feedback promptly

## 🤝 Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Maintain professional communication

## 📚 Resources

- [Terraform Documentation](https://terraform.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks)
- [Prometheus Documentation](https://prometheus.io/docs)
- [Grafana Documentation](https://grafana.com/docs)

Thank you for contributing! 🙏