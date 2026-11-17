"""Parchment backgrounds (gruvbox light + gold linework) for a light wezterm theme.

usage: gen.py OUT_DIR
writes parchment-{astrolabe,frame,celestial}.png (2560x1440) and *-preview.png
(with mock gruvbox code on top, to judge readability).
"""
import math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 2560, 1440
SS = 2  # supersampling for linework
rng = np.random.default_rng(1729)
OUT = sys.argv[1] if len(sys.argv) > 1 else '.'


def hexc(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], np.float32)


BG = hexc("#fbf1c7")      # gruvbox light bg0
BG_SOFT = hexc("#f2e5bc") # bg0_soft
BG_DEEP = hexc("#e6d3a3") # vignette edge
INK = hexc("#b57614")     # gruvbox yellow (dark) as gold ink


def fbm(octaves, base):
    acc = np.zeros((H, W), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        cells = base * 2 ** o
        small = rng.random((max(2, H // cells), max(2, W // cells))).astype(np.float32)
        img = Image.fromarray((small * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
        acc += amp * (np.asarray(img, np.float32) / 255 - 0.5)
        tot += amp
        amp *= 0.55
    return acc / tot


def parchment():
    clouds = fbm(5, 320)                       # broad mottling
    fibers = np.asarray(Image.fromarray(((rng.random((H // 2, W // 8)) * 255).astype(np.uint8)))
                        .resize((W, H), Image.BICUBIC), np.float32) / 255 - 0.5
    grain = rng.normal(0, 1, (H, W)).astype(np.float32)
    col = BG + (BG_SOFT - BG) * np.clip(0.5 + clouds * 2.2, 0, 1)[..., None]
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    d = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
    vig = np.clip((d - 0.55) / 0.85, 0, 1) ** 1.6
    col = col + (BG_DEEP - col) * (0.55 * vig)[..., None]
    col += (fibers * 3.0 + grain * 1.2)[..., None]
    return col


class Ink:
    """linework drawn at 2x on an alpha mask, then tinted gold"""

    def __init__(self):
        self.img = Image.new("L", (W * SS, H * SS), 0)
        self.d = ImageDraw.Draw(self.img)

    def p(self, x, y):
        return (x * SS, y * SS)

    def circle(self, cx, cy, r, w=1.0, a=1.0):
        self.d.ellipse([(cx - r) * SS, (cy - r) * SS, (cx + r) * SS, (cy + r) * SS],
                       outline=int(255 * a), width=max(1, int(w * SS)))

    def dot(self, cx, cy, r, a=1.0):
        self.d.ellipse([(cx - r) * SS, (cy - r) * SS, (cx + r) * SS, (cy + r) * SS], fill=int(255 * a))

    def line(self, pts, w=1.0, a=1.0):
        self.d.line([self.p(x, y) for x, y in pts], fill=int(255 * a), width=max(1, int(w * SS)))

    def poly(self, pts, w=1.0, a=1.0):
        self.line(list(pts) + [pts[0]], w, a)

    def arc(self, cx, cy, r, a0, a1, w=1.0, a=1.0):
        self.d.arc([(cx - r) * SS, (cy - r) * SS, (cx + r) * SS, (cy + r) * SS], a0, a1,
                   fill=int(255 * a), width=max(1, int(w * SS)))

    def mask(self):
        return np.asarray(self.img.resize((W, H), Image.LANCZOS), np.float32) / 255


def compose(base, ink, strength):
    a = (ink.mask() * strength)[..., None]
    out = base * (1 - a) + INK * a
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))


def polar(cx, cy, r, deg):
    t = math.radians(deg)
    return (cx + r * math.cos(t), cy + r * math.sin(t))


# ---------------------------------------------------------------- variants

def astrolabe(ink=None, cx_frac=0.84):
    ink = ink or Ink()
    cx, cy, R = W * cx_frac, H * 0.52, H * 0.66
    for r, w, a in [(R, 2.2, 1), (R * 0.965, 1.2, 0.8), (R * 0.80, 1.6, 0.9), (R * 0.785, 1, 0.6),
                    (R * 0.56, 1.4, 0.85), (R * 0.34, 1.2, 0.7), (R * 0.06, 1.2, 0.8)]:
        ink.circle(cx, cy, r, w, a)
    for k in range(360):                       # degree ticks
        L = 0.035 if k % 30 == 0 else (0.022 if k % 5 == 0 else 0.012)
        ink.line([polar(cx, cy, R * 0.965, k), polar(cx, cy, R * (0.965 - L), k)],
                 1.4 if k % 30 == 0 else 0.9, 0.9 if k % 5 == 0 else 0.6)
    for k in range(12):                        # twelve houses
        ink.line([polar(cx, cy, R * 0.80, k * 30), polar(cx, cy, R * 0.915, k * 30)], 1.0, 0.8)
        mx, my = polar(cx, cy, R * 0.86, k * 30 + 15)
        ink.circle(mx, my, R * 0.022, 1.0, 0.8)
        ink.dot(mx, my, R * 0.006, 0.9)
    star = [polar(cx, cy, R * (0.56 if i % 2 == 0 else 0.25), i * 22.5 - 90) for i in range(16)]
    ink.poly(star, 1.2, 0.85)                  # eight-pointed star
    for off in (0, 45):
        sq = [polar(cx, cy, R * 0.34, off + 90 * i) for i in range(4)]
        ink.poly(sq, 1.0, 0.6)
    ex, ey = polar(cx, cy, R * 0.16, 200)      # rete / ecliptic, off-centre
    ink.circle(ex, ey, R * 0.62, 1.2, 0.75)
    for k in range(24):                        # rete pointers
        ink.line([polar(ex, ey, R * 0.62, k * 15), polar(ex, ey, R * 0.65, k * 15)], 1.0, 0.6)
    for deg in (-75, -40, 10, 55, 100):        # a few stars caught in the rete
        sx, sy = polar(cx, cy, R * 0.68, deg)
        ink.dot(sx, sy, 3.2, 0.9)
    ink.line([polar(cx, cy, R * 1.05, 200), polar(cx, cy, R * 0.06, 200)], 1.6, 0.85)  # alidade
    return ink, 0.46


def frame(ink=None):
    ink = ink or Ink()
    m = 34
    for inset, w, a in [(m, 1.8, 1), (m + 12, 0.9, 0.7)]:
        ink.poly([(inset, inset), (W - inset, inset), (W - inset, H - inset), (inset, H - inset)], w, a)
    for sx, sy in [(1, 1), (-1, 1), (1, -1), (-1, -1)]:   # corner flourishes
        ox = m if sx > 0 else W - m
        oy = m if sy > 0 else H - m
        for r, a in [(120, 0.9), (96, 0.6), (72, 0.45)]:
            start = {(1, 1): 0, (-1, 1): 90, (-1, -1): 180, (1, -1): 270}[(sx, sy)]
            ink.arc(ox, oy, r, start, start + 90, 1.2, a)
        d = 46
        ink.poly([(ox + sx * d, oy), (ox + sx * (d + 14), oy + sy * 14), (ox + sx * d, oy + sy * 28),
                  (ox + sx * (d - 14), oy + sy * 14)], 1.0, 0.8)
        ink.dot(ox + sx * 14, oy + sy * 14, 4, 0.9)
        for k in range(1, 5):
            ink.dot(ox + sx * (140 + k * 26), oy + sy * 6, 1.8, 0.7)
            ink.dot(ox + sx * 6, oy + sy * (140 + k * 26), 1.8, 0.7)

    def emblem(x, y, horizontal):
        s = 18
        ink.poly([(x, y - s), (x + s, y), (x, y + s), (x - s, y)], 1.2, 0.9)
        ink.poly([(x, y - s / 2), (x + s / 2, y), (x, y + s / 2), (x - s / 2, y)], 1.0, 0.7)
        L = 180
        if horizontal:
            ink.line([(x - s - L, y), (x - s - 6, y)], 1.0, 0.7)
            ink.line([(x + s + 6, y), (x + s + L, y)], 1.0, 0.7)
            ink.arc(x - s - L - 10, y, 10, 0, 360, 1.0, 0.6)
            ink.arc(x + s + L + 10, y, 10, 0, 360, 1.0, 0.6)
        else:
            ink.line([(x, y - s - L), (x, y - s - 6)], 1.0, 0.7)
            ink.line([(x, y + s + 6), (x, y + s + L)], 1.0, 0.7)

    emblem(W / 2, m, True)
    emblem(W / 2, H - m, True)
    emblem(m, H / 2, False)
    emblem(W - m, H / 2, False)
    return ink, 0.50


def celestial(ink=None):
    ink = ink or Ink()
    cx, cy = W * 0.80, H * 0.46
    for (rx, ry, rot, a) in [(780, 300, -18, 0.7), (620, 230, 24, 0.55), (980, 380, 8, 0.45)]:
        pts = []
        for k in range(361):
            t = math.radians(k)
            x, y = rx * math.cos(t), ry * math.sin(t)
            r = math.radians(rot)
            pts.append((cx + x * math.cos(r) - y * math.sin(r), cy + x * math.sin(r) + y * math.cos(r)))
        ink.line(pts, 1.1, a)
    ink.circle(cx, cy, 34, 1.4, 0.9)
    ink.circle(cx, cy, 12, 1.0, 0.8)
    constellations = [
        [(0.64, 0.16), (0.69, 0.11), (0.74, 0.14), (0.78, 0.09), (0.83, 0.13)],
        [(0.90, 0.24), (0.94, 0.30), (0.91, 0.37), (0.96, 0.42)],
        [(0.62, 0.72), (0.67, 0.68), (0.70, 0.75), (0.75, 0.71), (0.73, 0.64), (0.67, 0.68)],
        [(0.86, 0.66), (0.90, 0.60), (0.95, 0.63)],
    ]
    for c in constellations:
        pts = [(x * W, y * H) for x, y in c]
        ink.line(pts, 1.0, 0.65)
        for i, (x, y) in enumerate(pts):
            ink.dot(x, y, 4.5 if i % 2 == 0 else 3.2, 0.95)
    for _ in range(140):                       # dust of faint stars on the right half
        x, y = W * (0.55 + 0.45 * rng.random()), H * rng.random()
        ink.dot(x, y, 1.2 + 1.6 * rng.random() ** 3, 0.35 + 0.4 * rng.random())
    rx, ry, R = W * 0.93, H * 0.84, 120        # compass rose
    for k in range(8):
        r = R if k % 2 == 0 else R * 0.55
        tip = polar(rx, ry, r, k * 45 - 90)
        l = polar(rx, ry, R * 0.14, k * 45 - 90 - 90)
        rr = polar(rx, ry, R * 0.14, k * 45 - 90 + 90)
        ink.poly([tip, l, (rx, ry), rr], 1.1, 0.85)
    ink.circle(rx, ry, R * 0.78, 1.0, 0.6)
    ink.circle(rx, ry, R * 0.72, 0.8, 0.45)
    return ink, 0.48


# ---------------------------------------------------------------- preview

CODE = """local function load_theme(name)
    -- pick the palette and repaint every pane
    local t = themes[name] or themes.default
    for _, pane in ipairs(window:panes()) do
        pane:set_colors(t.colors, { animate = true })
    end
    return string.format("theme: %s (%d panes)", name, #panes)
end""".split("\n")


def preview(img, path):
    im = img.copy()
    d = ImageDraw.Draw(im)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 30)
    except OSError:
        font = ImageFont.load_default()
    kw = {"local", "function", "return", "for", "do", "end", "in", "or"}
    colors = {"kw": "#9d0006", "str": "#79740e", "com": "#928374", "fn": "#427b58", "txt": "#3c3836"}
    lh = 46
    for block, (x0, y0) in enumerate([(80, 120), (80, 620), (1250, 420)]):
        for i, line in enumerate(CODE):
            x, y = x0, y0 + i * lh
            if line.strip().startswith("--"):
                d.text((x, y), line, font=font, fill=colors["com"])
                continue
            for tok in line.replace("(", " ( ").split(" "):
                if tok == "":
                    x += d.textlength(" ", font=font)
                    continue
                c = colors["kw"] if tok in kw else (colors["str"] if '"' in tok else colors["txt"])
                d.text((x, y), tok, font=font, fill=c)
                x += d.textlength(tok + " ", font=font)
    im.save(path)


if __name__ == '__main__':
  os.makedirs(OUT, exist_ok=True)
  base = parchment()
  for name, fn in [("astrolabe", astrolabe), ("frame", frame), ("celestial", celestial)]:
    ink, strength = fn()
    img = compose(base, ink, strength)
    img.save(os.path.join(OUT, f"parchment-{name}.png"), optimize=True)
    preview(img, os.path.join(OUT, f"parchment-{name}-preview.png"))
    print("done", name)
