terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.91.0" 
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.10.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
}


provider "talos" {}


resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = [
            "siderolabs/qemu-guest-agent",
            "siderolabs/intel-ucode"
          ]
        }
      }
    }
  )
}

resource "proxmox_virtual_environment_download_file" "talos_iso" {
  content_type = var.proxmox_content_type
  datastore_id = var.proxmox_datastore_id
  node_name    = var.proxmox_node_name

  url = "https://factory.talos.dev/image/${talos_image_factory_schematic.this.id}/v1.12.1/metal-amd64.iso"
  
  # Accessing the "schematic_id" key from the JSON
  file_name = "talos-${talos_image_factory_schematic.this.id}.iso"
}

# 3. Create the VM using that ISO
resource "proxmox_virtual_environment_vm" "talos_cp" {
  name      = var.proxmox_vm_name
  node_name = "pve"
  vm_id     = 800

  agent {
    enabled = true # Requires qemu-guest-agent extension in the ISO
  }

  cpu {
    cores = var.proxmox_cpu_cores
    type  = var.proxmox_cpu_type
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    file_format  = var.proxmox_disk_file_format
    interface    = var.proxmox_disk_interface
    size         = var.proxmox_disk_size
  }

  cdrom {
    file_id = proxmox_virtual_environment_download_file.talos_iso.id
  }

  network_device {
    bridge = var.proxmox_network_bridge
  }
  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  name      = "talos-worker-01"
  node_name = "pve"
  vm_id     = 801

  agent { enabled = true }
  cpu {
    cores = 2
    type  = "host"
  }
  memory { dedicated = 4096 }
  
  disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    interface    = "virtio0"
    size         = 20
  }
  
  cdrom {
    file_id = proxmox_virtual_environment_download_file.talos_iso.id
  }
  
  network_device {
    bridge = "vmbr0"
  }

  started = true
}

locals {
  # Logic to extract the first non-loopback IP for Control Plane
  cp_ip = [
    for ips in proxmox_virtual_environment_vm.talos_cp.ipv4_addresses :
    [for ip in ips : ip if ip != "127.0.0.1"][0]
    if length([for ip in ips : ip if ip != "127.0.0.1"]) > 0
  ][0]

  # Logic to extract the first non-loopback IP for Worker
  worker_ip = [
    for ips in proxmox_virtual_environment_vm.talos_worker.ipv4_addresses :
    [for ip in ips : ip if ip != "127.0.0.1"][0]
    if length([for ip in ips : ip if ip != "127.0.0.1"]) > 0
  ][0]
}
resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = "talos-proxmox-cluster"
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.cp_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = "talos-proxmox-cluster"
  machine_type     = "worker"
  cluster_endpoint = "https://${local.cp_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_client_configuration" "this" {
  cluster_name         = "talos-proxmox-cluster"
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [local.cp_ip]
}

# --- Apply Config to Control Plane ---
resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = local.cp_ip
}

# --- Apply Config to Worker ---
resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = local.worker_ip
}

# --- Bootstrap Cluster (CP Only) ---
resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.controlplane]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cp_ip
}

# --- Download Kubeconfig ---
resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cp_ip
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "control_plane_ip" {
  value = local.cp_ip
}

output "worker_ip" {
  value = local.worker_ip
}