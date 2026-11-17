"""Turn a dark artwork into a high-key parchment print for a gruvbox-light theme.

usage: ml.py SRC OUT_DIR
variants:
  wash    tones squeezed into bg1..bg0, fire kept as soft gold
  fade    like wash, but the left part (where code usually is) fades to plain parchment
  strong  wider tonal range (bg2..bg0) and brighter fire: more art, less calm
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
im = Image.open(src).convert("RGB")
W, H = im.size
rgb = np.asarray(im).astype(np.float32) / 255
hsv = np.asarray(im.convert("HSV")).astype(np.float32) / 255
h, s, v = hsv[..., 0] * 360, hsv[..., 1], hsv[..., 2]
lum = rgb @ np.array([0.299, 0.587, 0.114], np.float32)


def hexc(x):
    return np.array([int(x[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255


BG0, BG1, BG2 = hexc("#fbf1c7"), hexc("#ebdbb2"), hexc("#d5c4a1")
GOLD, ORANGE = hexc("#d79921"), hexc("#d65d0e")

# fire / glow: warm, saturated, bright
fire = (np.clip((s - 0.35) / 0.3, 0, 1) * np.clip((v - 0.45) / 0.3, 0, 1)
        * np.clip(1 - np.abs(h - 32) / 28, 0, 1))
fire = np.asarray(Image.fromarray((fire * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2)),
                  np.float32) / 255
fire_col = GOLD + (ORANGE - GOLD) * np.clip((0.85 - v) / 0.4, 0, 1)[..., None]

grain = np.random.default_rng(3).normal(0, 0.006, (H, W, 1)).astype(np.float32)


def tone(dark, light, fire_k, gamma=0.85):
    t = np.clip(lum, 0, 1) ** gamma
    base = dark + (light - dark) * t[..., None]
    a = (fire * fire_k)[..., None]
    return base * (1 - a) + fire_col * a + grain


def fade_left(img, start=0.08, end=0.55, floor=0.25):
    x = np.linspace(0, 1, W, dtype=np.float32)
    k = floor + (1 - floor) * np.clip((x - start) / (end - start), 0, 1)
    k = k * k * (3 - 2 * k)
    return BG0 + (img - BG0) * k[None, :, None]


variants = {
    "wash": tone(BG1, BG0, 0.45),
    "fade": fade_left(tone(BG1, BG0, 0.5)),
    "strong": tone(BG2, BG0, 0.6, gamma=0.75),
}

CODE = """local function load_theme(name)
    -- pick the palette and repaint every pane
    local t = themes[name] or themes.default
    for _, pane in ipairs(window:panes()) do
        pane:set_colors(t.colors, { animate = true })
    end
    return string.format("theme: %s (%d panes)", name, #panes)
end""".split("\n")


def preview(img, path):
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 30)
    kw = {"local", "function", "return", "for", "do", "end", "in", "or"}
    for x0, y0 in [(80, 120), (80, 620), (1250, 420), (1250, 980)]:
        for i, line in enumerate(CODE):
            x, y = x0, y0 + i * 46
            if line.strip().startswith("--"):
                d.text((x, y), line, font=font, fill="#928374")
                continue
            for tok in line.replace("(", " ( ").split(" "):
                if tok == "":
                    x += d.textlength(" ", font=font)
                    continue
                c = "#9d0006" if tok in kw else ("#79740e" if '"' in tok else "#3c3836")
                d.text((x, y), tok, font=font, fill=c)
                x += d.textlength(tok + " ", font=font)
    img.save(path)


for name, arr in variants.items():
    img = Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8))
    img.save(os.path.join(out, f"metaphor-light-{name}.png"), optimize=True)
    preview(img.copy(), os.path.join(out, f"metaphor-light-{name}-preview.png"))
    print("done", name)


# ---- second round: keep the silhouette readable inside the narrow light range
lo, hi = np.percentile(lum, 2), np.percentile(lum, 98)
stretched = np.clip((lum - lo) / (hi - lo), 0, 1)
# local contrast: subtract a heavy blur so shapes survive the squeeze
blur = np.asarray(Image.fromarray((stretched * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(40)),
                  np.float32) / 255
local = np.clip(0.5 + (stretched - blur) * 1.6, 0, 1)
mix = 0.55 * stretched + 0.45 * local
BG15 = (BG1 + BG2) / 2

def tone2(m, dark, light, fire_k):
    base = dark + (light - dark) * (m ** 0.9)[..., None]
    a = (fire * fire_k)[..., None]
    return base * (1 - a) + fire_col * a + grain

# etching: difference of gaussians as ink lines over a faint wash
g1 = np.asarray(Image.fromarray((stretched * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2)), np.float32) / 255
g2 = np.asarray(Image.fromarray((stretched * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(4)), np.float32) / 255
lines = np.clip((g2 - g1) * 7, 0, 1) ** 0.8          # dark edges
INK = hexc("#7c6f64")
wash = tone2(stretched, BG1, BG0, 0.0)
etch = wash * (1 - 0.55 * lines[..., None]) + INK * (0.55 * lines[..., None])
a = (fire * 0.5)[..., None]
etch = etch * (1 - a) + fire_col * a

for name, arr in {"balanced": tone2(mix, BG15, BG0, 0.5), "etch": etch}.items():
    img = Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8))
    img.save(os.path.join(out, f"metaphor-light-{name}.png"), optimize=True)
    preview(img.copy(), os.path.join(out, f"metaphor-light-{name}-preview.png"))
    print("done", name)
