#!/usr/bin/env python3
"""En acabar un torn de l'agent, analitza els fitxers Dart/Go modificats i, si hi ha errors, li demana que els corregeixi.

Només s'executa si el conjunt de canvis és diferent del de l'última comprovació (estalvia temps i tokens).
Entrada: Cursor `stop` ({"status": ..., "workspace_roots": [...]}) o Antigravity `Stop` ({"workspacePaths": [...]}).
Sortida: Cursor {"followup_message": "..."} · Antigravity {"decision": "continue", "reason": "..."} · o {} si tot és correcte.
"""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pending_decisions import unregistered  # noqa: E402
from toolchain import run_flutter_tool, run_go_tool, to_local_path  # noqa: E402

MAX_LINES = 15
MAX_CONTINUES = 2  # Antigravity no té loop_limit: limitem les represes per conversa


def git(cwd: Path, *args: str) -> str:
    try:
        return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, timeout=30).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def changed_files(root: Path) -> list[str]:
    tracked = git(root, "diff", "--name-only", "HEAD").splitlines()
    untracked = git(root, "ls-files", "--others", "--exclude-standard").splitlines()
    return sorted({f for f in tracked + untracked if f.endswith((".dart", ".go")) and (root / f).exists()})


def already_checked(root: Path, files: list[str], kind: str = "analyze") -> bool:
    digest = hashlib.sha256(git(root, "diff", "HEAD", "--", *files).encode() + "\n".join(files).encode()).hexdigest()
    stamp = Path(tempfile.gettempdir()) / f"aprop-ai-{kind}-{hashlib.sha1(str(root).encode()).hexdigest()[:10]}"
    if stamp.exists() and stamp.read_text() == digest:
        return True
    stamp.write_text(digest)
    return False


def analyze(root: Path, files: list[str]) -> list[str]:
    problems: list[str] = []
    dart = [f for f in files if f.endswith(".dart")]
    go = [f for f in files if f.endswith(".go")]
    if dart and (root / "pubspec.yaml").exists():
        result = run_flutter_tool("flutter", ["analyze", "--no-pub", *dart], cwd=root, timeout=170)
        if result and result.returncode != 0:
            problems += [l.strip() for l in result.stdout.splitlines() if " • " in l and ("error" in l or "warning" in l)]
    if go and (root / "go.mod").exists():
        unformatted = run_go_tool(["gofmt", "-l", *go], cwd=root, timeout=30)
        if unformatted and unformatted.stdout.strip():
            problems += [f"gofmt: {f}" for f in unformatted.stdout.split()]
        vet = run_go_tool(["go", "vet", "./..."], cwd=root, timeout=120)
        if vet and vet.returncode != 0:
            problems += [l for l in vet.stderr.splitlines() if l and not l.startswith("#")]
    return problems


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        payload = {}
    antigravity = "workspacePaths" in payload
    if antigravity and not payload.get("fullyIdle", True):
        print("{}")
        return 0
    roots = payload.get("workspacePaths") or payload.get("workspace_roots") or ["."]
    problems: list[str] = []
    pending: list[str] = []
    for raw in roots:
        root = Path(to_local_path(raw))
        files = changed_files(root)
        if files and not already_checked(root, files):
            problems += analyze(root, files)
        all_changed = sorted(set(git(root, "diff", "--name-only", "HEAD").split())
                             | set(git(root, "ls-files", "--others", "--exclude-standard").split()))
        if all_changed and not already_checked(root, all_changed, "decisions"):
            pending += unregistered(root)
    if pending:
        problems += ["Possibles decisions pendents sense registrar a docs/decisions-pendents.md "
                     "(fes servir el subagent vigilant-decisions o registra-les tu):", *pending]
    if antigravity and problems:
        counter = Path(tempfile.gettempdir()) / f"aprop-ai-stop-{payload.get('conversationId', 'x')}"
        count = int(counter.read_text()) if counter.exists() else 0
        if count >= MAX_CONTINUES:
            problems = []
        else:
            counter.write_text(str(count + 1))
    if not problems:
        print("{}")
        return 0
    shown = problems[:MAX_LINES]
    more = f"\n(+{len(problems) - MAX_LINES} més)" if len(problems) > MAX_LINES else ""
    message = "La revisió automàtica dels fitxers modificats ha trobat coses a resoldre abans d'acabar:\n" + "\n".join(shown) + more
    out = {"decision": "continue", "reason": message} if antigravity else {"followup_message": message}
    print(json.dumps(out, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
