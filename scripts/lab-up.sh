#!/usr/bin/env bash
# Build the Ubuntu and CentOS lab and wait until SSH accepts the lab key.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"
"${ROOT}/scripts/ensure-vault-pass.sh"

mkdir -p "${ROOT}/.lab"
chmod 700 "${ROOT}/.lab"

if [[ ! -f "${ROOT}/.lab/id_ed25519" ]]; then
  ssh-keygen -t ed25519 -N "" -C "configfleet-lab" -f "${ROOT}/.lab/id_ed25519"
fi
chmod 600 "${ROOT}/.lab/id_ed25519"

pub="$(tr -d '\r\n' < "${ROOT}/.lab/id_ed25519.pub")"
cat > "${ROOT}/.lab/extra.yml" <<EOF
---
baseline_additional_ssh_keys:
  - "${pub}"
EOF

docker compose -f "${ROOT}/docker/docker-compose.yml" up --build -d --remove-orphans

wait_for_ssh() {
  local port="$1"
  local attempt
  for attempt in $(seq 1 90); do
    if ssh -i "${ROOT}/.lab/id_ed25519" \
      -o IdentitiesOnly=yes \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=3 \
      -p "${port}" \
      ansible@127.0.0.1 true; then
      return 0
    fi
    echo "Waiting for SSH on port ${port} (${attempt}/90)" >&2
    sleep 3
  done
  echo "SSH on port ${port} did not come up" >&2
  docker compose -f "${ROOT}/docker/docker-compose.yml" logs --no-color || true
  return 1
}

wait_for_ssh 2222
wait_for_ssh 2223

ssh-keyscan -p 2222 -T 5 127.0.0.1 > "${ROOT}/.lab/known_hosts"
ssh-keyscan -p 2223 -T 5 127.0.0.1 >> "${ROOT}/.lab/known_hosts"
echo "Lab is up. Ubuntu is on port 2222, CentOS is on port 2223."
