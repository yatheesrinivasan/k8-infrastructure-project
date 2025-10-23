#!/bin/bash
# Quick deployment script for Play with Kubernetes
# Deploys Grafana + Prometheus with custom dashboards

echo "🚀 Deploying Grafana Monitoring Stack for Demo..."

# Add Helm repository
echo "📦 Adding Helm repositories..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create monitoring namespace
echo "🏗️ Creating monitoring namespace..."
kubectl create namespace demo-monitoring

# Deploy kube-prometheus-stack with Grafana
echo "📊 Deploying Prometheus + Grafana..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace demo-monitoring \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30000 \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.retention=7d \
  --set alertmanager.enabled=true \
  --wait --timeout=10m

# Deploy custom dashboards
echo "🎨 Deploying custom dashboards..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-dashboards
  namespace: demo-monitoring
  labels:
    grafana_dashboard: "1"
data:
  demo-cluster-overview.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Demo - Multi-Cloud Kubernetes Overview",
        "tags": ["demo", "kubernetes", "multicloud"],
        "style": "dark",
        "timezone": "browser",
        "refresh": "30s",
        "schemaVersion": 30,
        "time": {"from": "now-1h", "to": "now"},
        "panels": [
          {
            "id": 1,
            "title": "Cluster Nodes Status",
            "type": "stat",
            "gridPos": {"h": 6, "w": 8, "x": 0, "y": 0},
            "targets": [
              {
                "expr": "count(kube_node_info)",
                "legendFormat": "Total Nodes",
                "refId": "A"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "color": {"mode": "thresholds"},
                "thresholds": {
                  "steps": [
                    {"color": "red", "value": null},
                    {"color": "green", "value": 1}
                  ]
                }
              }
            }
          },
          {
            "id": 2,
            "title": "Running Pods",
            "type": "stat",
            "gridPos": {"h": 6, "w": 8, "x": 8, "y": 0},
            "targets": [
              {
                "expr": "count(kube_pod_status_phase{phase=\"Running\"})",
                "legendFormat": "Running Pods",
                "refId": "A"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "color": {"mode": "thresholds"},
                "thresholds": {
                  "steps": [
                    {"color": "red", "value": null},
                    {"color": "green", "value": 1}
                  ]
                }
              }
            }
          },
          {
            "id": 3,
            "title": "Namespaces",
            "type": "stat",
            "gridPos": {"h": 6, "w": 8, "x": 16, "y": 0},
            "targets": [
              {
                "expr": "count(kube_namespace_created)",
                "legendFormat": "Namespaces",
                "refId": "A"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "color": {"mode": "thresholds"},
                "thresholds": {
                  "steps": [
                    {"color": "green", "value": null}
                  ]
                }
              }
            }
          },
          {
            "id": 4,
            "title": "Pod Status Distribution",
            "type": "piechart",
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 6},
            "targets": [
              {
                "expr": "count by (phase) (kube_pod_status_phase)",
                "legendFormat": "{{phase}}",
                "refId": "A"
              }
            ],
            "options": {
              "pieType": "pie",
              "legend": {"displayMode": "visible", "placement": "right"}
            }
          },
          {
            "id": 5,
            "title": "CPU Usage by Node",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 6},
            "targets": [
              {
                "expr": "100 - (avg by(instance)(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
                "legendFormat": "CPU Usage - {{instance}}",
                "refId": "A"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "unit": "percent",
                "min": 0,
                "max": 100,
                "color": {"mode": "palette-classic"}
              }
            }
          },
          {
            "id": 6,
            "title": "Memory Usage by Node",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 24, "x": 0, "y": 14},
            "targets": [
              {
                "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
                "legendFormat": "Memory Usage - {{instance}}",
                "refId": "A"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "unit": "percent",
                "min": 0,
                "max": 100,
                "color": {"mode": "palette-classic"}
              }
            }
          }
        ],
        "templating": {
          "list": [
            {
              "name": "namespace",
              "type": "query",
              "query": "label_values(kube_namespace_created, namespace)",
              "refresh": 1,
              "includeAll": true,
              "multi": true
            }
          ]
        }
      }
    }
EOF

# Restart Grafana to load new dashboards
echo "🔄 Restarting Grafana to load dashboards..."
kubectl rollout restart deployment/prometheus-grafana -n demo-monitoring

# Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n demo-monitoring --timeout=300s

# Get service info
echo ""
echo "✅ Deployment completed!"
echo ""
echo "🎯 Access Grafana Dashboard:"
echo "   Click the '30000' port button above, or"
echo "   Use the IP address shown: http://$(hostname -i):30000"
echo ""
echo "👤 Login Credentials:"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "📊 Available Dashboards:"
echo "   • Demo - Multi-Cloud Kubernetes Overview (Custom)"
echo "   • Kubernetes / Compute Resources / Cluster"
echo "   • Kubernetes / Compute Resources / Node (Pods)"
echo "   • Node Exporter / Nodes"
echo ""

# Show running services
kubectl get svc -n demo-monitoring | grep grafana