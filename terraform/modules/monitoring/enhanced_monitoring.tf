# Enhanced Monitoring Stack with Full Observability
# Includes: Prometheus, Grafana, Jaeger (tracing), Loki (logs), AlertManager

# Prometheus + Grafana (existing, enhanced)
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "62.3.1"

  create_namespace = true

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          retention                               = "30d"
          retentionSize                          = "15GB"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class
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
              memory = "2Gi"
              cpu    = "1000m"
            }
            limits = {
              memory = "4Gi"
              cpu    = "2000m"
            }
          }
          # Enhanced scraping configs
          additionalScrapeConfigs = [
            {
              job_name = "jaeger-tracing"
              static_configs = [
                {
                  targets = ["jaeger-collector.observability:14269"]
                }
              ]
            }
          ]
        }
      }
      
      grafana = {
        adminPassword = var.grafana_admin_password
        
        persistence = {
          enabled          = true
          storageClassName = var.storage_class
          size             = "10Gi"
        }

        resources = {
          requests = {
            memory = "256Mi"
            cpu    = "100m"
          }
          limits = {
            memory = "512Mi"
            cpu    = "500m"
          }
        }

        # Enhanced Grafana configuration
        grafana.ini = {
          server = {
            root_url = "%(protocol)s://%(domain)s:%(http_port)s/grafana"
          }
          security = {
            allow_embedding = true
          }
          "auth.anonymous" = {
            enabled = true
            org_role = "Viewer"
          }
          feature_toggles = {
            enable = "tracing"
          }
        }

        # Pre-configured dashboards
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name = "custom"
                orgId = 1
                folder = "Custom Dashboards"
                type = "file"
                disableDeletion = false
                editable = true
                options = {
                  path = "/var/lib/grafana/dashboards/custom"
                }
              }
            ]
          }
        }

        dashboards = {
          custom = {
            # Multi-cloud cluster overview
            "multicloud-overview" = {
              gnetId = 7249
              revision = 1
              datasource = "Prometheus"
            }
            # Kubernetes cluster monitoring
            "k8s-cluster-rsrc-use" = {
              gnetId = 13332
              revision = 12
              datasource = "Prometheus"  
            }
            # Jaeger tracing dashboard
            "jaeger-tracing" = {
              gnetId = 10001
              revision = 1
              datasource = "Jaeger"
            }
          }
        }

        # Data source configurations
        datasources = {
          "datasources.yaml" = {
            apiVersion = 1
            datasources = [
              {
                name = "Prometheus"
                type = "prometheus"
                url = "http://prometheus-kube-prometheus-prometheus:9090"
                isDefault = true
              }
              {
                name = "Jaeger"
                type = "jaeger"
                url = "http://jaeger-query.observability:16686"
              }
              {
                name = "Loki"
                type = "loki"
                url = "http://loki-gateway.observability"
              }
            ]
          }
        }
      }
      
      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "5Gi"
                  }
                }
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.observability]
}

# Jaeger for distributed tracing
resource "helm_release" "jaeger" {
  name       = "jaeger"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  namespace  = "observability"
  version    = "3.0.0"

  create_namespace = true

  values = [
    yamlencode({
      provisionDataStore = {
        cassandra = false
        elasticsearch = true
      }
      
      storage = {
        type = "elasticsearch"
        elasticsearch = {
          host = "elasticsearch-master.observability"
          port = 9200
        }
      }

      agent = {
        enabled = true
        daemonset = {
          enabled = true
        }
      }

      collector = {
        enabled = true
        service = {
          type = "ClusterIP"
        }
        resources = {
          requests = {
            memory = "256Mi"
            cpu    = "100m"
          }
          limits = {
            memory = "512Mi"
            cpu    = "500m"
          }
        }
      }

      query = {
        enabled = true
        service = {
          type = "ClusterIP"
        }
        resources = {
          requests = {
            memory = "256Mi"
            cpu    = "100m"
          }
          limits = {
            memory = "512Mi"
            cpu    = "500m"
          }
        }
      }
    })
  ]

  depends_on = [helm_release.elasticsearch]
}

# Loki for log aggregation
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = "observability"
  version    = "6.6.2"

  values = [
    yamlencode({
      deploymentMode = "SimpleScalable"
      
      loki = {
        auth_enabled = false
        commonConfig = {
          replication_factor = 1
        }
        storage = {
          type = "filesystem"
        }
        schemaConfig = {
          configs = [
            {
              from = "2024-01-01"
              store = "tsdb"
              object_store = "filesystem"
              schema = "v13"
              index = {
                prefix = "index_"
                period = "24h"
              }
            }
          ]
        }
      }

      write = {
        replicas = 1
        persistence = {
          enabled = true
          storageClass = var.storage_class
          size = "10Gi"
        }
      }

      read = {
        replicas = 1
      }

      backend = {
        replicas = 1
        persistence = {
          enabled = true
          storageClass = var.storage_class
          size = "10Gi"
        }
      }

      gateway = {
        enabled = true
        replicas = 1
      }

      monitoring = {
        serviceMonitor = {
          enabled = true
        }
        selfMonitoring = {
          enabled = false
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.observability]
}

# Promtail for log collection (Loki agent)
resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  namespace  = "observability"
  version    = "6.16.4"

  values = [
    yamlencode({
      config = {
        clients = [
          {
            url = "http://loki-gateway.observability/loki/api/v1/push"
          }
        ]
      }

      daemonset = {
        enabled = true
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
    })
  ]

  depends_on = [helm_release.loki]
}

# Elasticsearch for Jaeger backend
resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  namespace  = "observability"
  version    = "8.5.1"

  values = [
    yamlencode({
      replicas = 1
      minimumMasterNodes = 1

      esConfig = {
        "elasticsearch.yml" = "cluster.name: jaeger\n"
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
      }

      volumeClaimTemplate = {
        accessModes = ["ReadWriteOnce"]
        storageClassName = var.storage_class
        resources = {
          requests = {
            storage = "10Gi"
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.observability]
}

# Observability namespace
resource "kubernetes_namespace" "observability" {
  metadata {
    name = "observability"
    labels = {
      name = "observability"
      "istio-injection" = "enabled"
    }
  }
}

# OpenTelemetry Operator for enhanced tracing
resource "helm_release" "opentelemetry_operator" {
  name       = "opentelemetry-operator"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-operator"
  namespace  = "observability"
  version    = "0.63.1"

  depends_on = [kubernetes_namespace.observability]
}

# Service monitors for custom metrics
resource "kubernetes_manifest" "custom_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "multi-cloud-metrics"
      namespace = "monitoring"
      labels = {
        app = "multi-cloud-monitoring"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "multi-cloud-exporter"
        }
      }
      endpoints = [
        {
          port = "metrics"
          path = "/metrics"
          interval = "30s"
        }
      ]
    }
  }

  depends_on = [helm_release.prometheus]
}