"""Gold linework for the metaphor-light theme.

usage: light_ornate.py BASE.png OUT_DIR

Writes two files, because the window rarely has the picture's aspect ratio:
  <base>-ornate.png   artwork + astrolabe (left) + celestial map (right);
                      shown with Cover, so its edges may be cropped
  frame-<base>.png    transparent overlay with only the frame; stretched to the
                      window (100% x 100%), so the frame always sits at the edges.
                      Leaves room at the bottom for the tab bar.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from PIL import Image
import parchment as gen

TAB_BAR = 0.03  # share of the height kept free for the bottom tab bar

base_path, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
stem = os.path.splitext(os.path.basename(base_path))[0]
base = np.asarray(Image.open(base_path).convert("RGB"), np.float32)
assert base.shape[:2] == (gen.H, gen.W), base.shape

# artwork + astrolabe + celestial
alpha = np.zeros(base.shape[:2], np.float32)
ink, _ = gen.astrolabe(cx_frac=0.13)   # mirrored to the left edge
alpha = np.maximum(alpha, ink.mask() * 0.40)
ink, _ = gen.celestial()               # stays on the right
alpha = np.maximum(alpha, ink.mask() * 0.42)
a = alpha[..., None]
art = Image.fromarray(np.clip(base * (1 - a) + gen.INK * a, 0, 255).astype(np.uint8))
art.save(os.path.join(out, stem + "-ornate.png"), optimize=True)

# frame overlay: drawn full size, squeezed upwards to clear the tab bar
ink, _ = gen.frame()
m = Image.fromarray((np.clip(ink.mask() * 0.46, 0, 1) * 255).astype(np.uint8))
h = round(gen.H * (1 - TAB_BAR))
mask = Image.new("L", (gen.W, gen.H), 0)
mask.paste(m.resize((gen.W, h), Image.LANCZOS), (0, 0))
rgba = Image.new("RGBA", (gen.W, gen.H), tuple(int(c) for c in gen.INK) + (0,))
rgba.putalpha(mask)
rgba.save(os.path.join(out, "frame-" + stem + ".png"), optimize=True)

# preview: frame over art at the picture's own size
prev = art.convert("RGBA")
prev.alpha_composite(rgba)
gen.preview(prev.convert("RGB"), os.path.join(out, stem + "-ornate-preview.png"))
print("done", stem)
