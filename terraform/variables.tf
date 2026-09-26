# --- Cluster ---

variable "cluster_name" {
  type        = string
  default     = "home-ops"
  description = "Name of the Talos cluster"
}

# renovate: datasource=github-releases depName=siderolabs/talos
variable "talos_version" {
  type        = string
  default     = "v1.13.10"
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

# renovate: datasource=helm depName=cilium registryUrl=https://helm.cilium.io/
variable "cilium_version" {
  type        = string
  default     = "1.17.18"
  description = "Cilium Helm chart version"
}

# --- Flux CD ---

# renovate: datasource=docker depName=ghcr.io/controlplaneio-fluxcd/charts/flux-operator
variable "flux_operator_version" {
  type        = string
  default     = "0.60.0"
  description = "Flux Operator Helm chart version"
}

# renovate: datasource=github-releases depName=fluxcd/flux2
variable "flux_version" {
  type        = string
  default     = "v2.9.5"
  description = "Flux distribution version managed by the FluxInstance"
}

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
