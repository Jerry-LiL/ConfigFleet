#!/usr/bin/env bash
# Lint, syntax-check, boot the lab, and prove a second apply changes nothing.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

on_err() {
  echo "Test failed." >&2
  if [[ -f "${ROOT}/docker/docker-compose.yml" ]]; then
    docker compose -f "${ROOT}/docker/docker-compose.yml" logs --no-color || true
  fi
}

cleanup() {
  if [[ "${KEEP_LAB:-}" != "1" ]]; then
    "${ROOT}/scripts/lab-down.sh" || true
  fi
}

trap on_err ERR
trap cleanup EXIT

if [[ ! -x "${ROOT}/.venv/bin/ansible-lint" ]]; then
  python3 -m venv "${ROOT}/.venv"
  "${ROOT}/.venv/bin/pip" install -r "${ROOT}/requirements-dev.txt"
fi

if [[ ! -f "${ROOT}/.env" && ! -f "${ROOT}/.vault_pass" ]]; then
  cp "${ROOT}/.env.example" "${ROOT}/.env"
fi
"${ROOT}/scripts/ensure-vault-pass.sh"
"${ROOT}/.venv/bin/ansible-galaxy" collection install -r "${ROOT}/requirements.yml" -p "${ROOT}/collections"

shellcheck -x \
  "${ROOT}/scripts/"*.sh \
  "${ROOT}/docker/entrypoint.sh" \
  "${ROOT}/roles/systemd_services/files/configfleet-heartbeat"

heartbeat_dir="$(mktemp -d)"
if CONFIGFLEET_STATE_DIR="${heartbeat_dir}" \
  CONFIGFLEET_API_TOKEN="" \
  CONFIGFLEET_ENV=dev \
  bash "${ROOT}/roles/systemd_services/files/configfleet-heartbeat"; then
  echo "heartbeat script should fail when the token is empty" >&2
  exit 1
fi
CONFIGFLEET_STATE_DIR="${heartbeat_dir}" \
  CONFIGFLEET_API_TOKEN="sample-token" \
  CONFIGFLEET_ENV=dev \
  bash "${ROOT}/roles/systemd_services/files/configfleet-heartbeat"
python3 - "${heartbeat_dir}/heartbeat.json" <<'PY'
import json
import sys
path = sys.argv[1]
raw = open(path, encoding="utf-8").read()
data = json.loads(raw)
assert data["environment"] == "dev", data
assert "sample-token" not in raw
assert len(data["token_fingerprint"]) == 12
PY
rm -rf "${heartbeat_dir}"

"${ROOT}/scripts/node-bootstrap.sh" --help >/dev/null
status=0
"${ROOT}/scripts/node-bootstrap.sh" >/dev/null 2>&1 || status=$?
if [[ "${status}" -ne 2 ]]; then
  echo "node-bootstrap.sh should exit 2 without arguments, got ${status}" >&2
  exit 1
fi

"${ROOT}/scripts/lint.sh"
"${ROOT}/scripts/syntax-check.sh"

dev_vault="$("${ROOT}/.venv/bin/ansible-vault" view "${ROOT}/inventories/dev/group_vars/all/vault.yml")"
prod_vault="$("${ROOT}/.venv/bin/ansible-vault" view "${ROOT}/inventories/prod/group_vars/all/vault.yml")"
grep -q "vault_api_token: dev-sample-api-token" <<<"${dev_vault}"
grep -q "vault_api_token: prod-sample-api-token" <<<"${prod_vault}"
grep -q "vault_breakglass_password_hash:" <<<"${prod_vault}"

"${ROOT}/scripts/lab-up.sh"

bootstrap_checksum() {
  local container="$1"
  docker exec "${container}" sha256sum \
    "/etc/sudoers.d/configfleet-ansible" \
    "/home/ansible/.ssh/authorized_keys"
}

before_ubuntu="$(bootstrap_checksum configfleet-lab-ubuntu)"
docker exec configfleet-lab-ubuntu \
  /usr/local/sbin/node-bootstrap.sh --user ansible --pubkey-file /bootstrap/id_ed25519.pub
after_ubuntu="$(bootstrap_checksum configfleet-lab-ubuntu)"
if [[ "${before_ubuntu}" != "${after_ubuntu}" ]]; then
  echo "Ubuntu bootstrap was not idempotent" >&2
  echo "${before_ubuntu}" >&2
  echo "${after_ubuntu}" >&2
  exit 1
fi

before_centos="$(bootstrap_checksum configfleet-lab-centos)"
docker exec configfleet-lab-centos \
  /usr/local/sbin/node-bootstrap.sh --user ansible --pubkey-file /bootstrap/id_ed25519.pub
after_centos="$(bootstrap_checksum configfleet-lab-centos)"
if [[ "${before_centos}" != "${after_centos}" ]]; then
  echo "CentOS bootstrap was not idempotent" >&2
  echo "${before_centos}" >&2
  echo "${after_centos}" >&2
  exit 1
fi

mkdir -p "${ROOT}/.lab"
"${ROOT}/scripts/provision.sh" --inventory inventories/dev
"${ROOT}/scripts/provision.sh" --inventory inventories/dev | tee "${ROOT}/.lab/second.log"
python3 "${ROOT}/tests/assert_stable.py" "${ROOT}/.lab/second.log"

"${ROOT}/scripts/dry-run.sh" --inventory inventories/dev | tee "${ROOT}/.lab/dry.log"
python3 "${ROOT}/tests/assert_stable.py" "${ROOT}/.lab/dry.log"

"${ROOT}/scripts/provision.sh" --inventory inventories/dev --playbook tests/verify.yml
echo "All checks passed."
