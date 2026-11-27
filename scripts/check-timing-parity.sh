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
if ! diff -q "$SHARED" "$TMP" >/dev/null; then
  echo "KO  divergence entre $SHARED et $COMPANION" >&2
  diff -u "$SHARED" "$TMP" | head -40 >&2
  exit 1
fi

# Les modules sans annotation sont des copies exactes.
for module in DiagLayout FeatureProbes ScriptVm ScriptLibrary VibrationPatterns; do
  if ! diff -q "shared/$module.mc" "companion/source/$module.mc" >/dev/null; then
    echo "KO  divergence $module.mc (face = compagnon)" >&2
    diff -u "shared/$module.mc" "companion/source/$module.mc" | head -40 >&2
    exit 1
  fi
done

echo "OK  parite Timing.mc, DiagLayout.mc, FeatureProbes.mc, ScriptVm.mc, ScriptLibrary.mc et VibrationPatterns.mc"
exit 0
