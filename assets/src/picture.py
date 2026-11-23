"""Any picture -> a theme background, clean and glass (as demifiend's).

    python picture.py SRC OUT_DIR NAME [--width=1920] [--damp=0.4] [--knee=0.55]
                      [--blur=0.002] [--opacity=0.45] [--kw=#hex] [--str=#hex]

writes NAME.png, NAME-glass.png and a *-preview.png of each (mock code on top,
at --opacity, the theme's bg_opacity; keywords in --kw, strings in --str):
  clean  big bright areas toned down by up to --damp (local brightness, so
         thin bright lines keep their glow), then a soft knee at --knee
  glass  the clean picture lightly blurred (--blur, a fraction of the width)
         like macOS window vibrancy: richer colour, a little lift, grain
--width resizes first (keeps the aspect); 0 keeps the size.
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

args = [a for a in sys.argv[1:] if not a.startswith("--")]
opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
src, out, name = args
WIDTH = int(opts.get("width", 1920))
DAMP = float(opts.get("damp", 0.4))
KNEE = float(opts.get("knee", 0.55))
BLUR = float(opts.get("blur", 0.002))
OPACITY = float(opts.get("opacity", 0.45))
KW, STR = opts.get("kw", "#4a9fe0"), opts.get("str", "#a4cef9")
os.makedirs(out, exist_ok=True)
LUMA = np.array([0.2126, 0.7152, 0.0722], np.float32)

img = Image.open(src).convert("RGB")
if WIDTH and img.width != WIDTH:
    img = img.resize((WIDTH, round(img.height * WIDTH / img.width)), Image.LANCZOS)
W, H = img.size


def arr(im):
    return np.asarray(im).astype(np.float32) / 255


def pil(x):
    return Image.fromarray((np.clip(x, 0, 1) * 255 + 0.5).astype(np.uint8))


def clean(a):
    lum = a @ LUMA
    local = arr(Image.fromarray((lum * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(W / 40)))
    a = a * (1 - DAMP * np.clip((local - 0.2) / 0.4, 0, 1))[..., None]
    lum = a @ LUMA
    comp = np.where(lum > KNEE, KNEE + 0.55 * (1 - KNEE) * np.tanh((lum - KNEE) / (1 - KNEE) * 0.8) / 0.8, lum)
    return a * (comp / np.maximum(lum, 1e-4))[..., None]


def glass(a):
    # blur from a slightly larger canvas, so the edges don't darken
    pad = int(W * 0.06)
    big = np.pad(a, ((pad, pad), (pad, pad), (0, 0)), mode="reflect")
    big = arr(pil(big).filter(ImageFilter.GaussianBlur(W * BLUR)))
    a = big[pad:pad + H, pad:pad + W]
    lum = (a @ LUMA)[..., None]
    a = lum + (a - lum) * 1.45
    a = 0.04 + a * 0.9
    a = np.where(a > 0.7, 0.7 + (a - 0.7) * 0.5, a)
    return a + np.random.default_rng(7).normal(0, 0.012, (H, W, 1)).astype(np.float32)


CODE = """-- pick the palette and repaint every pane
local function load_theme(name)
    local t = themes[name] or themes.default
    for _, pane in ipairs(window:panes()) do
        pane:set_colors(t.colors, { animate = true })
    end
    return string.format("theme: %s (%d panes)", name, #panes)
end""".split("\n")


def preview(res, path):
    shown = pil(arr(res) * OPACITY)
    d = ImageDraw.Draw(shown)
    size = W // 95
    font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", size)
    kw = {"local", "function", "return", "for", "do", "end", "in", "or"}
    for fx, fy in [(0.02, 0.06), (0.02, 0.54), (0.54, 0.18), (0.46, 0.7), (0.32, 0.3)]:
        for i, line in enumerate(CODE):
            x, y = W * fx, H * fy + i * size * 1.5
            if line.strip().startswith("--"):
                d.text((x, y), line, font=font, fill="#949494")
                continue
            for tok in line.replace("(", " ( ").split(" "):
                if tok == "":
                    x += d.textlength(" ", font=font)
                    continue
                c = KW if tok in kw else (STR if '"' in tok else "#ffffff")
                d.text((x, y), tok, font=font, fill=c)
                x += d.textlength(tok + " ", font=font)
    shown.save(path)


base = clean(arr(img))
for n, pic in [(name, base), (name + "-glass", glass(base))]:
    res = pil(pic)
    res.save(os.path.join(out, n + ".png"), optimize=True)
    preview(res, os.path.join(out, n + "-preview.png"))
    print("saved", n)
