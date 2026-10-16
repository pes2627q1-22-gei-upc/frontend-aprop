"""Utilitats compartides pels hooks: rutes Windows↔WSL i execució de dart/flutter/go."""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path, PurePosixPath, PureWindowsPath

_DART_MODE: str | None = None


def to_local_path(path: str) -> str:
    if re.match(r"^[A-Za-z]:[\\/]", path or "") and sys.platform != "win32":
        win = PureWindowsPath(path)
        return str(PurePosixPath("/mnt", win.drive[0].lower(), *win.parts[1:]))
    return path


def to_windows_path(path: str) -> str:
    match = re.match(r"^/mnt/([a-z])/(.*)$", path)
    if not match:
        return path
    return f"{match[1].upper()}:\\" + match[2].replace("/", "\\")


def _run(cmd: list[str], cwd: Path | str | None, timeout: int) -> subprocess.CompletedProcess[str] | None:
    try:
        return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.SubprocessError):
        return None


def _dart_mode() -> str:
    """'native' si `dart` funciona aquí, 'windows' si cal cmd.exe (Flutter instal·lat a Windows), 'none' si no n'hi ha."""
    global _DART_MODE
    if _DART_MODE is None:
        probe = _run(["dart", "--version"], None, 30) if shutil.which("dart") else None
        if probe and probe.returncode == 0:
            _DART_MODE = "native"
        elif shutil.which("cmd.exe"):
            probe = _run(["cmd.exe", "/c", "dart", "--version"], "/mnt/c", 30)
            _DART_MODE = "windows" if probe and probe.returncode == 0 else "none"
        else:
            _DART_MODE = "none"
    return _DART_MODE


def run_flutter_tool(tool: str, args: list[str], cwd: Path | str, timeout: int) -> subprocess.CompletedProcess[str] | None:
    """Executa `dart` o `flutter` amb els arguments donats, a WSL o via cmd.exe."""
    mode = _dart_mode()
    if mode == "native":
        return _run([tool, *args], cwd, timeout)
    if mode == "windows":
        win_args = [to_windows_path(a) if a.startswith("/mnt/") else a for a in args]
        return _run(["cmd.exe", "/c", tool, *win_args], cwd, timeout)
    return None


def run_dart(args: list[str], cwd: Path | str, timeout: int) -> subprocess.CompletedProcess[str] | None:
    return run_flutter_tool("dart", args, cwd, timeout)


def run_go_tool(cmd: list[str], cwd: Path | str, timeout: int) -> subprocess.CompletedProcess[str] | None:
    if not shutil.which(cmd[0]):
        return None
    return _run(cmd, cwd, timeout)
