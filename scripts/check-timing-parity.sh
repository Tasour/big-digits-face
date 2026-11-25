#!/usr/bin/env bash
# Parite du moteur de timing : la copie compagnon doit etre identique au
# module partage apres retrait des annotations (:background) propres au
# service background de la watch-app.
set -uo pipefail
cd "$(dirname "$0")/.."

SHARED="shared/Timing.mc"
COMPANION="companion/source/Timing.mc"
TMP="$(mktemp /tmp/opencode/timing-parity.XXXXXX)"
trap 'rm -f "$TMP"' EXIT

grep -v '^(:background)$' "$COMPANION" >"$TMP"
if diff -q "$SHARED" "$TMP" >/dev/null; then
  echo "OK  parite Timing.mc (face = compagnon)"
  exit 0
fi
echo "KO  divergence entre $SHARED et $COMPANION" >&2
diff -u "$SHARED" "$TMP" | head -40 >&2
exit 1
