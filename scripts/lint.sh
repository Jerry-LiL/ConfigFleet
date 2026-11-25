#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"
# shellcheck disable=SC1091
source "${ROOT}/scripts/common.sh"
"${ROOT}/scripts/ensure-vault-pass.sh"
export ANSIBLE_VAULT_PASSWORD_FILE="${ROOT}/.vault_pass"

if [[ -z "${ANSIBLE_LINT}" ]]; then
  echo "ansible-lint is not installed. See requirements-dev.txt." >&2
  exit 1
fi

exec "${ANSIBLE_LINT}"
