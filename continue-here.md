# Continue Here

## Last Session: 2026-04-08

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
