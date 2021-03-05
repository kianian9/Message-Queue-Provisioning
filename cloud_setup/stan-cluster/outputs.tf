# Gets the region
output "region" {
  value       = var.region
  description = "GCloud Region"
}

# Gets the zonal
output "zone" {
  value       = var.zone
  description = "GCloud Zonal"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "nr_worker_nodes" {
  value       = var.node_count
  description = "Worker Nodes"
}
