#!/usr/bin/env bash
set -euo pipefail

cluster_name=opsproof
namespace=opsproof-traffic
lab_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ensure_cluster() {
  if ! kind get clusters | grep -Fxq "$cluster_name"; then
    echo "kind cluster '$cluster_name' is missing. Run 'make cluster-up' first." >&2
    exit 1
  fi
}

build() {
  ensure_cluster
  docker build -t opsproof/traffic-demo:v1 "$lab_dir/app"
  kind load docker-image opsproof/traffic-demo:v1 --name "$cluster_name"
}

deploy() {
  ensure_cluster
  kubectl apply -k "$lab_dir/k8s/base"
  # ConfigMap changes are read when Envoy starts, so recreate the sidecar
  # during an explicit lab deploy rather than pretending it hot-reloads.
  kubectl -n "$namespace" rollout restart deployment/order-api
  kubectl -n "$namespace" rollout status deployment/payment-api --timeout=2m
  kubectl -n "$namespace" rollout status deployment/order-api --timeout=2m
  sleep 1
}

incident() {
  kubectl apply -k "$lab_dir/k8s/overlays/incident"
  kubectl -n "$namespace" rollout status deployment/payment-api --timeout=2m
  sleep 1
}

recover() {
  kubectl apply -k "$lab_dir/k8s/base"
  kubectl -n "$namespace" rollout status deployment/payment-api --timeout=2m
  sleep 1
}

check() {
  run_job traffic-check
}

load() {
  run_job traffic-load
}

run_job() {
  local job="$1"
  kubectl -n "$namespace" delete "job/$job" --ignore-not-found
  kubectl apply -f "$lab_dir/k8s/jobs/${job#traffic-}.yaml"
  kubectl -n "$namespace" wait --for=condition=complete "job/$job" --timeout=90s
  kubectl -n "$namespace" logs "job/$job"
}

case "${1:-}" in
  build) build ;;
  deploy) deploy ;;
  incident) incident ;;
  recover) recover ;;
  check) check ;;
  load) load ;;
  status) kubectl -n "$namespace" get deployment,pods,svc,jobs ;;
  logs) kubectl -n "$namespace" logs deployment/order-api -c envoy --tail="${2:-80}" ;;
  stats) echo "Run: kubectl -n $namespace port-forward service/envoy-admin 19901:9901" ;;
  clean) kubectl delete namespace "$namespace" --ignore-not-found ;;
  *)
    echo "usage: $0 {build|deploy|incident|recover|check|load|status|logs|stats|clean}" >&2
    exit 2
    ;;
esac
