# home-ops-px

GitOps repository for the homelab Kubernetes cluster. Managed by Flux CD.

## Structure

```
clusters/home-ops-px/       Flux entry point (Kustomization CRs)
infrastructure/
  crds/                     CRDs that must exist before controllers install
  controllers/              HelmReleases for cluster tooling (cert-manager, ingress, etc.)
  configs/                  Cluster-wide configs (ClusterIssuer, etc.)
apps/                       Application workloads
```

## Dependency Chain

```
infra-crds -> infra-controllers -> infra-configs -> apps
```

Each layer waits for the previous one to be healthy before deploying.
Enforced via Flux Kustomization `dependsOn`.

## Adding Infrastructure

1. Add the HelmRepository/HelmRelease to the appropriate `infrastructure/` layer
2. Reference it in that layer's `kustomization.yaml`
3. Push to `main`

## Adding Apps

1. Create a directory under `apps/` with your manifests
2. Add it to `apps/kustomization.yaml`
3. Push to `main`
