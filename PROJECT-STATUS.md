# Project Status - K8s Infrastructure

**Yathee Srinivasan** - Personal Project Progress

## Current Status: Ready for Demo ✅

Got the whole infrastructure project working! This took me a few weeks of evening and weekend work, but I'm happy with how it turned out. Everything deploys cleanly and the monitoring stack is solid.

## Project Location
```
C:\temp\k8s-infrastructure-project\
```

## Quick Demo Commands

**For development testing:**
```bash
# Check if everything's installed
.\scripts\deploy.ps1 check

# Deploy the full stack
.\scripts\deploy.ps1 deploy dev

# Access monitoring (this is pretty cool to show)
.\scripts\deploy.ps1 port-forward grafana
# Browser: http://localhost:3000 (admin/admin123)
```

**For production setup:**
```bash
.\scripts\deploy.ps1 deploy prod
```

## What I Built

### Infrastructure Core
✅ **Terraform Setup** - Built this from scratch
- Modular design with separate VPC, EKS, security, and monitoring modules
- Dev vs prod environment configs (learned about cost optimization the hard way)
- Proper state management and variable organization

✅ **AWS EKS Cluster** - This was the trickiest part
- Auto-scaling node groups with mixed instance types
- Took a while to get the IAM permissions right
- Multi-AZ setup for high availability

### Monitoring & Observability  
✅ **Prometheus + Grafana** - Really proud of this part
- Custom dashboards that actually show useful info
- Alert rules for the important stuff (high CPU, pod crashes, etc.)
- Had to debug some PVC issues with the Grafana storage

✅ **Custom DaemonSet** - My own implementation
- Runs Filebeat and node-exporter on every node
- Collects both container logs and system metrics
- Service account permissions took some trial and error

### Security Implementation
✅ **Network Policies** - Default deny-all approach
- Only allow necessary communication between pods
- DNS access is restricted but functional
- Learned a lot about K8s networking debugging this

✅ **Vulnerability Scanning** - Trivy integration
- Scans container images for known CVEs
- Added it to the deployment scripts for automation
- Found and fixed a few issues in my initial image choices

✅ **RBAC Setup** - Proper permissions everywhere
- Service accounts with minimal required access
- Cluster roles scoped appropriately
- No overly broad permissions (learned this lesson from reading about production incidents)

### DevOps Automation
✅ **Deployment Scripts** - Cross-platform support
- Bash version for Linux/Mac environments
- PowerShell version for Windows (like this machine)
- Error handling and user-friendly output

## Development Notes

**What Worked Well:**
- Terraform modules made it easy to manage complexity
- Helm charts simplified the monitoring stack deployment
- Having separate dev/prod configs saved money during testing

**What Was Challenging:**
- Getting the VPC networking right took several iterations
- Prometheus configuration has a lot of knobs to tune  
- Network policies are powerful but easy to get wrong
- AWS IAM can be frustrating when permissions are too restrictive

**Things I'd Do Differently:**
- Would start with network policies earlier in development
- Should have set up proper Terraform state backend from the beginning
- Could have used more spot instances in dev to save costs

## Demo Flow for Interviews

1. **Show the code structure** - explain the modular approach
2. **Deploy dev environment** - demonstrate the automation
3. **Access Grafana dashboards** - show the custom monitoring setup
4. **Explain security approach** - discuss the defense-in-depth strategy
5. **Walk through troubleshooting** - show how to debug issues

## Skills This Project Demonstrates

- **Infrastructure as Code**: Terraform best practices and modular design
- **Kubernetes**: Deep understanding of networking, security, and operations
- **Monitoring**: Prometheus/Grafana setup and custom dashboard creation
- **Security**: RBAC, network policies, vulnerability scanning, least privilege
- **DevOps**: Automation, cross-platform scripting, error handling
- **AWS**: EKS, VPC, IAM, security best practices
- **Problem Solving**: Debugging complex distributed systems issues

## Future Enhancements (If I Had More Time)

- **GitOps**: ArgoCD for continuous deployment
- **Service Mesh**: Istio for advanced traffic management
- **Cost Optimization**: Cluster autoscaler and better spot instance usage
- **Backup Strategy**: Velero for disaster recovery
- **Multi-Region**: Cross-region failover capabilities

## Personal Learning Outcomes

This project taught me a ton about production Kubernetes operations. The biggest learning was around the interconnected nature of networking, security, and observability in K8s. You can't just bolt security on at the end - it has to be designed in from the start.

Also learned that infrastructure as code is only as good as your testing and validation processes. I spent a lot of time iterating on the Terraform modules to get them right.

---

**Ready for technical discussions and demo!**

Contact: yathee.srinivasan.s@gmail.com