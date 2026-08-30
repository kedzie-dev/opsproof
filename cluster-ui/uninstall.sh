#!/usr/bin/env bash
set -euo pipefail

cluster_ui_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
namespace=opsproof-cluster-ui

helm uninstall headlamp --namespace "$namespace" --wait || true
kubectl delete --namespace "$namespace" --filename "$cluster_ui_dir/headlamp-local-user.yaml" --ignore-not-found
kubectl delete namespace "$namespace" --ignore-not-found
