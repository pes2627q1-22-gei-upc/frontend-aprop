#!/usr/bin/env bash
# Formata el fitxer editat per l'agent (Cursor afterFileEdit i Antigravity PostToolUse). No bloqueja mai.
python3 "$(dirname "$0")/after_edit.py" || echo '{}'
