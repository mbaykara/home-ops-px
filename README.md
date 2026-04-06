# Homelab

Talos Linux Kubernetes cluster on Proxmox VE, fully managed with Terraform and Flux CD.

## Stack

- **Proxmox VE** -- hypervisor
- **Talos Linux** -- immutable Kubernetes OS
- **Terraform** -- provisions VMs, bootstraps cluster, installs Flux
- **Flux CD** -- GitOps continuous delivery from [home-ops-px](https://github.com/mbaykara/home-ops-px)

## Usage

### Via GitHub Actions

Trigger the `Bootstrap Talos Cluster` workflow with `create-cluster` or `destroy-cluster`.

### Locally

```sh
cd terraform
cp terraform.tfvars.example terraform.tfvars  # fill in values
terraform init
terraform plan
terraform apply
```

Kubeconfig and talosconfig are saved to `terraform/generated/`.

## Required GitHub Secrets

| Secret | Description |
|---|---|
| `TF_VAR_PROXMOX_ENDPOINT` | Proxmox API URL |
| `TF_VAR_PROXMOX_USERNAME` | Proxmox username |
| `TF_VAR_PROXMOX_PASSWORD` | Proxmox password |
| `PA_TOKEN` | GitHub PAT for Flux git access |

## Node Configuration

Defined in `terraform.tfvars`:

```hcl
control_plane_nodes = {
  "talos-cp-01" = { vm_id = 800, cores = 2, memory = 4096, disk_size = 20 }
}

worker_nodes = {
  "talos-worker-01" = { vm_id = 801, cores = 2, memory = 4096, disk_size = 20 }
}
```

Add entries to scale up.
