KUBECONFIG := ./terraform/generated/kubeconfig
KUBECTL    := KUBECONFIG=$(KUBECONFIG) kubectl
TALOSCTL   := TALOSCONFIG=./terraform/generated/talosconfig talosctl

.PHONY: help sops-secret reconcile etcd-snapshot

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

sops-secret: ## Create the SOPS age decryption secret for Flux
	$(KUBECTL) create secret generic sops-age \
		--namespace=flux-system \
		--from-file=age.agekey=$(HOME)/.config/sops/age/keys.txt \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -

reconcile: ## Trigger Flux reconciliation
	KUBECONFIG=$(KUBECONFIG) flux reconcile source git flux-system
	KUBECONFIG=$(KUBECONFIG) flux reconcile kustomization infra-crds
	KUBECONFIG=$(KUBECONFIG) flux reconcile kustomization infra-controllers
	KUBECONFIG=$(KUBECONFIG) flux reconcile kustomization infra-configs
	KUBECONFIG=$(KUBECONFIG) flux reconcile kustomization apps

etcd-snapshot: ## Take an etcd snapshot for backup
	@mkdir -p _out/etcd-snapshots
	$(TALOSCTL) -n 192.168.178.171 etcd snapshot _out/etcd-snapshots/etcd-snapshot-$$(date +%Y%m%d-%H%M%S).db
	@echo "Snapshot saved to _out/etcd-snapshots/"
	@ls -la _out/etcd-snapshots/ | tail -5
