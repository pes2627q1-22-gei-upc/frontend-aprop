#!/usr/bin/env python3
"""Valida el format de commit de l'equip: «Tasca #<ID> <Títol de la tasca>: <descripció>».

Ús:
  python3 scripts/ai/commit_msg.py "Tasca #42 Títol: descripció"
  python3 scripts/ai/commit_msg.py --file .git/COMMIT_EDITMSG     (hook commit-msg de git)
"""

from __future__ import annotations

import re
import sys

PATTERN = re.compile(r"^Tasca #(?P<id>\d+) (?P<title>[^:]+?): (?P<desc>\S.*)$")
ALLOWED_PREFIXES = ("Merge ", "Revert ", "fixup! ", "squash! ")
EXAMPLE = "Tasca #42 Autenticació Google: Implementació de la validació de tokens JWT en el backend"


def validate(message: str) -> str | None:
    """Retorna None si és vàlid, o el motiu de l'error."""
    lines = [line for line in message.splitlines() if not line.startswith("#")]
    subject = lines[0].strip() if lines else ""
    if subject.startswith(ALLOWED_PREFIXES):
        return None
    match = PATTERN.match(subject)
    if not match:
        return f"ha de ser «Tasca #<ID> <Títol>: <descripció>». Exemple: {EXAMPLE}"
    if len(match["desc"]) < 10:
        return "la descripció és massa curta (≥ 10 caràcters)"
    if match["desc"].lower().rstrip(".") in {"canvis", "fix", "wip", "update", "arreglos", "cambios"}:
        return "la descripció ha d'explicar què canvia"
    if len(subject) > 160:
        return "la primera línia supera els 160 caràcters"
    return None


def main(argv: list[str]) -> int:
    if len(argv) >= 2 and argv[0] == "--file":
        with open(argv[1], encoding="utf-8") as handle:
            message = handle.read()
    elif argv:
        message = " ".join(argv)
    else:
        print(__doc__)
        return 2
    error = validate(message)
    if error:
        print(f"✗ Missatge de commit no vàlid: {error}", file=sys.stderr)
        return 1
    print("✓ Missatge de commit vàlid")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
