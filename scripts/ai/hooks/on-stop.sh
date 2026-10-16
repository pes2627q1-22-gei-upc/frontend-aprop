#!/usr/bin/env bash
# Comprovació final de flutter analyze / gofmt / go vet sobre els fitxers modificats (Cursor stop i Antigravity Stop).
python3 "$(dirname "$0")/on_stop.py" || echo '{}'
