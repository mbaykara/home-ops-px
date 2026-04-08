# --- Flux Operator (installs the CRDs and operator) ---

resource "helm_release" "flux_operator" {
  depends_on = [helm_release.cilium]

  name             = "flux-operator"
  namespace        = "flux-system"
  create_namespace = true
  chart            = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator"

  wait          = true
  wait_for_jobs = true
  timeout       = 300
}

# --- FluxInstance CR (triggers Flux to sync the GitOps repo) ---

resource "kubectl_manifest" "flux_instance" {
  depends_on = [
    helm_release.flux_operator,
    kubectl_manifest.flux_git_secret,
  ]

  yaml_body = yamlencode({
    apiVersion = "fluxcd.controlplane.io/v1"
    kind       = "FluxInstance"
    metadata = {
      name      = "flux"
      namespace = "flux-system"
    }
    spec = {
      distribution = {
        version  = "2.x"
        registry = "ghcr.io/fluxcd"
      }
      components = [
        "source-controller",
        "kustomize-controller",
        "helm-controller",
        "notification-controller",
        "image-reflector-controller",
        "image-automation-controller",
      ]
      sync = merge(
        {
          kind     = "GitRepository"
          provider = "generic"
          url      = var.flux_github_repo
          ref      = "refs/heads/main"
          path     = var.flux_path
        },
        var.github_token != "" ? { pullSecret = "flux-system" } : {}
      )
    }
  })
}

# --- Git credentials (only created when github_token is set) ---

resource "kubectl_manifest" "flux_git_secret" {
  depends_on = [helm_release.flux_operator]
  count      = var.github_token != "" ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "flux-system"
      namespace = "flux-system"
    }
    type = "Opaque"
    stringData = {
      username = "git"
      password = var.github_token
    }
  })
}
