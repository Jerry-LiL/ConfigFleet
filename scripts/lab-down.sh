#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -f "${ROOT}/docker/docker-compose.yml" ]]; then
  exit 0
fi
docker rm -f configfleet-lab-ubuntu configfleet-lab-centos >/dev/null 2>&1 || true
if [[ -f "${ROOT}/.lab/id_ed25519.pub" ]]; then
  docker compose -f "${ROOT}/docker/docker-compose.yml" down --remove-orphans
else
  docker network rm configfleet-lab_default >/dev/null 2>&1 || true
fi
