#!/usr/bin/env bash
set -euo pipefail

namespace=opsproof-observability

helm uninstall k8s-monitoring --namespace "$namespace" --wait || true
helm uninstall tempo --namespace "$namespace" --wait || true
helm uninstall loki --namespace "$namespace" --wait || true
helm uninstall kube-prometheus --namespace "$namespace" --wait || true
kubectl delete namespace "$namespace" --ignore-not-found
