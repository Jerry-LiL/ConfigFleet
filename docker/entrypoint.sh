#!/bin/bash
# Create the Ansible user, then hand off to systemd.
set -euo pipefail

if [[ -f /bootstrap/id_ed25519.pub ]]; then
  /usr/local/sbin/node-bootstrap.sh --user ansible --pubkey-file /bootstrap/id_ed25519.pub
fi

if [[ -x /lib/systemd/systemd ]]; then
  exec /lib/systemd/systemd
fi
exec /usr/lib/systemd/systemd
