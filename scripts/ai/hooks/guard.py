#!/usr/bin/env python3
"""Hook de seguretat abans d'executar ordres o llegir fitxers (Cursor i Antigravity).

Entrada (stdin, JSON):
  Cursor beforeShellExecution: {"command": "...", "cwd": "..."}
  Cursor beforeReadFile:       {"file_path": "..."}
  Antigravity PreToolUse:      {"toolCall": {"name": "run_command|view_file", "args": {...}}}
Sortida (stdout, JSON): {"permission": ...} per a Cursor, {"decision": ...} per a Antigravity.
"""

from __future__ import annotations

import json
import re
import shlex
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
from commit_msg import validate as validate_commit_msg  # noqa: E402
from toolchain import to_local_path  # noqa: E402

PROTECTED = {"main", "master", "develop"}
SECRET_FILE = re.compile(r"(^|/)(\.env(\..+)?|.*\.pem|.*\.key|id_rsa.*|credentials\.json|service-account.*\.json)$", re.I)
ENV_EXAMPLE = re.compile(r"(^|/)\.env\.(example|sample|template)$", re.I)
SECRET_CONTENT = [
    (re.compile(r"AIza[0-9A-Za-z_\-]{35}"), "clau d'API de Google"),
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"), "clau privada"),
    (re.compile(r"AKIA[0-9A-Z]{16}"), "clau d'accés d'AWS"),
    (re.compile(r"gh[pousr]_[A-Za-z0-9]{36,}"), "token de GitHub"),
    (re.compile(r"\"private_key\"\s*:"), "credencial de compte de servei"),
    (re.compile(r"(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*['\"][^'\"\s]{12,}['\"]"), "secret literal"),
]
ASK_GIT = re.compile(r"\bgit\s+(reset\s+--hard|clean\s+-[a-z]*f|rebase|branch\s+-D|stash\s+(drop|clear)|checkout\s+--|restore\b|add\s+(-A|--all|\.)(\s|$)|merge\b|tag\b)")


def git(cwd: str, *args: str) -> str:
    try:
        return subprocess.run(["git", *args], cwd=cwd or None, capture_output=True, text=True, timeout=20).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def check_read(path: str) -> tuple[str, str] | None:
    normalized = path.replace("\\", "/")
    if SECRET_FILE.search(normalized) and not ENV_EXAMPLE.search(normalized):
        return "deny", f"Lectura bloquejada: {Path(normalized).name} pot contenir secrets (regla de AGENTS.md)."
    return None


def check_commit(command: str, cwd: str) -> tuple[str, str]:
    branch = git(cwd, "branch", "--show-current").strip()
    if branch in PROTECTED:
        return "deny", f"Commit a la branca protegida '{branch}'. Crea una branca feature/ o hotfix/."
    staged = [f for f in git(cwd, "diff", "--cached", "--name-only").splitlines() if f]
    secrets = [f for f in staged if SECRET_FILE.search(f) and not ENV_EXAMPLE.search(f)]
    if secrets:
        return "deny", f"Hi ha fitxers amb secrets al stage: {', '.join(secrets)}. Treu-los (git restore --staged)."
    diff = git(cwd, "diff", "--cached", "-U0", "--no-color")
    added = "\n".join(line for line in diff.splitlines() if line.startswith("+") and not line.startswith("+++"))
    for pattern, label in SECRET_CONTENT:
        if pattern.search(added):
            return "deny", f"El diff en stage sembla contenir un {label}. Revisa'l abans de fer commit."
    try:
        tokens = shlex.split(command)
    except ValueError:
        tokens = command.split()
    messages = [tokens[i + 1] for i, t in enumerate(tokens[:-1]) if t in ("-m", "--message")]
    messages += [t.split("=", 1)[1] for t in tokens if t.startswith("--message=")]
    if messages:
        error = validate_commit_msg(messages[0])
        if error:
            return "deny", f"Missatge de commit no vàlid: {error}"
    return "ask", "Commit: cal la confirmació explícita d'una persona (regla de revisió humana)."


def check_command(command: str, cwd: str) -> tuple[str, str] | None:
    cmd = " ".join(command.split())
    if re.search(r"\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|-r\s+-f|-f\s+-r|--recursive\s+--force|--force\s+--recursive)\b", cmd):
        return "deny", "rm -rf bloquejat. Esborra els fitxers concrets o demana-ho a l'usuari."
    if re.search(r"\bgit\s+push\b", cmd):
        if re.search(r"(\s-f\b|--force|--mirror|--delete|\s:\S)", cmd):
            return "deny", "Push forçat o destructiu bloquejat (Gitflow)."
        if any(re.search(rf"(\s|:|/){b}(\s|$)", cmd) for b in PROTECTED):
            return "deny", "Push directe a una branca protegida. Obre una PR."
        branch = git(cwd, "branch", "--show-current").strip()
        if branch in PROTECTED and not re.search(r"\s(feature|hotfix)/", cmd):
            return "deny", f"Ets a '{branch}': no es pot fer push directament. Obre una PR des d'una branca feature/."
        return "ask", "Push: cal la confirmació explícita d'una persona."
    if re.search(r"\bgit\s+commit\b", cmd):
        return check_commit(command, cwd)
    if ASK_GIT.search(cmd):
        return "ask", "Ordre de git que pot perdre feina o afectar l'historial: confirma-la."
    for token in re.findall(r"[^\s'\"<>|;&]+", cmd):
        result = check_read(token)
        if result and re.search(r"\b(cat|less|more|head|tail|type|bat|grep|rg|sed|awk|cp|source|\.)\b|Get-Content", cmd):
            return result
    return None


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        payload = {}
    antigravity = "toolCall" in payload
    result: tuple[str, str] | None = None

    if antigravity:
        call = payload.get("toolCall", {})
        args = call.get("args", {}) or {}
        if call.get("name") == "run_command":
            result = check_command(args.get("CommandLine", ""), to_local_path(args.get("Cwd", "")))
        elif call.get("name") in ("view_file", "grep_search"):
            result = check_read(args.get("AbsolutePath") or args.get("SearchPath") or "")
    elif "command" in payload:
        result = check_command(payload.get("command", ""), to_local_path(payload.get("cwd", "")))
    elif "file_path" in payload:
        result = check_read(payload.get("file_path", ""))

    decision, reason = result or ("allow", "")
    if antigravity:
        mapped = {"ask": "force_ask"}.get(decision, decision)
        out = {"decision": mapped}
        if reason:
            out["reason"] = reason
    else:
        out = {"permission": decision}
        if reason:
            out["user_message"] = reason
            out["agent_message"] = reason
    print(json.dumps(out, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
