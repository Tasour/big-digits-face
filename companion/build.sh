#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

CFG="$HOME/.Garmin/ConnectIQ/current-sdk.cfg"
if [ ! -f "$CFG" ]; then
  echo "SDK non configure : $CFG introuvable." >&2
  exit 1
fi

SDK_BIN="$(cat "$CFG")/bin"
mkdir -p bin
"$SDK_BIN/monkeyc" \
  -f monkey.jungle \
  -d fr955 \
  -o bin/bigdigits-buzz-fr955.prg \
  -y developer_key.der \
  -r \
  -l 2 \
  -w
echo "OK: bin/bigdigits-buzz-fr955.prg"
