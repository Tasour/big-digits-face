#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.."

SDK_CFG="${CIQ_SDK_CFG:-$HOME/.Garmin/ConnectIQ/current-sdk.cfg}"
SDK="$(cat "$SDK_CFG")"
COMPAT="${CIQ_COMPAT_DIR:-$HOME/.opencode-poc/ciq-compat}"
JAVA="${CIQ_JAVA_HOME:-$HOME/.local/jdk21/jdk-21.0.13.1+2}"
export JAVA_HOME="$JAVA"
export PATH="$JAVA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$COMPAT"

"$SDK/bin/monkeyc" -f monkey.jungle -d fr955 -o bin/test-habits.prg \
  -y developer_key.der -t -w >/tmp/opencode/test-build.log 2>&1 || {
  tail -20 /tmp/opencode/test-build.log
  exit 1
}

STOP="$HOME/.opencode-poc/sim-stop.sh"
[ -x "$STOP" ] && "$STOP" >/dev/null 2>&1

LOG="docs/architecture/tests-$(date -u +%Y-%m-%d).log"
mkdir -p "$(dirname "$LOG")"
"$SDK/bin/simulator" bin/test-habits.prg >/tmp/opencode/test-sim.log 2>&1 &
SIM_PID=$!
sleep 10
if ! kill -0 "$SIM_PID" 2>/dev/null; then
  echo "SIMULATEUR_INDISPONIBLE"
  exit 2
fi

"$SDK/bin/monkeydo" "$PWD/bin/test-habits.prg" fr955 -t >"$LOG" 2>&1
rc=$?
kill "$SIM_PID" 2>/dev/null || true
[ -x "$STOP" ] && "$STOP" >/dev/null 2>&1

grep -E 'Ran [0-9]+ tests|PASSED \(' "$LOG" || true
if grep -q 'PASSED (passed=7, failed=0, errors=0)' "$LOG"; then
  exit 0
fi
exit "$rc"
