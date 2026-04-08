output "control_plane_ips" {
  value       = local.cp_ips
  description = "Control plane node IPs"
}

output "worker_ips" {
  value       = local.worker_ips
  description = "Worker node IPs"
}

output "cluster_endpoint" {
  value       = "https://${local.cp_endpoint_ip}:6443"
  description = "Kubernetes API endpoint"
}

output "kubeconfig_path" {
  value       = local_file.kubeconfig.filename
  description = "Path to the generated kubeconfig"
}

output "talosconfig_path" {
  value       = local_file.talosconfig.filename
  description = "Path to the generated talosconfig"
}

output "talos_schematic_id" {
  value       = talos_image_factory_schematic.this.id
  description = "Talos Image Factory schematic ID (for USB boot media)"
}
