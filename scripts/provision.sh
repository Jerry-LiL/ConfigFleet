#!/usr/bin/env bash
# Apply playbooks/site.yml. Pass --check for a --check --diff dry run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"
# shellcheck disable=SC1091
source "${ROOT}/scripts/common.sh"
"${ROOT}/scripts/ensure-vault-pass.sh"

inventory="inventories/dev"
playbook="playbooks/site.yml"
check_mode=0
extra=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --inventory)
      inventory="$2"
      shift 2
      ;;
    --playbook)
      playbook="$2"
      shift 2
      ;;
    --check)
      check_mode=1
      shift
      ;;
    *)
      extra+=("$1")
      shift
      ;;
  esac
done

if [[ "${inventory}" == *"/dev"* || "${inventory}" == "dev" ]]; then
  if [[ ! -f "${ROOT}/.lab/id_ed25519" || ! -f "${ROOT}/.lab/known_hosts" ]]; then
    echo "The dev inventory targets the local lab. Run scripts/lab-up.sh first." >&2
    exit 1
  fi
  export CONFIGFLEET_SSH_KEY="${ROOT}/.lab/id_ed25519"
  export CONFIGFLEET_KNOWN_HOSTS="${ROOT}/.lab/known_hosts"
  if [[ -f "${ROOT}/.lab/extra.yml" ]]; then
    extra+=("-e" "@${ROOT}/.lab/extra.yml")
  fi
fi

args=(-i "${inventory}" "${playbook}")
if [[ "${check_mode}" -eq 1 ]]; then
  args+=(--check --diff)
fi

echo "ansible-playbook ${args[*]}"
"${ANSIBLE_PLAYBOOK}" "${args[@]}" "${extra[@]}"
