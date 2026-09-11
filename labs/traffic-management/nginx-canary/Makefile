.DEFAULT_GOAL := help
.PHONY: help up canary rollback requests logs down

help:
	@echo "Targets: up canary rollback requests logs down"

up canary rollback logs down:
	@./lab.sh $@

requests:
	@./lab.sh requests $${COUNT:-30}
