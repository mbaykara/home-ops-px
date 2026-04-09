resource "talos_machine_secrets" "this" {}

# --- Talos Image Factory (bare-metal extensions) ---

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = [
          "siderolabs/intel-ucode",
          "siderolabs/iscsi-tools",
          "siderolabs/i915-ucode",
          "siderolabs/mei",
        ]
      }
    }
  })
}

# --- Control Plane Machine Configuration ---

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.cp_endpoint_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk  = var.install_disk
          image = "factory.talos.dev/installer/${talos_image_factory_schematic.this.id}:${var.talos_version}"
        }
        kubelet = {
          extraArgs = {
            rotate-server-certificates = "true"
            node-labels                = "node.kubernetes.io/instance-type=m720q"
          }
        }
        network = {
          interfaces = [
            {
              interface = var.network_interface
              addresses = ["${local.cp_endpoint_ip}/24"]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = var.network_gateway
                }
              ]
            }
          ]
          nameservers = [var.network_gateway, "8.8.8.8"]
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = true
        network = {
          cni = {
            name = "none"
          }
        }
        proxy = {
          disabled = true
        }
        extraManifests = [
          "https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml",
          "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml",
        ]
      }
    })
  ]
}

# --- Worker Machine Configuration (for future use) ---

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${local.cp_endpoint_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk  = var.install_disk
          image = "factory.talos.dev/installer/${talos_image_factory_schematic.this.id}:${var.talos_version}"
        }
      }
    })
  ]
}

# --- Client Configuration ---

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = values(local.cp_ips)
}

# --- Apply Configs ---

resource "talos_machine_configuration_apply" "controlplane" {
  for_each                    = local.cp_ips
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value
}

resource "talos_machine_configuration_apply" "worker" {
  for_each                    = local.worker_ips
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value
}

# --- Bootstrap ---

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker,
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cp_endpoint_ip
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cp_endpoint_ip
}

# --- Save Configs Locally ---

resource "local_file" "kubeconfig" {
  depends_on      = [talos_cluster_kubeconfig.this]
  content         = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename        = "${path.module}/generated/kubeconfig"
  file_permission = "0600"
}

resource "local_file" "talosconfig" {
  depends_on      = [talos_machine_bootstrap.this]
  content         = data.talos_client_configuration.this.talos_config
  filename        = "${path.module}/generated/talosconfig"
  file_permission = "0600"
}
