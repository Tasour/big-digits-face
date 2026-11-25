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

# Le serveur MCP n'herite pas de la session Wayland : on retrouve le socket
# et l'instance Hyprland dans /run/user/<uid> avant de lancer le simulateur.
UID_RUN="$(id -u)"
if [ -z "${XDG_RUNTIME_DIR:-}" ]; then export XDG_RUNTIME_DIR="/run/user/$UID_RUN"; fi
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
  for sock in /run/user/$UID_RUN/wayland-*; do
    case "$sock" in *.lock) continue;; esac
    [ -S "$sock" ] && export WAYLAND_DISPLAY="$(basename "$sock")" && break
  done
fi
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -d /run/user/$UID_RUN/hypr ]; then
  for instance in /run/user/$UID_RUN/hypr/*; do
    [ -d "$instance" ] && export HYPRLAND_INSTANCE_SIGNATURE="$(basename "$instance")" && break
  done
fi

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
if grep -qE 'PASSED \(passed=[0-9]+, failed=0, errors=0\)' "$LOG"; then
  exit 0
fi
exit "$rc"
