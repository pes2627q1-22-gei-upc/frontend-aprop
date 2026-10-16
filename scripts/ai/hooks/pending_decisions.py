"""Detecta, en els canvis de codi, dubtes que no s'han registrat a docs/decisions-pendents.md.

Senyals (només a les línies afegides de fitxers de codi o configuració):
  - TODO(confirmar), TODO(verificar), FIXME, HACK, XXX → cal registrar-los com a DP-NNN i marcar-los TODO(DP-NNN)
  - TODO(DP-NNN) amb un número que no existeix al registre
  - dependència nova a pubspec.yaml o go.mod que el registre no esmenta
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

DOC = Path("docs/decisions-pendents.md")
CODE_PREFIXES = ("lib/", "test/", "integration_test/", "internal/", "cmd/", "migrations/", "api/", ".github/workflows/",
                 "android/", "ios/")
CODE_FILES = ("pubspec.yaml", "go.mod", "Dockerfile", "analysis_options.yaml", ".env.example")
UNREGISTERED = re.compile(r"TODO\((confirmar|verificar)\)|\bFIXME\b|\bHACK\b|\bXXX\b")
DP_MARK = re.compile(r"TODO\((DP-\d{3})\)")
PUB_DEP = re.compile(r"^\s{2}([a-z0-9_]+):\s*(\^|\d|any|$)")
GO_DEP = re.compile(r"^\s*(?:require\s+)?([a-z0-9.\-]+\.[a-z]{2,}/[\w.\-/]+)\s+v\d")


def _git(cwd: Path, *args: str) -> str:
    try:
        return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, timeout=30).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def doc_path(root: Path) -> Path | None:
    """El registre és al frontend; des del backend es busca a ../frontend-aprop/."""
    for candidate in (root / DOC, root.parent / "frontend-aprop" / DOC):
        if candidate.exists():
            return candidate
    return None


def is_code(path: str) -> bool:
    return path.startswith(CODE_PREFIXES) or path in CODE_FILES


def added_lines(root: Path) -> list[tuple[str, str]]:
    """(fitxer, línia afegida) dels fitxers de codi modificats o nous respecte de HEAD."""
    result: list[tuple[str, str]] = []
    current = ""
    for line in _git(root, "diff", "HEAD", "-U0", "--no-color").splitlines():
        if line.startswith("+++ "):
            current = line[6:] if line.startswith("+++ b/") else ""
        elif line.startswith("+") and current and is_code(current):
            result.append((current, line[1:]))
    for path in _git(root, "ls-files", "--others", "--exclude-standard").splitlines():
        file = root / path
        if is_code(path) and file.is_file() and file.stat().st_size < 500_000:
            try:
                result += [(path, l) for l in file.read_text(encoding="utf-8").splitlines()]
            except UnicodeDecodeError:
                continue
    return result


def unregistered(root: Path) -> list[str]:
    doc = doc_path(root)
    registry = doc.read_text(encoding="utf-8") if doc else ""
    known = set(re.findall(r"^### (DP-\d{3})", registry, re.MULTILINE))
    findings: list[str] = []
    for path, line in added_lines(root):
        text = line.strip()
        if UNREGISTERED.search(text):
            findings.append(f"{path}: «{text[:90]}» → registra-ho com a DP-NNN i canvia el marcador per TODO(DP-NNN)")
        for dp in DP_MARK.findall(text):
            if dp not in known:
                findings.append(f"{path}: {dp} no existeix a {DOC}")
        dep = None
        if path.endswith("pubspec.yaml"):
            match = PUB_DEP.match(line)
            dep = match.group(1) if match and match.group(1) not in ("sdk", "flutter", "flutter_test", "version") else None
        elif path.endswith("go.mod"):
            match = GO_DEP.match(line)
            dep = match.group(1) if match else None
        if dep and dep not in registry:
            findings.append(f"{path}: dependència nova «{dep}» → registra la decisió (AGENTS.md: cap paquet sense necessitat)")
    if findings and not doc:
        findings.insert(0, f"No s'ha trobat {DOC} (ni a ../frontend-aprop/).")
    return findings
