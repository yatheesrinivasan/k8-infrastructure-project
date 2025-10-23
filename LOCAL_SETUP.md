# Local Kubernetes Setup Guide

## 🚀 **Quick Start - No Company Resources Needed!**

### **Option 1: Use Existing Local Cluster (Recommended)**

If you have Docker Desktop with Kubernetes enabled or any local cluster:

```powershell
# Deploy demo monitoring stack
.\scripts\local-demo.ps1 deploy

# Access Grafana dashboards  
.\scripts\local-demo.ps1 port-forward

# Open browser to: http://localhost:3000
# Credentials: admin / admin123
```

### **Option 2: Install Local Kubernetes Environment**

#### **A. Docker Desktop (Easiest)**
1. Install Docker Desktop for Windows
2. Enable Kubernetes in Settings
3. Run deployment script above

#### **B. Minikube (Lightweight)**
```powershell
# Install minikube
choco install minikube

# Start cluster  
minikube start --memory=4096 --cpus=2

# Deploy monitoring
.\scripts\local-demo.ps1 deploy
.\scripts\local-demo.ps1 port-forward
```

#### **C. Kind (Kubernetes in Docker)**
```powershell
# Install kind
choco install kind

# Create cluster
kind create cluster --name demo --config=scripts/kind-config.yaml

# Deploy monitoring
.\scripts\local-demo.ps1 deploy
.\scripts\local-demo.ps1 port-forward
```

### **Option 3: Online Kubernetes Playground**

**Play with Kubernetes** (No installation needed):
1. Go to: https://labs.play-with-k8s.com/
2. Create a cluster (follow their instructions)
3. Clone your repo and run deployment scripts

**Killercoda Kubernetes Playground**:
1. Go to: https://killercoda.com/kubernetes
2. Start a Kubernetes scenario
3. Upload your dashboard files and run Helm commands

### **Option 4: GitHub Codespaces (Cloud Development)**

```powershell
# In GitHub Codespaces, you get a pre-configured environment
# Just run:
.\scripts\local-demo.ps1 deploy
.\scripts\local-demo.ps1 port-forward
```

## 🎯 **What You'll See**

Once deployed, your Grafana instance will have:

### **Dashboard Categories**
- **📊 Local Demo Dashboard**: Basic Kubernetes metrics
- **🌍 Multi-Cloud Overview**: Cross-cloud cluster monitoring  
- **🚀 Application Performance**: APM with request tracing
- **🔒 Security & Compliance**: Policy and security monitoring
- **💰 Cost Optimization**: Resource and cost tracking

### **Sample Metrics**
- Node count and status
- Pod distribution across namespaces
- CPU and memory utilization  
- Network traffic patterns
- Storage usage statistics

### **Interactive Features**
- Time range selection (last 1h, 6h, 24h, 7d)
- Dynamic filtering by namespace, node, service
- Drill-down capabilities from overview to details
- Alert annotations and threshold indicators

## 🛠️ **Troubleshooting**

### **No Kubernetes Cluster**
```powershell
# Error: "No accessible Kubernetes cluster found"
# Solution: Install one of the options above
```

### **Permission Issues**  
```powershell
# If you get RBAC errors, create cluster admin binding:
kubectl create clusterrolebinding demo-admin --clusterrole=cluster-admin --user=system:serviceaccount:default:default
```

### **Port Already in Use**
```powershell  
# If port 3000 is busy, use different port:
kubectl port-forward -n demo-monitoring svc/prometheus-grafana 3001:80
# Then access: http://localhost:3001
```

### **Slow Loading Dashboards**
```powershell
# Check pod status:
kubectl get pods -n demo-monitoring

# Restart Grafana if needed:
kubectl rollout restart deployment/prometheus-grafana -n demo-monitoring
```

## 🎓 **Demo Walkthrough Script**

Use this for interviews or presentations:

### **1. Infrastructure Overview**
"This is a multi-cloud Kubernetes monitoring solution I built..."

### **2. Dashboard Tour**  
- Start with Cluster Overview: "Here we can see the health of our Kubernetes clusters across different cloud providers..."
- Move to APM Dashboard: "For application performance, we're tracking request rates, latency percentiles, and error rates..."
- Show Security Dashboard: "Security monitoring includes policy violations, RBAC oversight, and compliance tracking..."
- End with Cost Dashboard: "Finally, cost optimization helps track spending and identify savings opportunities..."

### **3. Technical Deep Dive**
- Explain Prometheus queries and metrics
- Show dashboard JSON configuration  
- Discuss multi-cloud labeling strategy
- Demonstrate alert configuration

### **4. Business Value**
- Cross-cloud visibility and vendor lock-in avoidance
- Proactive monitoring and incident prevention
- Cost optimization and resource efficiency
- Security compliance and governance

## 📋 **Next Steps**

After exploring locally:

1. **Extend Dashboards**: Add your own panels and metrics
2. **Custom Metrics**: Integrate application-specific metrics  
3. **Alert Rules**: Configure alerts for your use cases
4. **Production Deployment**: Use Terraform for full cloud deployment
5. **GitOps Integration**: Set up automated dashboard updates

## 🌟 **Interview Preparation**

Practice explaining:
- Why you chose this monitoring stack
- How dashboards provide business value  
- Technical implementation details
- Scaling and production considerations
- Security and compliance aspects

This local setup gives you hands-on experience with enterprise-grade monitoring without touching any company resources! 🎯