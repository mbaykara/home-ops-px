terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.100.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
  }
}

# --- Providers ---

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
}

provider "talos" {}

provider "helm" {
  kubernetes {
    host                   = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
    client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  }
}

provider "kubectl" {
  host                   = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
  client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  load_config_file       = false
}

# --- Talos ISO ---

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = [
          "siderolabs/qemu-guest-agent",
          "siderolabs/intel-ucode",
        ]
      }
    }
  })
}

resource "proxmox_download_file" "talos_iso" {
  content_type        = "iso"
  datastore_id        = var.proxmox_datastore_id
  node_name           = var.proxmox_node_name
  overwrite_unmanaged = true
  url                 = "https://factory.talos.dev/image/${talos_image_factory_schematic.this.id}/${var.talos_version}/metal-amd64.iso"
  file_name           = "talos-${talos_image_factory_schematic.this.id}.iso"
}

# --- Control Plane VMs ---

resource "proxmox_virtual_environment_vm" "control_plane" {
  for_each  = var.control_plane_nodes
  name      = each.key
  node_name = var.proxmox_node_name
  vm_id     = each.value.vm_id

  agent { enabled = true }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory { dedicated = each.value.memory }

  disk {
    datastore_id = var.proxmox_disk_datastore_id
    file_format  = "raw"
    interface    = "virtio0"
    size         = each.value.disk_size
  }

  cdrom {
    file_id = proxmox_download_file.talos_iso.id
  }

  network_device {
    bridge = var.proxmox_network_bridge
  }

  started = true
}

# --- Worker VMs ---

resource "proxmox_virtual_environment_vm" "worker" {
  for_each  = var.worker_nodes
  name      = each.key
  node_name = var.proxmox_node_name
  vm_id     = each.value.vm_id

  agent { enabled = true }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory { dedicated = each.value.memory }

  disk {
    datastore_id = var.proxmox_disk_datastore_id
    file_format  = "raw"
    interface    = "virtio0"
    size         = each.value.disk_size
  }

  cdrom {
    file_id = proxmox_download_file.talos_iso.id
  }

  network_device {
    bridge = var.proxmox_network_bridge
  }

  started = true
}

# --- IP Extraction ---

locals {
  cp_ips = {
    for name, vm in proxmox_virtual_environment_vm.control_plane : name => try([
      for ips in vm.ipv4_addresses :
      [for ip in ips : ip if ip != "127.0.0.1"][0]
      if length([for ip in ips : ip if ip != "127.0.0.1"]) > 0
    ][0], "0.0.0.0")
  }

  worker_ips = {
    for name, vm in proxmox_virtual_environment_vm.worker : name => try([
      for ips in vm.ipv4_addresses :
      [for ip in ips : ip if ip != "127.0.0.1"][0]
      if length([for ip in ips : ip if ip != "127.0.0.1"]) > 0
    ][0], "0.0.0.0")
  }

  cp_endpoint_ip = values(local.cp_ips)[0]
}
