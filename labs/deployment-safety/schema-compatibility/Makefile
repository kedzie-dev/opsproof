.DEFAULT_GOAL := help

ROOT_DIR := $(abspath ../../..)
PYTHON := $(ROOT_DIR)/.venv/bin/python

.PHONY: help test cluster-up cluster-down build-images baseline unsafe-transition safe-transition rollback observability-up observability-down observability-status grafana cluster-ui-up cluster-ui-down cluster-ui-status headlamp headlamp-token

help:
	@echo "Targets: test cluster-up cluster-down build-images baseline unsafe-transition safe-transition rollback observability-up observability-down observability-status grafana cluster-ui-up cluster-ui-down cluster-ui-status headlamp headlamp-token"

test:
	$(PYTHON) -m pytest $(ROOT_DIR)/tests

cluster-up cluster-down build-images baseline unsafe-transition safe-transition rollback:
	./lab.sh $@

observability-up observability-down observability-status grafana cluster-ui-up cluster-ui-down cluster-ui-status headlamp headlamp-token:
	@$(MAKE) -C $(ROOT_DIR) $@
