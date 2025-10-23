# Prometheus Helm Chart
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "62.3.1"  # Updated to current stable version

  create_namespace = true

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          retention                               = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "20Gi"
                  }
                }
              }
            }
          }
          resources = {
            requests = {
              memory = "1Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "2Gi"
              cpu    = "1000m"
            }
          }
        }
      }
      
      grafana = {
        adminPassword = var.grafana_admin_password
        
        persistence = {
          enabled          = true
          storageClassName = "gp3"
          size             = "10Gi"
        }
        
        service = {
          type = "LoadBalancer"
        }
        
        resources = {
          requests = {
            memory = "256Mi"
            cpu    = "250m"
          }
          limits = {
            memory = "512Mi"
            cpu    = "500m"
          }
        }
        
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [{
              name            = "default"
              orgId           = 1
              folder          = ""
              type            = "file"
              disableDeletion = false
              editable        = true
              options = {
                path = "/var/lib/grafana/dashboards/default"
              }
            }]
          }
        }
        
        dashboards = {
          default = {
            cluster-overview = {
              gnetId     = 7249
              revision   = 1
              datasource = "Prometheus"
            }
            node-exporter = {
              gnetId     = 1860
              revision   = 31
              datasource = "Prometheus"
            }
            kubernetes-cluster = {
              gnetId     = 6417
              revision   = 1
              datasource = "Prometheus"
            }
          }
        }
      }
      
      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "5Gi"
                  }
                }
              }
            }
          }
          resources = {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }
        }
      }
      
      nodeExporter = {
        enabled = true
      }
      
      kubeStateMetrics = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_storage_class.gp3]
}

# Custom storage class for better performance
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

# Custom ServiceMonitor for daemon metrics
resource "kubernetes_manifest" "daemon_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    
    metadata = {
      name      = "daemon-metrics"
      namespace = "monitoring"
      
      labels = {
        app = "daemon-metrics"
      }
    }
    
    spec = {
      selector = {
        matchLabels = {
          app = "logging-daemon"
        }
      }
      
      endpoints = [{
        port     = "metrics"
        interval = "30s"
        path     = "/metrics"
      }]
      
      namespaceSelector = {
        matchNames = ["kube-system"]
      }
    }
  }

  depends_on = [helm_release.prometheus]
}

# PrometheusRule for custom alerts
resource "kubernetes_manifest" "custom_alerts" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    
    metadata = {
      name      = "custom-alerts"
      namespace = "monitoring"
      
      labels = {
        app        = "kube-prometheus-stack"
        prometheus = "kube-prometheus-stack-prometheus"
      }
    }
    
    spec = {
      groups = [{
        name = "custom.rules"
        
        rules = [
          {
            alert = "HighCPUUsage"
            expr  = "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 80"
            for   = "5m"
            
            labels = {
              severity = "warning"
            }
            
            annotations = {
              summary     = "High CPU usage detected"
              description = "CPU usage is above 80% for more than 5 minutes on {{ $labels.instance }}"
            }
          },
          
          {
            alert = "HighMemoryUsage"
            expr  = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85"
            for   = "5m"
            
            labels = {
              severity = "warning"
            }
            
            annotations = {
              summary     = "High memory usage detected"
              description = "Memory usage is above 85% for more than 5 minutes on {{ $labels.instance }}"
            }
          },
          
          {
            alert = "DaemonPodNotRunning"
            expr  = "kube_daemonset_status_desired_number_scheduled - kube_daemonset_status_number_ready > 0"
            for   = "5m"
            
            labels = {
              severity = "critical"
            }
            
            annotations = {
              summary     = "DaemonSet pod not running"
              description = "DaemonSet {{ $labels.daemonset }} in namespace {{ $labels.namespace }} has pods not ready"
            }
          }
        ]
      }]
    }
  }

  depends_on = [helm_release.prometheus]
}