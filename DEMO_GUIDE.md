# 🎯 Grafana Dashboard Demo Guide

## 🚀 Quick Demo Setup (Play with Kubernetes)

### 1. Setup Commands
```bash
# Initialize cluster
kubeadm init --apiserver-advertise-address $(hostname -i) --pod-network-cidr=10.5.0.0/16
kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Clone and deploy
git clone https://github.com/yatheesrinivasan/k8-infrastructure-project.git
cd k8-infrastructure-project
chmod +x scripts/pwk-deploy.sh
./scripts/pwk-deploy.sh
```

### 2. Access Information
- **URL**: Click port "30000" button or http://NODE_IP:30000
- **Username**: admin
- **Password**: admin123

## 📊 Dashboard Tour Script

### Opening Statement
*"I've built a comprehensive Kubernetes monitoring solution using Grafana, Prometheus, and custom dashboards. Let me walk you through the key features."*

### 1. Custom Multi-Cloud Dashboard
**Navigate to**: "Demo - Multi-Cloud Kubernetes Overview"

**Key Points to Highlight**:
- ✅ **Real-time Metrics**: "These stats update every 30 seconds showing live cluster health"
- 🎯 **Custom Queries**: "I wrote PromQL queries like `count(kube_node_info)` to aggregate node data"
- 📊 **Visual Design**: "Notice the color thresholds - red for issues, green for healthy states"
- 🔄 **Dynamic Variables**: "The namespace filter allows drilling down into specific applications"

**Technical Details**:
```promql
# Node count query
count(kube_node_info)

# Running pods
count(kube_pod_status_phase{phase="Running"})

# CPU usage calculation
100 - (avg by(instance)(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### 2. Built-in Kubernetes Dashboards
**Navigate to**: "Kubernetes / Compute Resources / Cluster"

**Key Points**:
- 📈 **Resource Trends**: "Historical CPU and memory usage patterns"
- 🎛️ **Capacity Planning**: "Helps predict when we need to scale"
- 🔍 **Drill-down Capability**: "Can click to investigate specific nodes or pods"

### 3. Node Exporter Dashboard
**Navigate to**: "Node Exporter / Nodes"

**Key Points**:
- 💾 **Infrastructure Monitoring**: "Deep system metrics like disk I/O, network traffic"
- ⚡ **Performance Analysis**: "Can identify bottlenecks and resource constraints"
- 📊 **Multi-dimensional Views**: "Correlated metrics for comprehensive analysis"

## 🎓 Interview Q&A Preparation

### Technical Questions

**Q**: "How did you configure the dashboards?"
**A**: "I created JSON dashboard definitions with custom PromQL queries, deployed them via ConfigMaps with Grafana's auto-discovery labels, and integrated them into the Helm chart deployment."

**Q**: "What makes this enterprise-ready?"
**A**: "It includes persistent storage, RBAC configuration, automated alerts, dashboard versioning through Git, and supports multi-tenant access patterns."

**Q**: "How would you scale this?"
**A**: "Prometheus federation for multi-cluster monitoring, Grafana high availability with load balancing, and distributed storage with Thanos for long-term retention."

### Business Questions

**Q**: "What business value does this provide?"
**A**: "Reduces MTTR through faster issue identification, enables proactive capacity planning, provides cost optimization insights, and ensures compliance with SLAs."

**Q**: "How do you handle alerts?"
**A**: "Configured AlertManager with escalation policies, integrated with Slack/PagerDuty, and set up intelligent alert routing based on severity and team ownership."

## 🛠️ Demo Troubleshooting

### If Grafana doesn't load:
```bash
# Check pod status
kubectl get pods -n demo-monitoring

# Restart if needed
kubectl rollout restart deployment/prometheus-grafana -n demo-monitoring

# Check logs
kubectl logs -n demo-monitoring -l app.kubernetes.io/name=grafana
```

### If dashboards are missing:
```bash
# Check ConfigMaps
kubectl get configmaps -n demo-monitoring | grep dashboard

# Restart Grafana to reload
kubectl rollout restart deployment/prometheus-grafana -n demo-monitoring
```

### If metrics aren't showing:
```bash
# Check Prometheus targets
kubectl port-forward -n demo-monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets
```

## 🌟 Advanced Demo Features

### Show Prometheus Directly
```bash
kubectl port-forward -n demo-monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
- Demonstrate PromQL queries
- Show service discovery
- Explain target scraping

### Show AlertManager
```bash
kubectl port-forward -n demo-monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
```
- Show alert rules
- Demonstrate alert routing
- Explain silencing and inhibition

### Custom Metrics Demo
```bash
# Deploy sample app with custom metrics
kubectl apply -f https://raw.githubusercontent.com/prometheus/client_golang/main/examples/random/main.go
```

## 🚀 Next Steps After Demo

1. **Infrastructure as Code**: "In production, this is deployed via Terraform across AWS, GCP, and Azure"
2. **GitOps Integration**: "Dashboard updates are automated through CI/CD pipelines"
3. **Multi-Cloud Extension**: "The same pattern scales to monitor across cloud providers"
4. **Security Integration**: "Includes compliance dashboards and security policy monitoring"
5. **Cost Optimization**: "Integrated with cloud billing APIs for cost tracking"

## 📋 Key Takeaways for Interviewers

✅ **Technical Depth**: Understanding of Prometheus, Grafana, Kubernetes
✅ **Practical Implementation**: Hands-on experience with monitoring stacks  
✅ **Business Awareness**: Connecting technical solutions to business value
✅ **Scalability Thinking**: Consideration for enterprise requirements
✅ **DevOps Practices**: Infrastructure as Code, GitOps, automation

*This demo showcases both technical expertise and practical problem-solving skills that are valuable in cloud-native environments.*