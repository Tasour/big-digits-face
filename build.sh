#!/usr/bin/env bash
# Compile le cadran Big Digits pour Forerunner 955.
# Prérequis : SDK Connect IQ décompressé + 'current-sdk.cfg' pointant dessus,
# et un runtime Java dans le PATH.
set -euo pipefail
cd "$(dirname "$0")"

CFG="$HOME/.Garmin/ConnectIQ/current-sdk.cfg"
if [ ! -f "$CFG" ]; then
  echo "SDK non configuré : $CFG introuvable." >&2
  echo "Voir README : télécharger le SDK puis écrire son chemin dans ce fichier." >&2
  exit 1
fi

SDK_BIN="$(cat "$CFG")/bin"
if [ ! -x "$SDK_BIN/monkeyc" ]; then
  echo "monkeyc introuvable dans $SDK_BIN" >&2
  exit 1
fi

mkdir -p bin
"$SDK_BIN/monkeyc" \
  -f monkey.jungle \
  -d fr955 \
  -o bin/bigdigits-fr955.prg \
  -y developer_key.der \
  -r \
  -w
echo "OK: bin/bigdigits-fr955.prg"
