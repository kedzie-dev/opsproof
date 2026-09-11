.DEFAULT_GOAL := help
.PHONY: help cluster-up build deploy incident recover check load status logs stats clean

ROOT_DIR := $(abspath ../../..)

help:
	@echo "Targets: cluster-up build deploy incident recover check load status logs stats clean"

cluster-up:
	@$(MAKE) -C $(ROOT_DIR) cluster-up

build deploy incident recover check load status logs stats clean:
	@./lab.sh $@
