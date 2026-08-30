#!/usr/bin/env bash
set -euo pipefail

cluster_ui_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
namespace=opsproof-cluster-ui

if helm version --short | grep -q '^v4'; then
  failure_cleanup=(--rollback-on-failure)
else
  failure_cleanup=(--atomic)
fi

helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
helm repo update headlamp

kubectl get namespace "$namespace" >/dev/null 2>&1 || kubectl create namespace "$namespace"
kubectl apply --namespace "$namespace" --filename "$cluster_ui_dir/headlamp-local-user.yaml"

helm upgrade --install headlamp headlamp/headlamp \
  --namespace "$namespace" \
  --version 0.44.0 \
  --values "$cluster_ui_dir/values/headlamp.yaml" \
  "${failure_cleanup[@]}" \
  --wait --timeout 5m

echo "Headlamp: make headlamp (default http://localhost:3302)"
echo "Login token: make headlamp-token"
