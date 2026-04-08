# --- Cluster ---

variable "cluster_name" {
  type        = string
  default     = "home-ops"
  description = "Name of the Talos cluster"
}

variable "talos_version" {
  type        = string
  default     = "v1.12.1"
  description = "Talos Linux version"
}

variable "cluster_endpoint_ip" {
  type        = string
  description = "IP address for the Kubernetes API endpoint"
}

variable "install_disk" {
  type        = string
  default     = "/dev/sda"
  description = "Disk device path for Talos installation"
}

# --- Nodes ---

variable "control_plane_nodes" {
  type = map(object({
    ip = string
  }))
  description = "Control plane node definitions (name -> IP)"
}

variable "worker_nodes" {
  type = map(object({
    ip = string
  }))
  default     = {}
  description = "Worker node definitions (name -> IP)"
}

# --- Network ---

variable "network_interface" {
  type        = string
  default     = "eno1"
  description = "Primary network interface name on bare-metal nodes"
}

variable "network_gateway" {
  type        = string
  default     = "192.168.178.1"
  description = "Default gateway IP"
}

# --- Cilium ---

variable "cilium_version" {
  type        = string
  default     = "1.17.2"
  description = "Cilium Helm chart version"
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
