"""The Illusive Man before his star (Mass Effect 2), Paragon blue -> terminal background.

    python illusive_man.py SRC OUT_DIR [--blur=0.002]

The star fills the middle and is very bright: the big bright areas are toned
down (local brightness, as demifiend's clean picture), the silhouette and the
stars around stay. Writes illusive-man.png and illusive-man-glass.png (lightly
blurred like macOS window vibrancy, as demifiend-glass), each with a
*-preview.png (mock code on top, at OPACITY, default 0.5 as the theme).
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

args = [a for a in sys.argv[1:] if not a.startswith("--")]
src, out = args[0], args[1]
# glass blur radius, a fraction of the width (--blur=)
BLUR = next((float(a.split("=")[1]) for a in sys.argv if a.startswith("--blur=")), 0.002)
os.makedirs(out, exist_ok=True)
LUMA = np.array([0.2126, 0.7152, 0.0722], np.float32)

img = Image.open(src).convert("RGB")
W, H = img.size
a = np.asarray(img).astype(np.float32) / 255


def pil(x):
    return Image.fromarray((np.clip(x, 0, 1) * 255 + 0.5).astype(np.uint8))


# the star: wherever the neighbourhood is bright, bring it down (up to ~40%)
lum = a @ LUMA
local = np.asarray(Image.fromarray((lum * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(W / 40)))
local = local.astype(np.float32) / 255
a = a * (1 - 0.4 * np.clip((local - 0.2) / 0.4, 0, 1))[..., None]
# soft knee on what is left
lum = a @ LUMA
knee = 0.55
comp = np.where(lum > knee, knee + 0.55 * (1 - knee) * np.tanh((lum - knee) / (1 - knee) * 0.8) / 0.8, lum)
a = a * (comp / np.maximum(lum, 1e-4))[..., None]


def glass(x):
    # blur from a slightly larger canvas, so the edges don't darken
    pad = int(W * 0.06)
    big = np.pad(x, ((pad, pad), (pad, pad), (0, 0)), mode="reflect")
    big = np.asarray(pil(big).filter(ImageFilter.GaussianBlur(W * BLUR))).astype(np.float32) / 255
    x = big[pad:pad + H, pad:pad + W]
    # vibrancy: colour pushed up, highlights softened, a little lift in the darks
    lum = (x @ LUMA)[..., None]
    x = lum + (x - lum) * 1.45
    x = 0.04 + x * 0.9
    x = np.where(x > 0.7, 0.7 + (x - 0.7) * 0.5, x)
    return x + np.random.default_rng(7).normal(0, 0.012, (H, W, 1)).astype(np.float32)


# ---------------------------------------------------------------- preview
OPACITY = float(os.environ.get("OPACITY", "0.5"))
CODE = """-- pick the palette and repaint every pane
local function load_theme(name)
    local t = themes[name] or themes.default
    for _, pane in ipairs(window:panes()) do
        pane:set_colors(t.colors, { animate = true })
    end
    return string.format("theme: %s (%d panes)", name, #panes)
end""".split("\n")
FG, KW, STR, COMMENT = "#ffffff", "#4a9fe0", "#a4cef9", "#949494"


def preview(res, path):
    shown = Image.fromarray((np.asarray(res).astype(np.float32) * OPACITY + 0.5).astype(np.uint8))
    d = ImageDraw.Draw(shown)
    size = W // 95
    font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", size)
    kw = {"local", "function", "return", "for", "do", "end", "in", "or"}
    for fx, fy in [(0.02, 0.06), (0.02, 0.54), (0.54, 0.18), (0.46, 0.7), (0.32, 0.3)]:
        for i, line in enumerate(CODE):
            x, y = W * fx, H * fy + i * size * 1.5
            if line.strip().startswith("--"):
                d.text((x, y), line, font=font, fill=COMMENT)
                continue
            for tok in line.replace("(", " ( ").split(" "):
                if tok == "":
                    x += d.textlength(" ", font=font)
                    continue
                c = KW if tok in kw else (STR if '"' in tok else FG)
                d.text((x, y), tok, font=font, fill=c)
                x += d.textlength(tok + " ", font=font)
    shown.save(path)


for name, pic in [("illusive-man", a), ("illusive-man-glass", glass(a))]:
    res = pil(pic)
    res.save(os.path.join(out, name + ".png"), optimize=True)
    preview(res, os.path.join(out, name + "-preview.png"))
    print("saved", name)
