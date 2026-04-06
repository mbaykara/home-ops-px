KUBECONFIG ?= terraform/generated/kubeconfig
KUBECTL    := KUBECONFIG=$(KUBECONFIG) kubectl

.PHONY: help setup secrets namespaces all

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

all: namespaces secrets ## Apply namespaces and secrets

namespaces: ## Create namespaces with PodSecurity labels
	$(KUBECTL) apply -f infrastructure/controllers/monitoring/namespace.yaml
	$(KUBECTL) apply -f apps/postgres/namespace.yaml

secrets: namespaces ## Apply all secrets (requires namespaces first)
	$(KUBECTL) apply -f infrastructure/controllers/monitoring/secret.yaml
	$(KUBECTL) apply -f infrastructure/controllers/monitoring/db-o11y-secret.yaml
	$(KUBECTL) apply -f apps/postgres/secret.yaml

reconcile: ## Trigger Flux reconciliation
	KUBECONFIG=$(KUBECONFIG) flux reconcile source git flux-system
	KUBECONFIG=$(KUBECONFIG) flux reconcile kustomization infra-crds
	KUBECONFIG=$(KUBECONFIG) flux reconcile kustomization infra-controllers
	KUBECONFIG=$(KUBECONFIG) flux reconcile kustomization infra-configs
	KUBECONFIG=$(KUBECONFIG) flux reconcile kustomization apps
