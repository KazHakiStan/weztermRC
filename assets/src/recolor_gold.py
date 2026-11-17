"""Recolor aegis-lavender.png into a Metaphor-like gold palette."""
import colorsys, sys
import numpy as np
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
rgb = np.asarray(Image.open(src).convert("RGB")).astype(np.float32) / 255
hsv = np.asarray(Image.open(src).convert("HSV")).astype(np.float32) / 255
h, s, v = hsv[..., 0] * 360, hsv[..., 1], hsv[..., 2]
lum = rgb @ np.array([0.299, 0.587, 0.114], np.float32)

def hexrgb(x):
    return np.array([int(x[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255

# greys -> warm gradient map (black -> umber -> parchment -> warm white)
stops = [(0.0, "#000000"), (0.25, "#2b2112"), (0.55, "#8c7a58"), (0.8, "#d9c9a3"), (1.0, "#fff7e6")]
xs = np.array([p for p, _ in stops], np.float32)
cols = np.stack([hexrgb(c) for _, c in stops])
warm = np.stack([np.interp(lum, xs, cols[:, i]) for i in range(3)], axis=-1)
grey = 0.55 * warm + 0.45 * lum[..., None]   # keep some neutral grey for detail

def recolor(hue_deg, sat_mul, val_mul):
    hh = np.full_like(h, hue_deg / 360)
    ss = np.clip(s * sat_mul, 0, 1)
    vv = np.clip(v * val_mul, 0, 1)
    img = Image.fromarray((np.stack([hh, ss, vv], -1) * 255).astype(np.uint8), "HSV").convert("RGB")
    return np.asarray(img).astype(np.float32) / 255

gold = recolor(39, 1.35, 1.0)         # lavender -> rich amber gold
champagne = recolor(46, 0.45, 1.1)    # cyan -> pale champagne gold

lav_w = np.clip(1 - np.abs(h - 275) / 40, 0, 1)
cyan_w = np.clip(1 - np.abs(h - 195) / 50, 0, 1)
accent = (gold * lav_w[..., None] + champagne * cyan_w[..., None]) / np.maximum(lav_w + cyan_w, 1e-6)[..., None]
w = (np.clip((s - 0.12) / 0.2, 0, 1) * np.clip(lav_w + cyan_w, 0, 1))[..., None]
res = grey * (1 - w) + accent * w
Image.fromarray((np.clip(res, 0, 1) * 255 + 0.5).astype(np.uint8)).save(out, optimize=True)
print("saved", out)
