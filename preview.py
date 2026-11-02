"""Aperçu du cadran « Big Digits » (FR955, écran rond 260x260).

Reproduit la maquette de référence : 18:44 en quatre cellules 7 segments,
badge de date « 28 » à gauche. Les chiffres sont dessinés en segments,
sans police, pour coller aux proportions de la photo.
"""
from PIL import Image, ImageDraw

W = H = 260
CELL = 116
STROKE = 22
X_LEFT = 11
X_RIGHT = 133
Y_TOP = 12
Y_BOTTOM = 134

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)

img = Image.new("RGB", (W, H), BLACK)
d = ImageDraw.Draw(img)


def seg(x, y, w, h):
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=WHITE)


def big(x, y, digit):
    a = digit in "02356789"
    g = digit in "2345689"
    dd = digit in "0235689"
    f = digit in "045689"
    b = digit in "01234789"
    e = digit in "0268"
    c = digit in "013456789"

    if a:
        seg(x, y, CELL, STROKE)
    if g:
        seg(x, y + 47, CELL, STROKE)
    if dd:
        seg(x, y + 94, CELL, STROKE)
    if f:
        seg(x, y, STROKE, 69)
    if b:
        seg(x + CELL - STROKE, y, STROKE, 69)
    if e:
        seg(x, y + 47, STROKE, 69)
    if c:
        seg(x + CELL - STROKE, y + 47, STROKE, 69)


def one(x, y):
    # Hampe du 1, puis drapeau incliné.
    d.rectangle([x + 59, y + 2, x + 80, y + 94], fill=WHITE)
    d.polygon(
        [(x + 65, y), (x + 80, y), (x + 80, y + 23), (x + 36, y + 23)],
        fill=WHITE,
    )


def mini(x, y, digit):
    w, h, s = 16, 17, 2
    a = digit in "02356789"
    g = digit in "2345689"
    dd = digit in "0235689"
    f = digit in "045689"
    b = digit in "01234789"
    e = digit in "0268"
    c = digit in "013456789"

    if a:
        d.rectangle([x, y, x + w - 1, y + s - 1], fill=WHITE)
    if g:
        d.rectangle([x, y + 7, x + w - 1, y + 7 + s - 1], fill=WHITE)
    if dd:
        d.rectangle([x, y + h - s, x + w - 1, y + h - 1], fill=WHITE)
    if f:
        d.rectangle([x, y, x + s - 1, y + 8], fill=WHITE)
    if b:
        d.rectangle([x + w - s, y, x + w - 1, y + 8], fill=WHITE)
    if e:
        d.rectangle([x, y + 7, x + s - 1, y + h - 1], fill=WHITE)
    if c:
        d.rectangle([x + w - s, y + 7, x + w - 1, y + h - 1], fill=WHITE)


# 18:44
one(X_LEFT, Y_TOP)
big(X_RIGHT, Y_TOP, "8")
big(X_LEFT, Y_BOTTOM, "4")
big(X_RIGHT, Y_BOTTOM, "4")

# Badge de date « 28 ».
d.rounded_rectangle([46, 106, 115, 127], radius=3, fill=WHITE)
d.rectangle([74, 108, 113, 125], fill=BLACK)
mini(77, 108, "2")
mini(95, 108, "8")

# Masque circulaire (l'écran FR955 est rond).
mask = Image.new("L", (W * 4, H * 4), 0)
md = ImageDraw.Draw(mask)
md.ellipse([0, 0, W * 4 - 1, H * 4 - 1], fill=255)
mask = mask.resize((W, H), Image.LANCZOS)
img = Image.composite(img, Image.new("RGB", (W, H), BLACK), mask)

img.save("/home/tasour/Work/big-digits-face/preview-fr955.png")
print("saved preview-fr955.png")
