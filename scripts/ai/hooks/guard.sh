#!/usr/bin/env bash
# Punt d'entrada del hook de seguretat (Cursor beforeShellExecution/beforeReadFile i Antigravity PreToolUse).
# A Windows, Cursor executa `bash` = WSL; per això la lògica és en Python i no depèn de jq.
exec python3 "$(dirname "$0")/guard.py"
