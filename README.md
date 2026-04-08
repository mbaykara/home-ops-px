# home-ops-px

Bare-metal Kubernetes cluster running Talos Linux on a Lenovo ThinkCentre M720q. Managed by Flux CD.

## Stack

| Component | Tool | Notes |
|---|---|---|
| OS | Talos Linux v1.12.1 | Immutable, API-driven |
| CNI | Cilium | kube-proxy replacement, Hubble, Gateway API, L2 announcements |
| GitOps | Flux CD v2.x | Syncs from this repo |
| Storage | local-path-provisioner | Path: `/var/local-path-provisioner` |
| TLS | cert-manager | Self-signed ClusterIssuer |
| Ingress | Cilium Gateway API | No separate ingress controller |
| Load Balancer | Cilium L2 | IP pool: 192.168.178.200-220 |
| Secrets | SOPS + age | Encrypted in git, decrypted by Flux |
| Provisioning | Terraform | Talos bootstrap, Cilium, Flux |

## Structure

```
clusters/home-ops-px/          Flux entry point (Kustomization CRs)
infrastructure/
  crds/                        Gateway API, cert-manager CRDs
  controllers/                 Cluster tooling (see below)
  configs/                     Cilium L2 pool, ClusterIssuer
apps/                          Application workloads
terraform/                     Bare-metal provisioning (Talos, Cilium, Flux)
```

### Infrastructure Controllers

- **local-path-provisioner** -- Default StorageClass (Retain policy)
- **cloudnative-pg** -- PostgreSQL operator
- **monitoring** -- Grafana k8s-monitoring (Alloy, Prometheus, Loki, OTLP)
- **cert-manager** -- TLS certificate management
- **otel-operator** -- OpenTelemetry Operator for collectors and auto-instrumentation

### Applications

- **postgres** -- CloudNative PG cluster (single instance, 10Gi)

## Dependency Chain

```
infra-crds -> infra-controllers -> infra-configs -> apps
```

Each layer waits for the previous one to be healthy before deploying.
Enforced via Flux Kustomization `dependsOn`.

## Quick Start

### Prerequisites

- `terraform`, `talosctl`, `kubectl`, `flux`, `sops`, `age`
- SOPS age key at `~/.config/sops/age/keys.txt`

### Deploy

```sh
cd terraform
terraform init
terraform apply       # Bootstraps Talos, Cilium, Flux
cd ..
make sops-secret      # Create SOPS decryption key in cluster
make reconcile        # Trigger Flux sync
```

### Day-2 Operations

```sh
make reconcile        # Force Flux sync
make etcd-snapshot    # Backup etcd
make sops-secret      # Rotate SOPS key in cluster
```

### Encrypting Secrets

```sh
sops --encrypt --in-place path/to/secret.yaml
```

