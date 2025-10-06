# Network Policies
resource "kubernetes_network_policy" "deny_all_ingress" {
  metadata {
    name      = "deny-all-ingress"
    namespace = "default"
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "allow_dns" {
  metadata {
    name      = "allow-dns"
    namespace = "default"
  }

  spec {
    pod_selector {}

    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }

      ports {
        protocol = "UDP"
        port     = "53"
      }

      ports {
        protocol = "TCP"
        port     = "53"
      }
    }
  }
}

# RBAC Configuration
resource "kubernetes_service_account" "monitoring" {
  metadata {
    name      = "monitoring-service-account"
    namespace = "monitoring"
  }
}

resource "kubernetes_cluster_role" "monitoring" {
  metadata {
    name = "monitoring-cluster-role"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "nodes/metrics", "services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "apps"]
    resources  = ["deployments", "replicasets", "daemonsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs            = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "monitoring" {
  metadata {
    name = "monitoring-cluster-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.monitoring.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.monitoring.metadata[0].name
    namespace = kubernetes_service_account.monitoring.metadata[0].namespace
  }
}

# Pod Security Standards
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    
    labels = {
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_namespace" "security" {
  metadata {
    name = "security"
    
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

# Security Context Constraints
resource "kubernetes_limit_range" "default" {
  metadata {
    name      = "default-limit-range"
    namespace = "default"
  }

  spec {
    limit {
      type = "Container"
      
      default = {
        cpu    = "100m"
        memory = "128Mi"
      }
      
      default_request = {
        cpu    = "50m"
        memory = "64Mi"
      }
      
      max = {
        cpu    = "1"
        memory = "1Gi"
      }
    }
  }
}

# Secrets management
resource "kubernetes_secret" "monitoring_credentials" {
  metadata {
    name      = "monitoring-credentials"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  type = "Opaque"

  data = {
    username = base64encode("admin")
    password = base64encode(random_password.grafana_admin.result)
  }
}

resource "random_password" "grafana_admin" {
  length  = 16
  special = true
}

# Image scanning policy (using OPA Gatekeeper)
resource "kubernetes_manifest" "image_scanning_policy" {
  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1beta1"
    kind       = "ConstraintTemplate"
    
    metadata = {
      name = "k8srequiredsecuritycontext"
    }
    
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sRequiredSecurityContext"
          }
          
          validation = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                runAsNonRoot = {
                  type = "boolean"
                }
                readOnlyRootFilesystem = {
                  type = "boolean"
                }
                allowPrivilegeEscalation = {
                  type = "boolean"
                }
              }
            }
          }
        }
      }
      
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego = <<-EOT
          package k8srequiredsecuritycontext

          violation[{"msg": msg}] {
            container := input.review.object.spec.containers[_]
            not container.securityContext.runAsNonRoot == true
            msg := "Container must run as non-root user"
          }

          violation[{"msg": msg}] {
            container := input.review.object.spec.containers[_]
            not container.securityContext.readOnlyRootFilesystem == true
            msg := "Container must have read-only root filesystem"
          }

          violation[{"msg": msg}] {
            container := input.review.object.spec.containers[_]
            container.securityContext.allowPrivilegeEscalation == true
            msg := "Container must not allow privilege escalation"
          }
        EOT
      }]
    }
  }
}