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

  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }

  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }

  set {
    name  = "k8sServiceHost"
    value = local.cp_endpoint_ip
  }

  set {
    name  = "k8sServicePort"
    value = "6443"
  }

  # Hubble observability
  set {
    name  = "hubble.enabled"
    value = "true"
  }

  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }

  set {
    name  = "hubble.ui.enabled"
    value = "true"
  }

  # L2 announcements (replaces MetalLB)
  set {
    name  = "l2announcements.enabled"
    value = "true"
  }

  set {
    name  = "externalIPs.enabled"
    value = "true"
  }

  # Single-node: only 1 operator replica
  set {
    name  = "operator.replicas"
    value = "1"
  }

  # Talos-specific: cgroup settings
  set {
    name  = "cgroup.autoMount.enabled"
    value = "false"
  }

  set {
    name  = "cgroup.hostRoot"
    value = "/sys/fs/cgroup"
  }

  # Gateway API (replaces traditional Ingress controllers)
  set {
    name  = "gatewayAPI.enabled"
    value = "true"
  }

  # Talos-specific: security context capabilities
  set {
    name  = "securityContext.capabilities.ciliumAgent"
    value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  }

  set {
    name  = "securityContext.capabilities.cleanCiliumState"
    value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  }
}
