#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"
# shellcheck disable=SC1091
source "${ROOT}/scripts/common.sh"
"${ROOT}/scripts/ensure-vault-pass.sh"

for env_name in dev staging prod; do
  echo "Syntax check inventories/${env_name}"
  "${ANSIBLE_PLAYBOOK}" playbooks/site.yml -i "inventories/${env_name}" --syntax-check
done
