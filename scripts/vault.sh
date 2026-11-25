#!/usr/bin/env bash
# View or edit a vault file with .vault_pass.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"
# shellcheck disable=SC1091
source "${ROOT}/scripts/common.sh"
"${ROOT}/scripts/ensure-vault-pass.sh"

action="${1:-}"
file="${2:-}"

if [[ "${action}" != "view" && "${action}" != "edit" ]]; then
  echo "Usage: scripts/vault.sh view|edit inventories/<env>/group_vars/all/vault.yml" >&2
  exit 2
fi
if [[ -z "${file}" ]]; then
  echo "Usage: scripts/vault.sh view|edit inventories/<env>/group_vars/all/vault.yml" >&2
  exit 2
fi

exec "${ANSIBLE_VAULT}" "${action}" "${file}"
