#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "${EMERGE_PERFORMANCE_LOCK_HELD:-0}" != "1" ]]; then
  exec flock -w "${EMERGE_PERFORMANCE_LOCK_TIMEOUT:-30}" /tmp/emerge-performance.lock \
    env EMERGE_PERFORMANCE_LOCK_HELD=1 "$0" "$@"
fi

routes=(
  "opengl opengl"
  "vulkan opengl"
  "opengl vulkan"
  "vulkan vulkan"
)

if (($# == 2)); then
  routes=("$1 $2")
elif (($# != 0)); then
  echo "usage: $0 [producer-api main-api]" >&2
  exit 2
fi

route_timeout="${EMERGE_DEMO_PRIME_ROUTE_TIMEOUT:-}"
if [[ -z "$route_timeout" ]]; then
  if (( ${EMERGE_DEMO_PRIME_SOAK_FRAMES:-72} >= 9000 )); then
    route_timeout=420s
  else
    route_timeout=120s
  fi
fi

for route in "${routes[@]}"; do
  read -r producer main <<<"$route"
  echo "== PRIME matrix: producer=$producer main=$main =="
  # Every route gets a fresh BEAM and native renderer lifetime.
  timeout "$route_timeout" \
    env MIX_ENV="${MIX_ENV:-test}" \
    mix run scripts/prime_matrix_route.exs -- "$producer" "$main"
done
