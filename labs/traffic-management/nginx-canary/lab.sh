#!/usr/bin/env bash
set -euo pipefail

lab_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
compose=(docker compose -f "$lab_dir/compose.yaml")

activate() {
  local config="$1"
  mkdir -p "$lab_dir/runtime"
  cp "$lab_dir/nginx/$config.conf" "$lab_dir/runtime/default.conf"
  "${compose[@]}" exec -T nginx nginx -t
  "${compose[@]}" exec -T nginx nginx -s reload
  # nginx drains old workers after a graceful reload. Keep the next request
  # sample outside that handoff window so the rollback result is unambiguous.
  sleep 1
  echo "nginx now uses $config.conf"
}

case "${1:-}" in
  up)
    mkdir -p "$lab_dir/runtime"
    cp "$lab_dir/nginx/baseline.conf" "$lab_dir/runtime/default.conf"
    "${compose[@]}" up --build --wait
    echo "baseline is listening on http://localhost:${NGINX_LAB_PORT:-18080}/orders/42"
    ;;
  canary) activate canary ;;
  rollback) activate baseline ;;
  requests)
    for _ in $(seq 1 "${2:-30}"); do
      curl -sS -o /dev/null -w '%{http_code}\n' "http://localhost:${NGINX_LAB_PORT:-18080}/orders/42" || true
    done | sort | uniq -c
    ;;
  logs) "${compose[@]}" logs --tail="${2:-80}" nginx order-v1 order-v2 ;;
  down) "${compose[@]}" down --volumes --remove-orphans ;;
  *)
    echo "usage: $0 {up|canary|rollback|requests [count]|logs [lines]|down}" >&2
    exit 2
    ;;
esac
