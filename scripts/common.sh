#!/usr/bin/env bash
# Paths shared by the operator scripts. Source this file; do not execute it.

if [[ -z "${ROOT:-}" ]]; then
  echo "ROOT is not set" >&2
  exit 1
fi

if [[ -x "${ROOT}/.venv/bin/ansible-playbook" ]]; then
  ANSIBLE_PLAYBOOK="${ROOT}/.venv/bin/ansible-playbook"
  ANSIBLE_LINT="${ROOT}/.venv/bin/ansible-lint"
  ANSIBLE_VAULT="${ROOT}/.venv/bin/ansible-vault"
  ANSIBLE_GALAXY="${ROOT}/.venv/bin/ansible-galaxy"
else
  ANSIBLE_PLAYBOOK="$(command -v ansible-playbook)"
  ANSIBLE_LINT="$(command -v ansible-lint)"
  ANSIBLE_VAULT="$(command -v ansible-vault)"
  ANSIBLE_GALAXY="$(command -v ansible-galaxy)"
fi

export ANSIBLE_PLAYBOOK ANSIBLE_LINT ANSIBLE_VAULT ANSIBLE_GALAXY
