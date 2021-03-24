# Gets the zonal
output "zone" {
  value       = var.zone
  description = "GCloud Zonal"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "instance_name" {
  value       = google_compute_instance.default.name
  description = "GCE Instance Name"
}

output "client_host_ip" {
  value       = google_compute_instance.default.network_interface[0].access_config.0.nat_ip
  description = "GCE Host IP"
}

output "machine_type" {
  value       = var.machine_type
  description = "Machine Type"
}