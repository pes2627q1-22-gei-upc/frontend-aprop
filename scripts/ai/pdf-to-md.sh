#!/usr/bin/env bash
# Extreu el text d'un PDF de docs/source/ per poder-ne actualitzar els resums de docs/ai/ sense llegir el PDF sencer.
#   bash scripts/ai/pdf-to-md.sh docs/source/incepcio-2.pdf      → docs/source/incepcio-2.txt (ignorat per git)
# Després, demana a l'agent que compari el .txt amb el fitxer de docs/ai/ corresponent (només la secció canviada).
set -euo pipefail

pdf="${1:?ús: bash scripts/ai/pdf-to-md.sh <fitxer.pdf>}"
out="${pdf%.pdf}.txt"

if command -v pdftotext >/dev/null 2>&1; then
  pdftotext -layout -enc UTF-8 "$pdf" "$out"
elif python3 -c "import pypdf" >/dev/null 2>&1; then
  python3 - "$pdf" "$out" <<'PY'
import sys
from pypdf import PdfReader
reader = PdfReader(sys.argv[1])
with open(sys.argv[2], "w", encoding="utf-8") as fh:
    for i, page in enumerate(reader.pages, 1):
        fh.write(f"\n\n-- pàgina {i} --\n\n{page.extract_text() or ''}")
PY
else
  echo "Cal pdftotext (sudo apt install poppler-utils) o pypdf (pip install --user pypdf)." >&2
  echo "Alternativa: obre el PDF amb l'eina de lectura de l'agent i demana només les pàgines necessàries." >&2
  exit 1
fi

echo "Text extret a $out ($(wc -l <"$out") línies). No el versionis: és a .gitignore."
