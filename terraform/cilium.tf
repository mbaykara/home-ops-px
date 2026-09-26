# --- Cilium CNI (deployed after bootstrap, before Flux) ---
# Cilium replaces kube-proxy and provides L2 announcements for LoadBalancer IPs.
# Must be deployed via Terraform (not Flux) because Flux pods need a CNI to start.

resource "helm_release" "cilium" {
  depends_on = [talos_cluster_kubeconfig.this]

  name             = "cilium"
  namespace        = "kube-system"
  repository       = "https://helm.cilium.io/"
  chart            = "cilium"
  version          = var.cilium_version
  create_namespace = false

  wait          = true
  wait_for_jobs = true
  timeout       = 600

  set = [
    {
      name  = "ipam.mode"
      value = "kubernetes"
    },

    {
      name  = "kubeProxyReplacement"
      value = "true"
    },

    {
      name  = "k8sServiceHost"
      value = local.cp_endpoint_ip
    },

    {
      name  = "k8sServicePort"
      value = "6443"
    },

    # Hubble observability
    {
      name  = "hubble.enabled"
      value = "true"
    },

    {
      name  = "hubble.relay.enabled"
      value = "true"
    },

    {
      name  = "hubble.ui.enabled"
      value = "true"
    },

    # L2 announcements (replaces MetalLB)
    {
      name  = "l2announcements.enabled"
      value = "true"
    },

    {
      name  = "externalIPs.enabled"
      value = "true"
    },

    # Single-node: only 1 operator replica
    {
      name  = "operator.replicas"
      value = "1"
    },

    # Talos-specific: cgroup settings
    {
      name  = "cgroup.autoMount.enabled"
      value = "false"
    },

    {
      name  = "cgroup.hostRoot"
      value = "/sys/fs/cgroup"
    },

    # Gateway API (replaces traditional Ingress controllers)
    {
      name  = "gatewayAPI.enabled"
      value = "true"
    },

    # Talos-specific: security context capabilities
    {
      name  = "securityContext.capabilities.ciliumAgent"
      value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
    },

    {
      name  = "securityContext.capabilities.cleanCiliumState"
      value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
    },
  ]
}
