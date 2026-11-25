#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"

rc=0
echo "== G0 : diff =="
git diff --check || rc=1

echo "== G1 : builds stricts (-l 3) =="
for b in build.sh companion/build.sh chrono/build.sh; do
  log="/tmp/opencode/verify-$(basename "$(dirname "$b")")-$(basename "$b").log"
  if (cd "$(dirname "$b")" && ./"$(basename "$b")") >"$log" 2>&1; then
    echo "OK  $b"
  else
    echo "KO  $b — $log"
    tail -20 "$log"
    rc=1
  fi
done

echo "== G2 : tests unitaires =="
if [ -x scripts/run-watch-tests.sh ]; then
  ./scripts/run-watch-tests.sh || rc=1
else
  echo "KO : scripts/run-watch-tests.sh absent"
  rc=1
fi

echo "== G3 : captures =="
if [ -d docs/screens ] && [ -n "$(find docs/screens -name '*.png' -print -quit)" ]; then
  echo "OK  captures présentes (à relire manuellement)"
else
  echo "KO  aucune capture"
  rc=1
fi

echo "== G4 : provenance =="
if [ -f RELEASES.md ] && grep -q 'SHA-256' RELEASES.md; then
  echo "OK  RELEASES.md présent"
else
  echo "KO  RELEASES.md absent — lancer release.sh"
  rc=1
fi

exit "$rc"
