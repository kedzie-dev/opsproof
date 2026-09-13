#!/usr/bin/env bash
set -euo pipefail

cluster_name=opsproof
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kind_config="$script_dir/../kind/opsproof.yaml"

cluster_up() {
  if kind get clusters | grep -Fxq "$cluster_name"; then
    echo "kind cluster '$cluster_name' already exists"
    return
  fi

  kind create cluster --name "$cluster_name" --config "$kind_config" --wait 2m
}

cluster_down() {
  kind delete cluster --name "$cluster_name"
}

case "${1:-}" in
  cluster-up) cluster_up ;;
  cluster-down) cluster_down ;;
  *)
    echo "usage: $0 {cluster-up|cluster-down}" >&2
    exit 2
    ;;
esac
