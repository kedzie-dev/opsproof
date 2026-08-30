.DEFAULT_GOAL := help

.PHONY: help test cluster-up cluster-down build-images baseline unsafe-transition safe-transition rollback observability-up observability-down observability-status grafana cluster-ui-up cluster-ui-down cluster-ui-status headlamp headlamp-token

LAB_DIR := labs/deployment-safety/schema-compatibility
OBSERVABILITY_NAMESPACE := opsproof-observability
CLUSTER_UI_NAMESPACE := opsproof-cluster-ui

help:
	@$(MAKE) -C $(LAB_DIR) help
	@echo "Shared targets: observability-up observability-down observability-status grafana cluster-ui-up cluster-ui-down cluster-ui-status headlamp headlamp-token"

test:
	@$(MAKE) -C $(LAB_DIR) test

cluster-up cluster-down build-images baseline unsafe-transition safe-transition rollback:
	@$(MAKE) -C $(LAB_DIR) $@

observability-up:
	@./observability/install.sh

observability-down:
	@./observability/uninstall.sh

observability-status:
	@kubectl -n $(OBSERVABILITY_NAMESPACE) get pods,svc,pvc

grafana:
	@kubectl -n $(OBSERVABILITY_NAMESPACE) port-forward service/kube-prometheus-grafana "$${GRAFANA_PORT:-3301}":80

cluster-ui-up:
	@./cluster-ui/install.sh

cluster-ui-down:
	@./cluster-ui/uninstall.sh

cluster-ui-status:
	@kubectl -n $(CLUSTER_UI_NAMESPACE) get deployment,pods,svc

headlamp:
	@kubectl -n $(CLUSTER_UI_NAMESPACE) port-forward service/headlamp "$${HEADLAMP_PORT:-3302}":80

headlamp-token:
	@kubectl -n $(CLUSTER_UI_NAMESPACE) create token headlamp-local-user --duration="$${HEADLAMP_TOKEN_TTL:-1h}"
