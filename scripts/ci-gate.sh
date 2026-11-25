#!/usr/bin/env bash
# Run the same three checks the Jenkinsfile runs, against one inventory.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
inventory="${1:-inventories/dev}"

"${ROOT}/scripts/lint.sh"
"${ROOT}/scripts/syntax-check.sh"
"${ROOT}/scripts/dry-run.sh" --inventory "${inventory}"
