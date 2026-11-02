"""Réplique du cadran (cercle rouge) : 18:47:28, gris bleuté sur bleu nuit.
Maître 2080px -> downscale Lanczos 1040 (+ variante 260). Fond hors cercle transparent.
Usage: python3 dial_render.py [--time HHMMSS]
"""
import math
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ---------------- paramètres ----------------
TIME = "184728"
if len(sys.argv) > 1 and len(sys.argv[1]) == 6 and sys.argv[1].isdigit():
    TIME = sys.argv[1]
HH, MM, SS = TIME[0:2], TIME[2:4], TIME[4:6]

MASTER = 2080          # 2x de 1040
OUT1040 = "/home/tasour/Work/big-digits-face/dial-184728-1040.png"
OUT260 = "/home/tasour/Work/big-digits-face/dial-184728-260.png"

DSEG_BI = "/tmp/opencode/fonts/DSEG7Classic-BoldItalic.ttf"
DSEG_B = "/tmp/opencode/fonts/DSEG7Classic-Bold.ttf"

C_BG_C = (12, 19, 34)      # centre bleu nuit
C_BG_M = (8, 13, 23)       # mi-rayon
C_BG_E = (4, 6, 12)        # bord
C_DIGITS = (196, 203, 212)  # gris bleuté
DIGITS_ALPHA = 235          # ~92%
C_INK = (10, 14, 21)        # encre pastille secondes
C_RING = (35, 45, 61)

D = MASTER
CX = CY = D // 2
R = D // 2


def fit_font(path, sample, target_cap_h):
    """Trouve la taille donnant la hauteur de caps voulue (mesure réelle)."""
    size = int(target_cap_h / 0.72)
    for _ in range(3):
        f = ImageFont.truetype(path, size)
        bb = ImageDraw.Draw(Image.new("RGB", (8, 8))).textbbox((0, 0), sample, font=f)
        h = bb[3] - bb[1]
        size = int(size * target_cap_h / max(h, 1))
    return ImageFont.truetype(path, size)


def radial_bg():
    img = Image.new("RGB", (D, D), C_BG_E)
    px = img.load()
    for y in range(0, D, 2):
        for x in range(0, D, 2):
            dx, dy = x - CX, y - CY
            t = min(1.0, math.hypot(dx, dy) / R)
            if t < 0.5:
                k = t / 0.5
                c = tuple(int(C_BG_C[i] + (C_BG_M[i] - C_BG_C[i]) * k) for i in range(3))
            else:
                k = (t - 0.5) / 0.5
                c = tuple(int(C_BG_M[i] + (C_BG_E[i] - C_BG_M[i]) * k) for i in range(3))
            px[x, y] = c
            if x + 1 < D:
                px[x + 1, y] = c
    return img


img = radial_bg().convert("RGBA")
d = ImageDraw.Draw(img, "RGBA")

# Sheen discret haut-gauche (reflet verre)
sheen = Image.new("L", (D, D), 0)
ds = ImageDraw.Draw(sheen)
ds.ellipse([CX - R, CY - R - int(0.55 * D), CX + R, CY + R - int(0.55 * D)], fill=26)
sheen = sheen.filter(ImageFilter.GaussianBlur(R // 3))
white = Image.new("RGBA", (D, D), (255, 255, 255, 255))
img = Image.composite(white, img, sheen.point(lambda v: int(v * 0.35)))

# Anneau verre interne
d = ImageDraw.Draw(img, "RGBA")
d.ellipse([4, 4, D - 5, D - 5], outline=C_RING + (150,), width=4)

# Grandes lignes (calque alpha 92%)
layer = Image.new("RGBA", (D, D), (0, 0, 0, 0))
dl = ImageDraw.Draw(layer)


def centered(drw, cx, top_y, s, font, fill):
    """Centre optique réel via bbox mesurée (bearings asymétriques)."""
    bb = drw.textbbox((0, 0), s, font=font)
    w = bb[2] - bb[0]
    drw.text((cx - w / 2 - bb[0], top_y - bb[1]), s, font=font, fill=fill)


f_big = fit_font(DSEG_BI, HH, int(0.335 * D))
centered(dl, CX, int(0.075 * D), HH, f_big, C_DIGITS + (255,))
centered(dl, CX, int(0.500 * D), MM, f_big, C_DIGITS + (255,))
layer.putalpha(layer.getchannel("A").point(lambda v: int(v * DIGITS_ALPHA / 255)))
img = Image.alpha_composite(img, layer)

# Pastille secondes (par-dessus la jonction)
d = ImageDraw.Draw(img, "RGBA")
pw, ph, pr = int(0.155 * D), int(0.072 * D), int(0.018 * D)
pcx, pcy = CX, int(0.487 * D)
d.rounded_rectangle([pcx - pw // 2, pcy - ph // 2, pcx + pw // 2, pcy + ph // 2],
                    radius=pr, fill=C_DIGITS + (255,))
f_sec = fit_font(DSEG_B, SS, int(0.048 * D))
d.text((pcx, pcy), SS, font=f_sec, fill=C_INK + (255,), anchor="mm")

# Masque circulaire franc + downscale
mask = Image.new("L", (D, D), 0)
ImageDraw.Draw(mask).ellipse([0, 0, D - 1, D - 1], fill=255)
img.putalpha(mask)
img1040 = img.resize((1040, 1040), Image.Resampling.LANCZOS)
m1040 = mask.resize((1040, 1040), Image.Resampling.LANCZOS).point(lambda v: 255 if v > 128 else 0)
img1040.putalpha(m1040)
img1040.save(OUT1040)
img1040.resize((260, 260), Image.Resampling.LANCZOS).save(OUT260)
print("saved", OUT1040, "et", OUT260)
