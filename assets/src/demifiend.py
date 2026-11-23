"""Demi-fiend (SMT V: Vengeance) picture -> terminal backgrounds.

    python demifiend.py SRC OUT_DIR [--upscale] [--blur=0.002]

writes two pictures plus a *-preview.png of each with mock code on top:
  demifiend.png        clean: the big bright patches (lit windows, the floor's
                       sheen) toned down so text over them reads, while thin
                       glowing lines (the markings, the eyes) stay bright
  demifiend-glass.png  frosted glass, like macOS window vibrancy: blur
                       (--blur=, a fraction of the width), richer colour, grain

--upscale is for small, compressed sources (e.g. a 1400x700 AVIF frame:
`magick x.avif src.png` first): smooths the compression blocks, 2x upscale.
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

args = [a for a in sys.argv[1:] if not a.startswith("--")]
# glass blur radius, a fraction of the width (--blur=): light, so he and his eyes read
BLUR = next((float(a.split("=")[1]) for a in sys.argv if a.startswith("--blur=")), 0.002)
src, out = args[0], args[1]
os.makedirs(out, exist_ok=True)
LUMA = np.array([0.2126, 0.7152, 0.0722], np.float32)

img = Image.open(src).convert("RGB")
if "--upscale" in sys.argv:
    img = img.filter(ImageFilter.GaussianBlur(0.9))
    img = img.resize((img.width * 2, img.height * 2), Image.LANCZOS)
    img = img.filter(ImageFilter.UnsharpMask(radius=2.5, percent=60, threshold=2))
W, H = img.size
rng = np.random.default_rng(7)


def arr(im):
    return np.asarray(im).astype(np.float32) / 255


def pil(a):
    return Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8))


def vignette(a, strength=0.35):
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H * 0.55) / (H / 2)) ** 2)
    return a * (1 - strength * np.clip((r - 0.55) / 0.8, 0, 1) ** 1.5)[..., None]


def grain(a, sigma):
    return a + rng.normal(0, sigma, (H, W, 1)).astype(np.float32)


def clean(a):
    # local brightness: large bright areas hurt readability; thin lines barely
    # move the local average, so they keep their glow
    lum = a @ LUMA
    local = arr(Image.fromarray((lum * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(W / 40)))
    a = a * (1 - 0.55 * np.clip((local - 0.18) / 0.35, 0, 1))[..., None]
    # soft knee on what is left: nothing brighter than ~0.85
    lum = a @ LUMA
    knee = 0.6
    comp = np.where(lum > knee, knee + 0.6 * (1 - knee) * np.tanh((lum - knee) / (1 - knee) * 0.7) / 0.7, lum)
    a = a * (comp / np.maximum(lum, 1e-4))[..., None]
    return grain(vignette(a), 0.006)


def glass(a):
    # blur from a slightly larger canvas, so the edges don't darken
    pad = int(W * 0.06)
    big = np.pad(a, ((pad, pad), (pad, pad), (0, 0)), mode="reflect")
    big = arr(pil(big).filter(ImageFilter.GaussianBlur(W * BLUR)))
    a = big[pad:pad + H, pad:pad + W]
    # vibrancy: colour pushed up, highlights softened, a little lift in the darks
    lum = (a @ LUMA)[..., None]
    a = lum + (a - lum) * 1.45
    a = 0.04 + a * 0.9
    a = np.where(a > 0.7, 0.7 + (a - 0.7) * 0.5, a)
    return grain(a, 0.012)


# ---------------------------------------------------------------- preview
# as WezTerm shows it: black, the picture at bg_opacity, theme colours on top
OPACITY = float(os.environ.get("OPACITY", "0.65"))
CODE = """-- pick the palette and repaint every pane
local function load_theme(name)
    local t = themes[name] or themes.default
    for _, pane in ipairs(window:panes()) do
        pane:set_colors(t.colors, { animate = true })
    end
    return string.format("theme: %s (%d panes)", name, #panes)
end""".split("\n")
FG, KW, STR, COMMENT = "#ffffff", "#35b88a", "#d8e070", "#949494"


def preview(im, path):
    shown = pil(arr(im) * OPACITY)
    d = ImageDraw.Draw(shown)
    size = max(12, W // 95)
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


base = arr(img)
for name, fn in [("demifiend", clean), ("demifiend-glass", glass)]:
    res = pil(fn(base.copy()))
    res.save(os.path.join(out, name + ".png"), optimize=True)
    preview(res, os.path.join(out, name + "-preview.png"))
    print("saved", name)
