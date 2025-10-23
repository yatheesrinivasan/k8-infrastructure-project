#!/bin/bash
# GitHub Codespaces Kubernetes Setup
# Creates local k3s cluster and deploys Grafana

echo "🚀 Setting up Kubernetes in GitHub Codespaces..."

# Install k3s (lightweight Kubernetes)
echo "📦 Installing k3s..."
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
export KUBECONFIG=~/.kube/config

# Wait for k3s to be ready
echo "⏳ Waiting for k3s to be ready..."
sudo k3s kubectl wait --for=condition=Ready node --all --timeout=60s

# Install Helm
echo "📦 Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add Helm repositories
echo "📚 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
echo "🏗️ Creating monitoring namespace..."
kubectl create namespace demo-monitoring

# Deploy Prometheus + Grafana
echo "📊 Deploying monitoring stack..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace demo-monitoring \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=ClusterIP \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.retention=7d \
  --set grafana.persistence.enabled=false \
  --set prometheus.prometheusSpec.storageSpec=null \
  --wait --timeout=10m

# Deploy custom dashboard
echo "🎨 Deploying custom dashboard..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: codespace-dashboard
  namespace: demo-monitoring
  labels:
    grafana_dashboard: "1"
data:
  codespace-demo.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Codespace Demo - K8s Monitoring",
        "tags": ["codespace", "demo", "k8s"],
        "style": "dark",
        "timezone": "browser",
        "refresh": "30s",
        "schemaVersion": 30,
        "time": {"from": "now-30m", "to": "now"},
        "panels": [
          {
            "id": 1,
            "title": "🎯 Demo Status",
            "type": "stat",
            "gridPos": {"h": 4, "w": 24, "x": 0, "y": 0},
            "targets": [{"expr": "1", "legendFormat": "Grafana Demo Ready!", "refId": "A"}],
            "fieldConfig": {"defaults": {"color": {"mode": "thresholds"}, "thresholds": {"steps": [{"color": "green", "value": null}]}}}
          },
          {
            "id": 2,
            "title": "Cluster Nodes",
            "type": "stat",
            "gridPos": {"h": 6, "w": 8, "x": 0, "y": 4},
            "targets": [{"expr": "count(kube_node_info)", "legendFormat": "Nodes", "refId": "A"}],
            "fieldConfig": {"defaults": {"color": {"mode": "thresholds"}}}
          },
          {
            "id": 3,
            "title": "Running Pods",
            "type": "stat",
            "gridPos": {"h": 6, "w": 8, "x": 8, "y": 4},
            "targets": [{"expr": "count(kube_pod_status_phase{phase=\"Running\"})", "legendFormat": "Running", "refId": "A"}],
            "fieldConfig": {"defaults": {"color": {"mode": "thresholds"}}}
          },
          {
            "id": 4,
            "title": "Namespaces",
            "type": "stat", 
            "gridPos": {"h": 6, "w": 8, "x": 16, "y": 4},
            "targets": [{"expr": "count(group by (namespace) (kube_namespace_created))", "legendFormat": "Namespaces", "refId": "A"}],
            "fieldConfig": {"defaults": {"color": {"mode": "thresholds"}}}
          },
          {
            "id": 5,
            "title": "📊 Interview Demo Points",
            "type": "text",
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 10},
            "options": {
              "content": "### 🎯 Key Demo Features:\\n\\n✅ **Custom Grafana Dashboards**\\n✅ **Prometheus Metrics Collection**  \\n✅ **Real-time Kubernetes Monitoring**\\n✅ **PromQL Query Examples**\\n✅ **Infrastructure as Code (Helm)**\\n✅ **Container Orchestration**\\n\\n### 🚀 Technical Stack:\\n- **Kubernetes**: k3s cluster\\n- **Monitoring**: Prometheus + Grafana\\n- **Deployment**: Helm charts\\n- **Metrics**: kube-state-metrics, node-exporter",
              "mode": "markdown"
            }
          },
          {
            "id": 6,
            "title": "Pod Status Over Time",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 10},
            "targets": [{"expr": "count by (phase) (kube_pod_status_phase)", "legendFormat": "{{phase}}", "refId": "A"}],
            "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"}}}
          }
        ]
      }
    }
EOF

# Restart Grafana to load dashboard
kubectl rollout restart deployment/prometheus-grafana -n demo-monitoring

# Wait for Grafana to be ready
echo "⏳ Waiting for Grafana to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n demo-monitoring --timeout=300s

# Setup port forwarding in background
echo "🌐 Setting up port forwarding..."
kubectl port-forward -n demo-monitoring svc/prometheus-grafana 3000:80 &

echo ""
echo "✅ Setup Complete!"
echo ""
echo "🎯 Access Grafana:"
echo "   1. Go to the 'PORTS' tab in VS Code"
echo "   2. Click the 🌐 icon next to port 3000"
echo "   3. Login with: admin / admin123"
echo ""
echo "📊 Available Dashboards:"
echo "   • Codespace Demo - K8s Monitoring (Custom)"
echo "   • Kubernetes / Compute Resources / Cluster" 
echo "   • Node Exporter / Nodes"
echo ""
echo "🔍 To check status:"
echo "   kubectl get pods -n demo-monitoring"