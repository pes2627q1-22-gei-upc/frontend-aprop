#!/usr/bin/env bash
# Valida un missatge de commit amb el format de l'equip.
#   bash scripts/ai/check-commit-msg.sh "Tasca #42 Títol: descripció"
#   bash scripts/ai/check-commit-msg.sh --file .git/COMMIT_EDITMSG
set -euo pipefail
exec python3 "$(dirname "$0")/commit_msg.py" "$@"
