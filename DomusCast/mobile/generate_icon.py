"""Gera o ícone DomusCast em 1024x1024 PNG."""
from PIL import Image, ImageDraw
import math, os

SIZE = 1024
OUT = os.path.join(os.path.dirname(__file__), "assets", "icon", "icon.png")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

BG    = (15, 52, 120)       # azul escuro
WHITE = (255, 255, 255)
CREAM = (220, 235, 255)     # janelas

img  = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# ── fundo com cantos arredondados ──────────────────────────────────────────
draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=SIZE // 5, fill=BG)

# ── edifício ──────────────────────────────────────────────────────────────
CX = SIZE // 2
# corpo
bw, bh = 360, 260
bx, by = CX - bw // 2, 570
draw.rectangle([bx, by, bx + bw, by + bh], fill=WHITE)

# telhado (triângulo)
roof_y = by - 100
draw.polygon([(CX, roof_y), (bx - 30, by + 6), (bx + bw + 30, by + 6)], fill=WHITE)

# janelas - 3 × 2
win, gap = 60, 22
rows = [(by + 30, by + 30 + win), (by + 30 + win + gap, by + 30 + win + gap + win)]
for wy1, wy2 in rows:
    for col in range(3):
        wx = bx + 40 + col * (win + 38)
        draw.rectangle([wx, wy1, wx + win, wy2], fill=CREAM)

# porta
pw, ph = 64, 100
px = CX - pw // 2
draw.rectangle([px, by + bh - ph, px + pw, by + bh], fill=CREAM)

# ── sinal de broadcast (arcos) ────────────────────────────────────────────
# Ponto central do sinal - no topo do telhado
sx, sy = CX, roof_y - 18
draw.ellipse([sx - 14, sy - 14, sx + 14, sy + 14], fill=WHITE)

for i, r in enumerate([52, 100, 150]):
    w = 14 - i * 2
    # arco de ~200° a 340° (abre para baixo)
    bbox = [sx - r, sy - r, sx + r, sy + r]
    draw.arc(bbox, start=210, end=330, fill=WHITE, width=w)

img = img.convert("RGB")
img.save(OUT, "PNG")
print(f"Ícone guardado em {OUT}")
