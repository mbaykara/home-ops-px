# --- Proxmox Connection ---

variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox VE API endpoint URL"
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox VE API username"
}

variable "proxmox_password" {
  type        = string
  sensitive   = true
  description = "Proxmox VE API password"
}

variable "proxmox_insecure" {
  type        = bool
  default     = false
  description = "Allow insecure TLS connections to Proxmox"
}

# --- Proxmox Infrastructure ---

variable "proxmox_node_name" {
  type        = string
  default     = "pve"
  description = "Proxmox node to deploy VMs on"
}

variable "proxmox_datastore_id" {
  type        = string
  default     = "local"
  description = "Datastore for ISO images"
}

variable "proxmox_disk_datastore_id" {
  type        = string
  default     = "local-lvm"
  description = "Datastore for VM disks"
}

variable "proxmox_network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Network bridge for VMs"
}

# --- Cluster ---

variable "cluster_name" {
  type        = string
  default     = "talos-proxmox-cluster"
  description = "Name of the Talos cluster"
}

variable "talos_version" {
  type        = string
  default     = "v1.12.1"
  description = "Talos Linux version"
}

variable "control_plane_nodes" {
  type = map(object({
    vm_id     = number
    cores     = number
    memory    = number
    disk_size = number
  }))
  description = "Control plane node definitions"
}

variable "worker_nodes" {
  type = map(object({
    vm_id     = number
    cores     = number
    memory    = number
    disk_size = number
  }))
  description = "Worker node definitions"
}

# --- Flux CD ---

variable "github_token" {
  type        = string
  sensitive   = true
  default     = ""
  description = "GitHub PAT for Flux to access the GitOps repo (leave empty for public repos)"
}

variable "flux_github_repo" {
  type        = string
  description = "GitHub repository URL for Flux GitOps sync"
}

variable "flux_path" {
  type        = string
  default     = "clusters/home-ops-px"
  description = "Path within the repo for Flux to sync"
}
