variable "machine_type" {
  type = string
}

variable "project_id" {
  type = string
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_compute_image" "ubuntu_image" {
  family  = "ubuntu-1804-lts"
  project = "ubuntu-os-cloud"
}

resource "google_service_account" "default" {
  account_id   = "kianian9-client"
  display_name = "Service Account"
  project      = var.project_id
}

resource "google_compute_address" "static" {
  name           = "ipv4-address"
  project        = var.project_id
  region         = var.region
}


resource "google_compute_instance" "default" {
  name         = "${var.project_id}-gce-client"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["firewall"]

  boot_disk {
    initialize_params {
      image  = data.google_compute_image.ubuntu_image.self_link
      size   = 10
      type   = "pd-standard"
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.ssh_pub_key_path)}"
  }  


  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }


  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }


  #############################################################################
  # This is the 'local exec' method.  
  # Ansible runs from the same host you run Terraform from
  #############################################################################

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.ssh_username
      private_key = file(var.ssh_prv_key_path)
      host        = google_compute_instance.default.network_interface[0].access_config.0.nat_ip
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook -i '${google_compute_instance.default.network_interface[0].access_config.0.nat_ip},' --private-key ${var.ssh_prv_key_path} ./client.yaml"
  }

  depends_on = [google_compute_firewall.default]
}



resource "google_compute_firewall" "default" {
  name     = "gce-client-firewall"
  network  = "default"
  project  = var.project_id
  
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8080"]
  }

  target_tags = ["firewall"]
  source_ranges = ["0.0.0.0/0"] // Do not open to world, In Production.
}