#!/usr/bin/env bash
# Opcional i per persona: instal·la un hook commit-msg de git que valida el format «Tasca #ID Títol: descripció».
# També protegeix contra commits a master/main/develop. No s'activa sol: cadascú decideix si l'instal·la.
#   bash scripts/ai/install-git-hooks.sh
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
hooks="$(git rev-parse --git-path hooks)"
mkdir -p "$hooks"

cat >"$hooks/commit-msg" <<'HOOK'
#!/usr/bin/env bash
exec python3 "$(git rev-parse --show-toplevel)/scripts/ai/commit_msg.py" --file "$1"
HOOK

cat >"$hooks/pre-commit" <<'HOOK'
#!/usr/bin/env bash
branch="$(git branch --show-current)"
case "$branch" in
  main|master|develop) echo "✗ No es pot fer commit directament a '$branch'. Fes servir una branca feature/ o hotfix/." >&2; exit 1 ;;
esac
if git diff --cached --name-only | grep -Eq '(^|/)\.env($|\.)' && ! git diff --cached --name-only | grep -Eq '(^|/)\.env\.example$'; then
  echo "✗ Hi ha un fitxer .env al stage. Treu-lo amb: git restore --staged <fitxer>" >&2; exit 1
fi
HOOK

chmod +x "$hooks/commit-msg" "$hooks/pre-commit"
echo "Hooks instal·lats a $hooks (repo: $root). Per desinstal·lar-los: rm \"$hooks/commit-msg\" \"$hooks/pre-commit\""
