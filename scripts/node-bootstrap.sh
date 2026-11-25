#!/usr/bin/env bash
# Prepare a fresh Ubuntu or CentOS host so Ansible can log in.
# Safe to run more than once.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: node-bootstrap.sh --user NAME --pubkey-file PATH [--group NAME]

Create the Ansible login user, install Python 3 and sudo, and grant
passwordless sudo. Run as root.
EOF
}

user_name=""
pubkey_file=""
admin_group=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      user_name="$2"
      shift 2
      ;;
    --pubkey-file)
      pubkey_file="$2"
      shift 2
      ;;
    --group)
      admin_group="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${user_name}" || -z "${pubkey_file}" ]]; then
  usage >&2
  exit 2
fi
if [[ ! -f "${pubkey_file}" ]]; then
  echo "Public key file not found: ${pubkey_file}" >&2
  exit 1
fi
if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run node-bootstrap.sh as root." >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot read /etc/os-release" >&2
  exit 1
fi
# shellcheck disable=SC1091
. /etc/os-release

os_like="${ID_LIKE:-} ${ID:-}"
case "${os_like}" in
  *debian* | *ubuntu*)
    family="debian"
    admin_group="${admin_group:-sudo}"
    ;;
  *rhel* | *fedora* | *centos*)
    family="redhat"
    admin_group="${admin_group:-wheel}"
    ;;
  *)
    echo "Unsupported distribution: ${ID:-unknown}" >&2
    exit 1
    ;;
esac

if ! command -v python3 >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1; then
  case "${family}" in
    debian)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      apt-get install -y python3 sudo ca-certificates
      ;;
    redhat)
      if command -v dnf >/dev/null 2>&1; then
        dnf install -y python3 sudo ca-certificates
      else
        yum install -y python3 sudo ca-certificates
      fi
      ;;
    *)
      echo "Unsupported family: ${family}" >&2
      exit 1
      ;;
  esac
fi

if ! getent group "${admin_group}" >/dev/null 2>&1; then
  groupadd "${admin_group}"
fi

if ! id "${user_name}" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash --groups "${admin_group}" "${user_name}"
else
  usermod --append --groups "${admin_group}" "${user_name}"
fi

home_dir="$(getent passwd "${user_name}" | cut -d: -f6)"
install -d -m 0700 -o "${user_name}" -g "${user_name}" "${home_dir}/.ssh"
key="$(tr -d '\r\n' < "${pubkey_file}")"
auth_file="${home_dir}/.ssh/authorized_keys"
touch "${auth_file}"
chmod 0600 "${auth_file}"
chown "${user_name}:${user_name}" "${auth_file}"
if ! grep -qxF "${key}" "${auth_file}"; then
  printf '%s\n' "${key}" >> "${auth_file}"
fi

sudoers="/etc/sudoers.d/configfleet-${user_name}"
tmp="$(mktemp)"
printf '%s\n' "${user_name} ALL=(ALL) NOPASSWD:ALL" "Defaults:${user_name} !requiretty" > "${tmp}"
chmod 0440 "${tmp}"
visudo -cf "${tmp}" >/dev/null
mv "${tmp}" "${sudoers}"
chmod 0440 "${sudoers}"

echo "Bootstrap complete for ${user_name} on ${ID:-unknown} (${family})."
