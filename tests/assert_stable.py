#!/usr/bin/env python3
"""Fail if an Ansible recap reports changes, failures, or unreachable hosts."""

import re
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: assert_stable.py RECAP_LOG", file=sys.stderr)
        return 2
    text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
    rows = re.findall(
        r"^(\S+)\s+:\s+ok=\d+\s+changed=(\d+)\s+unreachable=(\d+)\s+failed=(\d+)",
        text,
        re.MULTILINE,
    )
    if len(rows) < 2:
        print(f"expected a recap for both lab hosts, found {rows!r}", file=sys.stderr)
        return 1
    bad = [row for row in rows if row[1] != "0" or row[2] != "0" or row[3] != "0"]
    if bad:
        print(f"playbook was not stable: {bad}", file=sys.stderr)
        return 1
    print("stable:", ", ".join(row[0] for row in rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
