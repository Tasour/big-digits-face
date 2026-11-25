#!/usr/bin/env python3
"""Capture la vue diagnostic de l'app compagnon sur le simulateur fr955.

Usage : python3 scripts/capture-companion.py [prg] [slug]
Nécessite le SDK Connect IQ, le device fr955 et le répertoire de compatibilité
des libs GTK (CIQ_COMPAT_DIR, défaut ~/.opencode-poc/ciq-compat).
"""
import json
import os
import signal
import subprocess
import sys
import time
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SDK = Path(os.environ.get("CIQ_SDK_CFG", Path.home() / ".Garmin/ConnectIQ/current-sdk.cfg")).read_text().strip()
COMPAT = os.environ.get("CIQ_COMPAT_DIR", str(Path.home() / ".opencode-poc/ciq-compat"))
PRG = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "companion/bin/bigdigits-buzz-fr955.prg"
SLUG = sys.argv[2] if len(sys.argv) > 2 else "app-diagnostic"
OUT = ROOT / "docs/screens"


def session_env():
    """Complete l'environnement quand le script est lance hors du shell utilisateur.

    Un serveur MCP n'herite pas forcement de HYPRLAND_INSTANCE_SIGNATURE ni de
    WAYLAND_DISPLAY : on les retrouve dans /run/user/<uid>.
    """
    env = os.environ.copy()
    uid = os.getuid()
    if not env.get("XDG_RUNTIME_DIR"):
        env["XDG_RUNTIME_DIR"] = f"/run/user/{uid}"
    if not env.get("HYPRLAND_INSTANCE_SIGNATURE"):
        base = Path(f"/run/user/{uid}/hypr")
        if base.is_dir():
            for entry in sorted(base.iterdir()):
                env["HYPRLAND_INSTANCE_SIGNATURE"] = entry.name
                break
    # Force la valeur reelle du socket : un environnement hrite peut porter
    # un WAYLAND_DISPLAY mort (wayland-0) et faire echouer grim.
    for candidate in sorted(Path(f"/run/user/{uid}").glob("wayland-*")):
        if candidate.suffix != ".lock":
            env["WAYLAND_DISPLAY"] = candidate.name
            break
    env["XDG_SESSION_TYPE"] = "wayland"
    env.pop("GDK_BACKEND", None)
    env.pop("DISPLAY", None)
    return env


SESSION_ENV = session_env()


def geometry():
    out = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True,
                         env=SESSION_ENV).stdout
    try:
        clients = json.loads(out)
    except json.JSONDecodeError:
        return None
    for c in clients:
        if c.get("class") == "simulator":
            x, y = c["at"]
            w, h = c["size"]
            return int(x * 2), int(y * 2), int(w * 2), int(h * 2), c["address"]
    return None


env = SESSION_ENV.copy()
env["LD_LIBRARY_PATH"] = COMPAT
env["JAVA_HOME"] = os.environ.get("CIQ_JAVA_HOME", str(Path.home() / ".local/jdk21/jdk-21.0.13.1+2"))
env["PATH"] = env["JAVA_HOME"] + "/bin:" + env["PATH"]

subprocess.run([str(Path.home() / ".opencode-poc/sim-stop.sh")], capture_output=True)
geo = None
for attempt in range(4):
    with open("/tmp/ciq-capture.log", "w") as log:
        subprocess.Popen([f"{SDK}/bin/simulator", str(PRG)], env=env, stdout=log, stderr=log)
    time.sleep(10)
    mdo = subprocess.Popen([f"{SDK}/bin/monkeydo", str(PRG), "fr955"], env=env,
                           stdout=open("/tmp/ciq-capture.log", "a"),
                           stderr=subprocess.STDOUT, start_new_session=True)
    time.sleep(20)
    for probe in range(6):
        time.sleep(3)
        geo = geometry()
        if geo and geo[2] > 100 and geo[3] > 100:
            break
        geo = None
    if geo:
        break
if not geo:
    raise SystemExit("simulator introuvable ou géométrie invalide")

x, y, w, h, addr = geo
# API Lua de Hyprland 0.56 : les selecteurs passent par une table.
# Hyprland 0.56 exige un objet Window, pas une chaine d'adresse.
win_ref = f"hl.get_window('address:{addr}')"
for call in (f'hl.dsp.focus({{window={win_ref}}})',
             f'hl.dsp.window.bring_to_top({{window={win_ref}}})'):
    subprocess.run(["hyprctl", "eval", call], capture_output=True, env=SESSION_ENV)
time.sleep(2)
raw = Path(f"/tmp/ciq-{SLUG}.png")
subprocess.run(["grim", str(raw)], check=True, env=SESSION_ENV)
win = Image.open(raw).crop((x, y, x + w, y + h))
OUT.mkdir(parents=True, exist_ok=True)
win.save(OUT / f"{SLUG}-simulator.png")
watch = win.crop((142, 356, 662, 876))
watch.save(OUT / f"{SLUG}-watch.png")
print(f"capture OK {SLUG} tentative {attempt + 1}")
# On ne coupe l'application qu'apres la capture : sinon l'ecran est noir.
if mdo.poll() is None:
    os.killpg(os.getpgid(mdo.pid), signal.SIGTERM)
subprocess.run(["pkill", "-x", "simulator"], capture_output=True, env=SESSION_ENV)
