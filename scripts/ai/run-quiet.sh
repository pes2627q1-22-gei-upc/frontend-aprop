#!/usr/bin/env bash
# Executa una ordre i mostra només els errors i el resum (estalvia tokens). El log complet queda en un fitxer.
#   bash scripts/ai/run-quiet.sh flutter test
#   bash scripts/ai/run-quiet.sh go test ./...
# Conserva el codi de sortida de l'ordre. MAX_LINES (per defecte 60) limita la sortida.
set -uo pipefail

if [ "$#" -eq 0 ]; then
  echo "ús: bash scripts/ai/run-quiet.sh <ordre> [args...]" >&2
  exit 2
fi

max="${MAX_LINES:-60}"
log="$(mktemp "${TMPDIR:-/tmp}/aprop-run.XXXXXX.log")"

cmd=("$@")
# Flutter instal·lat només a Windows: des de WSL cal cmd.exe.
if [[ "${cmd[0]}" == "flutter" || "${cmd[0]}" == "dart" ]] && ! "${cmd[0]}" --version >/dev/null 2>&1 && command -v cmd.exe >/dev/null 2>&1; then
  cmd=(cmd.exe /c "${cmd[@]}")
fi

"${cmd[@]}" >"$log" 2>&1
status=$?

filter='(error|Error|ERROR|FAIL|Fail|failed|Expected:|Actual:|Which:|\[E\]|panic:|_test\.go:[0-9]+|\.dart:[0-9]+:[0-9]+|warning •|error •|Exception|Some tests failed|--- FAIL)'
summary='(All tests passed|tests? passed|No issues found|issues found|^ok |^PASS|^FAIL|coverage:|Formatted|Changed|Built|✓|✗|[0-9]+ (passed|failed))'

errors="$(grep -E "$filter" "$log" | grep -vE '^\s*$' | head -n "$max")"
summary_lines="$(grep -E "$summary" "$log" | tail -n 5)"

echo "\$ $* → exit $status"
if [ -n "$errors" ]; then
  echo "--- errors (màx. $max línies) ---"
  echo "$errors"
fi
echo "--- resum ---"
if [ -n "$summary_lines" ]; then echo "$summary_lines"; else tail -n 5 "$log"; fi
echo "--- log complet: $log ($(wc -l <"$log") línies) ---"
exit "$status"
