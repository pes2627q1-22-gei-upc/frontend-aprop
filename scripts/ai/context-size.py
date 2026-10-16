#!/usr/bin/env python3
"""Mesura aproximada del context base que cada eina carrega sempre (abans de llegir res sota demanda).

Aproximació: 1 token ≈ 4 caràcters (en català el valor real pot ser una mica més alt).
Ús: python3 scripts/ai/context-size.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def tokens(text: str) -> int:
    return round(len(text) / 4)


def frontmatter(text: str) -> str:
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end != -1:
            return text[4:end]
    return ""


def field(fm: str, key: str) -> str:
    match = re.search(rf"^{key}:\s*(.*)$", fm, re.MULTILINE)
    return match.group(1).strip() if match else ""


def main() -> int:
    agents_md = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
    skills = sorted((ROOT / ".agents/skills").glob("*/SKILL.md"))
    skill_index = sum(
        tokens(field(frontmatter(p.read_text(encoding="utf-8")), "name") + field(frontmatter(p.read_text(encoding="utf-8")), "description"))
        for p in skills
        if "disable-model-invocation: true" not in frontmatter(p.read_text(encoding="utf-8"))
    )
    command_index = sum(
        tokens(field(frontmatter(p.read_text(encoding="utf-8")), "name"))
        for p in skills
        if "disable-model-invocation: true" in frontmatter(p.read_text(encoding="utf-8"))
    )

    def agent_index(folder: str, pattern: str) -> int:
        return sum(tokens(field(frontmatter(p.read_text(encoding="utf-8")), "description")) for p in (ROOT / folder).glob(pattern))

    cursor_always = sum(
        tokens(p.read_text(encoding="utf-8"))
        for p in (ROOT / ".cursor/rules").glob("*.mdc")
        if "alwaysApply: true" in frontmatter(p.read_text(encoding="utf-8"))
    )
    cursor_desc = sum(
        tokens(field(frontmatter(p.read_text(encoding="utf-8")), "description"))
        for p in (ROOT / ".cursor/rules").glob("*.mdc")
        if "alwaysApply: true" not in frontmatter(p.read_text(encoding="utf-8")) and "globs:" not in frontmatter(p.read_text(encoding="utf-8"))
    )
    ag_always = sum(
        tokens(p.read_text(encoding="utf-8"))
        for p in (ROOT / ".agents/rules").glob("*.md")
        if field(frontmatter(p.read_text(encoding="utf-8")), "trigger") == "always_on"
    )
    ag_desc = sum(
        tokens(field(frontmatter(p.read_text(encoding="utf-8")), "description"))
        for p in (ROOT / ".agents/rules").glob("*.md")
        if field(frontmatter(p.read_text(encoding="utf-8")), "trigger") == "model_decision"
    )

    base = tokens(agents_md)
    rows = [
        ("Cursor", base, cursor_always + cursor_desc, skill_index + command_index, agent_index(".cursor/agents", "*.md")),
        ("Antigravity", base, ag_always + ag_desc, skill_index + command_index, agent_index(".agents/agents", "*/agent.md")),
    ]
    lines = agents_md.count("\n")
    print(f"AGENTS.md: {lines} línies, ~{base} tokens (objectiu < 150 línies)")
    print(f"{'Eina':<12} {'AGENTS.md':>9} {'regles':>7} {'skills*':>8} {'agents*':>8} {'total':>7}")
    for name, a, r, s, g in rows:
        print(f"{name:<12} {a:>9} {r:>7} {s:>8} {g:>8} {a + r + s + g:>7}")
    print("* només l'índex (nom + descripció); el cos es carrega sota demanda. Regles glob: 0 fins que s'obre un fitxer que coincideix.")
    return 0 if lines < 150 else 1


if __name__ == "__main__":
    sys.exit(main())
