variable "node_count" {
  default = "3"
}

variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

resource "google_service_account" "default" {
  account_id   = "kianian9"
  display_name = "Service Account"
}

variable "zone" {
  description = "zone"
}

# Kubernetes version
data "google_container_engine_versions" "north1" {
  project        = var.project_id
  provider       = google-beta
  location       = var.zone
  version_prefix = "1.18."
}


# GKE cluster
resource "google_container_cluster" "primary" {
  name                     = "${var.project_id}-gke"
  location                 = var.zone
  node_version             = data.google_container_engine_versions.north1.latest_node_version
  min_master_version       = data.google_container_engine_versions.north1.latest_node_version
  remove_default_node_pool = true
  initial_node_count       = 1
  logging_service          = "none"
  monitoring_service       = "none"

  network                  = google_compute_network.vpc.name
  subnetwork               = google_compute_subnetwork.subnet.name

  master_auth {
    username = var.gke_username
    password = var.gke_password

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    service_account = google_service_account.default.email
    preemptible  = true
    machine_type = "e2-medium"

    disk_size_gb       = 10
    disk_type          = "pd-standard"
    image_type         = "ubuntu"
    tags = [
      "firewall"
    ]
  }
}

