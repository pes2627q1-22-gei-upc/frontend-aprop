#!/usr/bin/env python3
"""Formata el fitxer que l'agent acaba d'editar (dart format / gofmt). No bloqueja mai.

Entrada (stdin, JSON):
  Cursor afterFileEdit:     {"file_path": "..."}
  Antigravity PostToolUse:  {"toolCall": {"name": "write_to_file|replace_file_content|...", "args": {"TargetFile": "..."}}}
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from toolchain import run_dart, run_go_tool, to_local_path  # noqa: E402


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        payload = {}
    if "toolCall" in payload:
        path = (payload["toolCall"].get("args") or {}).get("TargetFile", "")
    else:
        path = payload.get("file_path", "")
    path = to_local_path(path)
    file = Path(path)
    if file.suffix == ".dart" and file.exists():
        run_dart(["format", str(file)], cwd=file.parent, timeout=60)
    elif file.suffix == ".go" and file.exists():
        run_go_tool(["gofmt", "-w", str(file)], cwd=file.parent, timeout=30)
    print("{}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
