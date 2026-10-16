#!/usr/bin/env python3
"""Genera la configuració específica de cada eina d'IA a partir de les fonts úniques.

Fonts (s'editen a mà):
  .agents/rules/*.md        regles (format Antigravity: trigger, description, globs)
  .agents/skills/*/SKILL.md skills (estàndard Agent Skills; les llegeixen Cursor i Antigravity)
  docs/ai/agents/*.md       subagents (frontmatter propi amb camps cursor_* i antigravity_*)

Sortides (generades, no s'editen):
  .cursor/rules/*.mdc               regles per a Cursor
  .cursor/agents/*.md               subagents per a Cursor
  .agents/agents/<nom>/agent.md     subagents per a Antigravity
  amb --backend RUTA: agents, skills compartides, regles compartides, scripts/ai i hooks al repo backend

Ús:
  python3 scripts/ai/sync-ai-config.py [--backend ../api-aprop] [--check]
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GENERATED = "GENERAT per scripts/ai/sync-ai-config.py des de {src}. No l'editis: edita la font i torna'l a generar."
SHARED_RULES = ("git-commits.md", "docs.md")
SHARED_SCRIPTS = ("scripts/ai",)
FRONTEND_ONLY_SCRIPTS = ("sync-ai-config.py", "templates/cursorignore")
SHARED_HOOK_CONFIGS = (".agents/hooks.json", ".cursor/hooks.json")
SKILL_NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


def split_frontmatter(text: str, src: Path) -> tuple[dict[str, str], str, str]:
    """Retorna (camps de primer nivell, frontmatter cru, cos)."""
    if not text.startswith("---\n"):
        raise SystemExit(f"{src}: falta el frontmatter YAML")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit(f"{src}: frontmatter sense tancar")
    raw = text[4:end]
    body = text[end + 5 :]
    fields: dict[str, str] = {}
    for line in raw.splitlines():
        if not line or line.startswith((" ", "\t", "#", "-")):
            continue
        key, sep, value = line.partition(":")
        if sep:
            fields[key.strip()] = value.strip()
    return fields, raw, body


def unquote(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def yaml_str(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def parse_list(value: str) -> list[str]:
    value = value.strip()
    if not (value.startswith("[") and value.endswith("]")):
        raise ValueError(f"llista no vàlida: {value}")
    return [unquote(item.strip()) for item in value[1:-1].split(",") if item.strip()]


def display_path(src: Path) -> str:
    for base in (ROOT, ROOT.parent):
        try:
            return src.relative_to(base).as_posix()
        except ValueError:
            continue
    return src.as_posix()


def rule_to_mdc(src: Path) -> str:
    fields, _, body = split_frontmatter(src.read_text(encoding="utf-8"), src)
    trigger = fields.get("trigger")
    description = unquote(fields.get("description", ""))
    globs = unquote(fields.get("globs", fields.get("glob", "")))
    lines = ["---"]
    if trigger == "always_on":
        lines += [f"description: {yaml_str(description)}", "alwaysApply: true"]
    elif trigger == "glob":
        if not globs:
            raise SystemExit(f"{src}: trigger glob sense globs")
        lines += [f"description: {yaml_str(description)}", f"globs: {globs}", "alwaysApply: false"]
    elif trigger == "model_decision":
        if not description:
            raise SystemExit(f"{src}: model_decision requereix description")
        lines += [f"description: {yaml_str(description)}", "alwaysApply: false"]
    elif trigger == "manual":
        lines += ["alwaysApply: false"]
    else:
        raise SystemExit(f"{src}: trigger desconegut: {trigger!r}")
    lines.append("---")
    return "\n".join(lines) + f"\n<!-- {GENERATED.format(src=display_path(src))} -->\n" + body


def load_agents() -> list[tuple[Path, dict[str, str], str]]:
    agents = []
    for src in sorted((ROOT / "docs/ai/agents").glob("*.md")):
        if src.name.lower() == "readme.md":
            continue
        fields, _, body = split_frontmatter(src.read_text(encoding="utf-8"), src)
        for key in ("name", "description", "repos", "cursor_model", "antigravity_model", "antigravity_tools"):
            if key not in fields:
                raise SystemExit(f"{src}: falta el camp {key}")
        if fields["name"] != src.stem:
            raise SystemExit(f"{src}: name ha de coincidir amb el nom del fitxer")
        agents.append((src, fields, body))
    return agents


def agent_outputs(agent: tuple[Path, dict[str, str], str]) -> dict[str, str]:
    src, f, body = agent
    rel = src.relative_to(ROOT).as_posix()
    note = f"<!-- {GENERATED.format(src=rel)} -->\n"
    name = f["name"]
    description = yaml_str(unquote(f["description"]))
    readonly = f.get("cursor_readonly", "false").lower()
    cursor = "\n".join([
        "---",
        f"name: {name}",
        f"description: {description}",
        f"model: {unquote(f['cursor_model'])}",
        f"readonly: {readonly}",
        "is_background: false",
        "---",
    ]) + "\n" + note + body
    tools = parse_list(f["antigravity_tools"])
    policy = unquote(f.get("antigravity_command_policy", "sandbox"))
    antigravity = "\n".join([
        "---",
        f"name: {name}",
        f"description: {description}",
        "tools: [" + ", ".join(tools) + "]",
        "mainAgent: false",
        "subagent: true",
        f"model: {unquote(f['antigravity_model'])}",
        f"commandExecutionPolicy: {yaml_str(policy)}",
        "---",
    ]) + "\n" + note + body
    return {
        f".cursor/agents/{name}.md": cursor,
        f".agents/agents/{name}/agent.md": antigravity,
    }


def skill_repos(skill_md: Path) -> str:
    _, raw, _ = split_frontmatter(skill_md.read_text(encoding="utf-8"), skill_md)
    match = re.search(r"^\s+repos:\s*(\w+)", raw, re.MULTILINE)
    return match.group(1) if match else "frontend"


def validate_skills(skills_dir: Path) -> list[str]:
    errors = []
    for skill_md in sorted(skills_dir.glob("*/SKILL.md")):
        fields, _, body = split_frontmatter(skill_md.read_text(encoding="utf-8"), skill_md)
        name = fields.get("name", "")
        description = unquote(fields.get("description", ""))
        folder = skill_md.parent.name
        if name != folder:
            errors.append(f"{skill_md}: name '{name}' ≠ carpeta '{folder}'")
        if not SKILL_NAME_RE.match(name) or len(name) > 64:
            errors.append(f"{skill_md}: name no vàlid")
        if not description or len(description) > 1024:
            errors.append(f"{skill_md}: description buida o > 1024 caràcters")
        if re.search(r"(^|\s)#", fields.get("description", "")) and not fields["description"].startswith(("\"", "'")):
            errors.append(f"{skill_md}: description amb ' #' sense cometes (YAML ho llegeix com a comentari)")
        if re.search(r":\s", description) and not fields["description"].startswith(("\"", "'")):
            errors.append(f"{skill_md}: description amb ': ' sense cometes")
        if body.count("\n") > 130:
            errors.append(f"{skill_md}: SKILL.md massa llarg ({body.count(chr(10))} línies); mou-ne part a references/")
    return errors


def build(backend: Path | None) -> dict[Path, str]:
    """Calcula tots els fitxers de sortida (ruta absoluta → contingut)."""
    out: dict[Path, str] = {}
    for src in sorted((ROOT / ".agents/rules").glob("*.md")):
        out[ROOT / ".cursor/rules" / f"{src.stem}.mdc"] = rule_to_mdc(src)
    for agent in load_agents():
        repos = agent[1]["repos"]
        for rel, content in agent_outputs(agent).items():
            if repos in ("frontend", "both"):
                out[ROOT / rel] = content
            if backend and repos in ("backend", "both"):
                out[backend / rel] = content
    if backend:
        for name in SHARED_RULES:
            src = ROOT / ".agents/rules" / name
            out[backend / ".agents/rules" / name] = src.read_text(encoding="utf-8")
            out[backend / ".cursor/rules" / f"{src.stem}.mdc"] = rule_to_mdc(src)
        for src in sorted((backend / ".agents/rules").glob("*.md")):
            if src.name not in SHARED_RULES:
                out[backend / ".cursor/rules" / f"{src.stem}.mdc"] = rule_to_mdc(src)
        for skill_md in sorted((ROOT / ".agents/skills").glob("*/SKILL.md")):
            if skill_repos(skill_md) in ("both", "backend"):
                for file in skill_md.parent.rglob("*"):
                    if file.is_file():
                        rel = file.relative_to(ROOT)
                        out[backend / rel] = file.read_text(encoding="utf-8")
        for folder in SHARED_SCRIPTS:
            for file in (ROOT / folder).rglob("*"):
                rel_in_folder = file.relative_to(ROOT / folder).as_posix()
                if file.is_file() and "__pycache__" not in file.parts and rel_in_folder not in FRONTEND_ONLY_SCRIPTS:
                    out[backend / file.relative_to(ROOT)] = file.read_text(encoding="utf-8")
        for rel in SHARED_HOOK_CONFIGS:
            out[backend / rel] = (ROOT / rel).read_text(encoding="utf-8")
    return out


def stale_generated(expected: dict[Path, str], backend: Path | None) -> list[Path]:
    """Fitxers generats que ja no tenen font (p. ex. un agent esborrat)."""
    roots = [ROOT] + ([backend] if backend else [])
    found = []
    for root in roots:
        for pattern in (".cursor/rules/*.mdc", ".cursor/agents/*.md", ".agents/agents/*/agent.md"):
            for file in root.glob(pattern):
                if "GENERAT per scripts/ai/sync-ai-config.py" in file.read_text(encoding="utf-8") and file not in expected:
                    found.append(file)
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--backend", type=Path, help="ruta del repo backend (p. ex. ../api-aprop)")
    parser.add_argument("--check", action="store_true", help="no escriu; surt amb 1 si hi ha diferències")
    args = parser.parse_args()
    backend = args.backend.resolve() if args.backend else None
    if backend and not (backend / "go.mod").exists():
        print(f"{backend} no sembla el repo backend (no hi ha go.mod)", file=sys.stderr)
        return 2

    errors = validate_skills(ROOT / ".agents/skills")
    if backend and (backend / ".agents/skills").exists():
        errors += validate_skills(backend / ".agents/skills")
    expected = build(backend)
    stale = stale_generated(expected, backend)
    changed = [p for p, c in expected.items() if not p.exists() or p.read_text(encoding="utf-8") != c]

    for error in errors:
        print(f"ERROR {error}", file=sys.stderr)
    if args.check:
        for path in changed:
            print(f"DESACTUALITZAT {path}")
        for path in stale:
            print(f"SOBRANT {path}")
        return 1 if (errors or changed or stale) else 0
    if errors:
        return 1
    for path in changed:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(expected[path], encoding="utf-8", newline="\n")
        print(f"escrit {path.relative_to(path.anchor)}")
    for path in stale:
        target = path.parent if path.name == "agent.md" else path
        shutil.rmtree(target) if target.is_dir() else target.unlink()
        print(f"esborrat {path}")
    print(f"{len(changed)} fitxers actualitzats, {len(stale)} esborrats, {len(expected) - len(changed)} sense canvis")
    return 0


if __name__ == "__main__":
    sys.exit(main())
