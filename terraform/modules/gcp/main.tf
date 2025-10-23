# GCP GKE Cluster Module
# Creates GKE cluster with proper networking and security

# Enable required APIs
resource "google_project_service" "container_api" {
  service = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460

  depends_on = [google_project_service.compute_api]
}

# Subnet for GKE cluster
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.name

  # Secondary ranges for pods and services
  secondary_ip_range {
    range_name    = "gke-${var.cluster_name}-pods"
    ip_cidr_range = var.pod_cidr
  }

  secondary_ip_range {
    range_name    = "gke-${var.cluster_name}-services"
    ip_cidr_range = var.service_cidr
  }

  depends_on = [google_project_service.compute_api]
}

# Cloud Router
resource "google_compute_router" "router" {
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # Network configuration
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Networking configuration
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.subnet.secondary_ip_range[1].range_name
  }

  # Security configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_cidr
  }

  # Master authorized networks
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable network policy
  network_policy {
    enabled = true
  }

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }

    gcp_filestore_csi_driver_config {
      enabled = true
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Monitoring and logging
  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "APISERVER",
      "CONTROLLER_MANAGER",
      "SCHEDULER"
    ]
  }

  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "APISERVER",
      "CONTROLLER_MANAGER",
      "SCHEDULER"
    ]
  }

  # Maintenance policy
  maintenance_policy {
    recurring_window {
      start_time = var.maintenance_start_time
      end_time   = var.maintenance_end_time
      recurrence = var.maintenance_recurrence
    }
  }

  # Resource labels
  resource_labels = {
    environment = var.environment
    project     = var.cluster_name
    managed-by  = "terraform"
  }

  depends_on = [
    google_project_service.container_api,
    google_compute_subnetwork.subnet
  ]
}

# Node pools
resource "google_container_node_pool" "primary_nodes" {
  for_each = var.node_pools

  name       = each.key
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = each.value.node_count

  # Auto scaling
  autoscaling {
    min_node_count = each.value.min_nodes
    max_node_count = each.value.max_nodes
  }

  # Management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Node configuration
  node_config {
    preemptible  = each.value.preemptible
    machine_type = each.value.machine_type

    # Google recommends custom service accounts with minimal permissions
    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]

    labels = {
      environment = var.environment
      node-pool   = each.key
    }

    # Disk configuration
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Security configuration
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    tags = ["gke-node", "${var.cluster_name}-gke"]
  }

  depends_on = [google_container_cluster.primary]
}

# Service Account for GKE nodes
resource "google_service_account" "gke_service_account" {
  account_id   = "${var.cluster_name}-gke-sa"
  display_name = "GKE Service Account for ${var.cluster_name}"
  description  = "Service account for GKE cluster ${var.cluster_name}"
}

# IAM binding for GKE service account
resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter", 
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Firewall rule for internal cluster communication
resource "google_compute_firewall" "gke_internal" {
  name    = "${var.cluster_name}-gke-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr, var.pod_cidr]
  target_tags   = ["gke-node"]
}