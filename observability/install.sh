#!/usr/bin/env bash
set -euo pipefail

observability_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
namespace=opsproof-observability

if helm version --short | grep -q '^v4'; then
  failure_cleanup=(--rollback-on-failure)
else
  failure_cleanup=(--atomic)
fi

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo update prometheus-community grafana grafana-community

kubectl get namespace "$namespace" >/dev/null 2>&1 || kubectl create namespace "$namespace"

helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace "$namespace" \
  --version 88.3.0 \
  --values "$observability_dir/values/kube-prometheus-stack.yaml" \
  "${failure_cleanup[@]}" \
  --wait --timeout 5m

helm upgrade --install loki grafana-community/loki \
  --namespace "$namespace" \
  --version 18.9.1 \
  --values "$observability_dir/values/loki.yaml" \
  "${failure_cleanup[@]}" \
  --wait --timeout 5m

helm upgrade --install tempo grafana-community/tempo \
  --namespace "$namespace" \
  --version 2.2.4 \
  --values "$observability_dir/values/tempo.yaml" \
  "${failure_cleanup[@]}" \
  --wait --timeout 5m

helm upgrade --install k8s-monitoring grafana/k8s-monitoring \
  --namespace "$namespace" \
  --version 4.4.0 \
  --values "$observability_dir/values/k8s-monitoring.yaml" \
  "${failure_cleanup[@]}" \
  --wait --timeout 5m

kubectl apply -k "$observability_dir/dashboards"

echo "Grafana: make grafana (default http://localhost:3301)"
