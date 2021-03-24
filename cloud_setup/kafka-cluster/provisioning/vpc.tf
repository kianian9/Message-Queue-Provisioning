variable "region" {
  description = "region"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Firewall
resource "google_compute_firewall" "default" {
  name     = "gke-firewall"
  network  = google_compute_network.vpc.name
  
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "9094", "30000-30001"]
  }

  target_tags = ["firewall"]
  source_ranges = ["0.0.0.0/0"] // Do not open to world, In Production.
}


# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}
