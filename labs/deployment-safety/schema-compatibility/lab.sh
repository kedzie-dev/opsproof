#!/usr/bin/env bash
set -euo pipefail

cluster_name=opsproof
namespace=opsproof
lab_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "$lab_dir/../../.." && pwd)"
k8s_dir="$lab_dir/k8s"

cluster_up() {
  if kind get clusters | grep -Fxq "$cluster_name"; then
    echo "kind cluster '$cluster_name' already exists"
    return
  fi
  kind create cluster --name "$cluster_name" --config "$lab_dir/kind-config.yaml" --wait 2m
}

cluster_down() {
  kind delete cluster --name "$cluster_name"
}

build_images() {
  docker build -f "$lab_dir/Dockerfile" -t opsproof/order-api:v1 "$root_dir"
  docker tag opsproof/order-api:v1 opsproof/order-api:unsafe-v2
  docker tag opsproof/order-api:v1 opsproof/order-api:safe-v2
  kind load docker-image \
    opsproof/order-api:v1 \
    opsproof/order-api:unsafe-v2 \
    opsproof/order-api:safe-v2 \
    --name "$cluster_name"
}

wait_for_postgres() {
  kubectl -n "$namespace" rollout status statefulset/postgres --timeout=2m
}

apply_baseline() {
  kubectl apply -k "$k8s_dir/overlays/v1"
  wait_for_postgres
  kubectl -n "$namespace" delete job/migration-v1 --ignore-not-found
  kubectl apply -f "$k8s_dir/jobs/migration-v1.yaml"
  kubectl -n "$namespace" wait --for=condition=complete job/migration-v1 --timeout=1m
  kubectl -n "$namespace" rollout status deployment/order-api --timeout=2m
  start_check
  check_result
}

start_check() {
  kubectl -n "$namespace" delete job/synthetic-check --ignore-not-found
  kubectl apply -f "$k8s_dir/jobs/synthetic-check.yaml"
}

check_result() {
  local deadline=$((SECONDS + 90))
  while (( SECONDS < deadline )); do
    if [[ "$(kubectl -n "$namespace" get job/synthetic-check -o jsonpath='{.status.succeeded}' 2>/dev/null)" == "1" ]]; then
      kubectl -n "$namespace" logs job/synthetic-check
      return 0
    fi
    if [[ "$(kubectl -n "$namespace" get job/synthetic-check -o jsonpath='{.status.failed}' 2>/dev/null)" == "1" ]]; then
      kubectl -n "$namespace" logs job/synthetic-check
      return 1
    fi
    sleep 1
  done
  kubectl -n "$namespace" logs job/synthetic-check || true
  echo "synthetic check did not reach a terminal state within 90 seconds" >&2
  return 2
}

unsafe_transition() {
  kubectl apply -f "$k8s_dir/jobs/migration-unsafe-rename.yaml"
  kubectl -n "$namespace" wait --for=condition=complete job/migration-unsafe-rename --timeout=1m
  start_check
  kubectl apply -k "$k8s_dir/overlays/unsafe-v2"
  kubectl -n "$namespace" rollout status deployment/order-api --timeout=2m
  if check_result; then
    echo "unexpected: unsafe transition satisfied the deployment contract" >&2
    return 1
  fi
  echo "expected: the check failed. Image-only rollback cannot restore v1 after the destructive rename." >&2
}

safe_transition() {
  kubectl apply -f "$k8s_dir/jobs/migration-safe-expand.yaml"
  kubectl -n "$namespace" wait --for=condition=complete job/migration-safe-expand --timeout=1m
  start_check
  kubectl apply -k "$k8s_dir/overlays/safe-v2"
  kubectl -n "$namespace" rollout status deployment/order-api --timeout=2m
  check_result
}

rollback() {
  kubectl -n "$namespace" rollout undo deployment/order-api
  kubectl -n "$namespace" rollout status deployment/order-api --timeout=2m
  echo "Use rollback only after the compatibility transition; an unsafe rename also requires schema restoration." >&2
}

case "${1:-}" in
  cluster-up) cluster_up ;;
  cluster-down) cluster_down ;;
  build-images) build_images ;;
  baseline) apply_baseline ;;
  unsafe-transition) unsafe_transition ;;
  safe-transition) safe_transition ;;
  rollback) rollback ;;
  *)
    echo "usage: $0 {cluster-up|cluster-down|build-images|baseline|unsafe-transition|safe-transition|rollback}" >&2
    exit 2
    ;;
esac
