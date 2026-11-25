#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

./build.sh >/dev/null
(cd companion && ./build.sh >/dev/null)
(cd chrono && ./build.sh >/dev/null)

DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
HEAD_SHA="$(git rev-parse HEAD)"
{
  echo "# Releases — big-digits-face"
  echo
  echo "Généré le ${DATE} depuis ${HEAD_SHA}."
  echo
  echo '| Binaire | SHA-256 | Taille |'
  echo '|---|---|---:|'
  for f in bin/bigdigits-fr955.prg companion/bin/bigdigits-buzz-fr955.prg chrono/bin/bigdigits-chrono-fr955.prg; do
    printf '| `%s` | `%s` | %s |\n' "$f" "$(sha256sum "$f" | cut -d' ' -f1)" "$(stat -c%s "$f")"
  done
  echo
  echo "Arbre de travail au moment du build :"
  git status --short
} > RELEASES.md

echo "OK: RELEASES.md écrit"
