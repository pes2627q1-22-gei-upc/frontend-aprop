#!/usr/bin/env bash
# Mesura el context base de cada eina d'IA. Surt amb 1 si AGENTS.md supera les 150 línies.
exec python3 "$(dirname "$0")/context-size.py" "$@"
