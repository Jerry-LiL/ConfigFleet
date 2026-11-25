#!/usr/bin/env bash
# --check --diff against an inventory. This is the Jenkins dry-run stage.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "${ROOT}/scripts/provision.sh" --check "$@"
