#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

USB_DEV="${USB_DEV:-}"
if [ -z "$USB_DEV" ]; then
  echo "Usage : USB_DEV=/dev/bus/usb/XXX/YYY ./deploy.sh" >&2
  exit 1
fi

echo "Montage de $USB_DEV"
gio mount -d "$USB_DEV" >/dev/null 2>&1 || true  # déjà monté si le câble vient d'être branché

WATCH=''
for base in /run/user/$(id -u)/gvfs/mtp:*; do
  if [ -d "$base/Internal Storage/GARMIN/Apps" ]; then
    WATCH="$base/Internal Storage/GARMIN/Apps"
    break
  fi
done
if [ -z "$WATCH" ]; then
  echo "Dossier GARMIN/Apps introuvable" >&2
  gio mount -u "mtp://$(basename "$WATCH" 2>/dev/null || true)/" 2>/dev/null || true
  exit 1
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
for f in bin/bigdigits-fr955.prg companion/bin/bigdigits-buzz-fr955.prg chrono/bin/bigdigits-chrono-fr955.prg; do
  name="$(basename "$f")"
  if [ -f "$WATCH/$name" ]; then
    gio copy "$WATCH/$name" "$WATCH/$name.prev.$STAMP"
    echo "Sauvegarde $name.prev.$STAMP"
    # MTP refuse d'ecraser une destination existante (Operation non prise en
    # charge) : on retire l'ancien fichier apres sauvegarde.
    gio remove "$WATCH/$name"
  fi
  gio copy "$f" "$WATCH/$name"
  local_size="$(stat -c%s "$f")"
  remote_size="$(gio info "$WATCH/$name" 2>/dev/null | grep -oP 'standard::size: \K[0-9]+' || true)"
  if [ "$local_size" != "$remote_size" ]; then
    echo "KO taille $name : local=$local_size distant=$remote_size" >&2
    exit 1
  fi
  echo "OK $name ($remote_size octets)"
done

MTP_URI="$(gio mount -l | grep -oP 'mtp://\S+' | head -1 || true)"
if [ -n "$MTP_URI" ]; then
  gio mount -u "$MTP_URI" >/dev/null 2>&1 || true
fi
echo "Démontage terminé — débranche/rebranche la montre pour le scan."
