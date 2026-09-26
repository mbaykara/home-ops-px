# Continue Here

## Last Session: 2026-09-26
- Re-enabled grafana-k8s-monitoring HelmRelease, chart bumped 4.0.1 -> 4.2.1
- Removed otel-operator (no Instrumentation/Collector CRs depended on it; Flux prunes it)
- Local fix: terraform/generated/kubeconfig had a stale Azure `monitoring` context as
  current-context; removed it and set `admin@home-ops`. talosconfig endpoint set to
  192.168.178.171. Context `admin@home-ops` also merged into ~/.kube/config.

- k8s-monitoring kept disabled (reverted the re-enable, HelmRelease pruned)
- Added Renovate (.github/renovate.json5). Terraform versions (Talos, Cilium, Flux operator,
  Flux distribution) tracked via `# renovate:` annotations in terraform/variables.tf; those
  PRs get the `terraform-apply` label and need a manual apply after merge.
- Flux pinned: operator chart 0.46.0, distribution v2.8.5 (was unpinned / `2.x`)
- Renovate app installed; first batch of PRs merged 2026-09-26

## Session: 2026-09-27
- Migrated Terraform to helm provider v3 syntax (`set = [...]`, `kubernetes = {}`)
- talosconfig endpoint now set in Terraform (talos_client_configuration.endpoints)
- terraform apply done: Flux operator 0.60.0, Flux v2.9.5, kubelet node label m720q
- Etcd snapshot before apply: _out/etcd-snapshots/etcd-snapshot-20260927-001127.db
- NOT upgraded: terraform.tfvars (local, gitignored) pins talos_version=v1.12.1 and
  cilium_version=1.17.2, overriding the Renovate-bumped defaults. Running: Talos v1.12.1,
  Cilium 1.17.2. Cilium needs one-minor-at-a-time (1.18 -> 1.19 -> 1.20); Talos needs
  `talosctl upgrade` (1.12.12 -> 1.13.10), changing the var alone does not upgrade the node.
- Open: PR #17 (terraform providers, talos provider 0.12)

## Session: 2026-04-08

### What was done
- Migrated from Proxmox VM to bare-metal Talos Linux on ThinkCentre M720q
- Cluster is running on bare metal at 192.168.178.171

### Architecture
- **OS**: Talos Linux v1.12.1 (bare metal, single control plane node)
- **CNI**: Cilium 1.17.2 (kube-proxy replacement, Hubble, Gateway API, L2 announcements)
- **GitOps**: Flux CD v2.x syncing from https://github.com/mbaykara/home-ops-px
- **Storage**: local-path-provisioner v0.0.35 (path: /var/local-path-provisioner)
- **TLS**: cert-manager v1.17.1 with self-signed ClusterIssuer
- **Ingress**: Cilium Gateway API (no separate ingress controller)
- **Secrets**: SOPS with age encryption, Flux decryption
- **Load Balancer IPs**: 192.168.178.200-220 via Cilium L2 announcements

### Talos extensions (required for M720q)
- siderolabs/intel-ucode
- siderolabs/i915-ucode
- siderolabs/iscsi-tools
- siderolabs/mei (required for Intel I219-LM NIC on vPro platform)

### Key commands
```
export KUBECONFIG=./terraform/generated/kubeconfig
export TALOSCONFIG=./terraform/generated/talosconfig

make sops-secret     # Create SOPS decryption key in cluster
make reconcile       # Trigger Flux sync
make etcd-snapshot   # Backup etcd

kubectl get nodes
flux get kustomizations
talosctl -n 192.168.178.171 health
```

### Lessons learned
1. ThinkCentre M720q needs `siderolabs/mei` extension for NIC detection
2. Static network config required in Talos machine config (DHCP IP != cluster endpoint)
3. Cilium must depend on kubeconfig, NOT health check (health check deadlocks without CNI)
