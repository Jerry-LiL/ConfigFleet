#!/usr/bin/env bash
# Create .vault_pass from CONFIGFLEET_VAULT_PASSWORD or .env when it is missing.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

if [[ -f .vault_pass ]]; then
  exit 0
fi

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

if [[ -z "${CONFIGFLEET_VAULT_PASSWORD:-}" ]]; then
  echo "Set CONFIGFLEET_VAULT_PASSWORD or create .vault_pass. See .env.example." >&2
  exit 1
fi

umask 077
printf '%s\n' "${CONFIGFLEET_VAULT_PASSWORD}" > .vault_pass
chmod 600 .vault_pass
