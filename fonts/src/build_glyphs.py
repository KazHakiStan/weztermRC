"""Build KazGlyphs.ttf: custom status-bar glyphs for wezterm (tabbar.lua).

    fontforge -lang=py -script fonts/src/build_glyphs.py

Glyphs live in Supplementary Private Use Area-B (U+100000...), which Nerd Fonts
do not use. Metrics follow JetBrains Mono (1000 upm, 600 advance) so a glyph
fits one terminal cell.

U+100000..U+10000B  tarot card spinning around its vertical axis (12 frames, 30 deg)
                    front: outlined card with a four-pointed star (P5 calling card)
                    back:  solid card with a diamond cut out
"""
import math
import os

import fontforge

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "KazGlyphs.ttf")

ADVANCE = 600
CX = ADVANCE / 2
CARD_W = 440          # front-facing width
CARD_H = 760
CARD_Y0 = -50         # bottom (baseline-relative)
BORDER = 70
CORNER = 70
PERSPECTIVE = 0.10    # near edge grows, far edge shrinks while turning
EDGE_MIN = 46         # card seen edge-on is still a visible sliver
FRAMES = 12
BASE_CP = 0x100000


def rounded_rect(hw, hh, r, steps=6):
    """points of a rounded rectangle centred at 0, in card space (-hw..hw, -hh..hh)"""
    pts = []
    corners = [(hw - r, hh - r, 0), (-hw + r, hh - r, 90), (-hw + r, -hh + r, 180), (hw - r, -hh + r, 270)]
    for cx, cy, start in corners:
        for s in range(steps + 1):
            a = math.radians(start + 90 * s / steps)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def star4(r_out, r_in):
    pts = []
    for k in range(8):
        a = math.radians(90 + 45 * k)
        r = r_out if k % 2 == 0 else r_in
        pts.append((r * math.cos(a), r * math.sin(a)))
    return pts


def diamond(rx, ry):
    return [(0, ry), (-rx, 0), (0, -ry), (rx, 0)]


def project(pts, theta):
    """card space -> glyph space for a card rotated by theta around the vertical axis"""
    c, s = math.cos(theta), math.sin(theta)
    half_w = max(abs(c) * CARD_W / 2, EDGE_MIN / 2)
    hw0 = CARD_W / 2
    out = []
    for u, v in pts:
        un = u / hw0                       # -1..1 across the card
        x = CX + un * half_w
        # perspective: the edge turning towards the viewer gets taller
        scale = 1 + PERSPECTIVE * s * un * (1 if c >= 0 else -1)
        y = CARD_Y0 + CARD_H / 2 + v * scale
        out.append((x, y))
    return out


def draw(pen, pts):
    pen.moveTo(pts[0])
    for p in pts[1:]:
        pen.lineTo(p)
    pen.closePath()


def card_frame(glyph, theta):
    hw, hh = CARD_W / 2, CARD_H / 2
    front = math.cos(theta) >= 0
    pen = glyph.glyphPen()
    outer = rounded_rect(hw, hh, CORNER)
    draw(pen, project(outer, theta))
    if abs(math.cos(theta)) > 0.2:   # edge-on: just the solid sliver
        if front:
            inner = rounded_rect(hw - BORDER, hh - BORDER, max(CORNER - BORDER / 2, 10))
            draw(pen, project(inner[::-1], theta))           # hole -> outline card
            draw(pen, project(star4(190, 62), theta))        # star on the face
        else:
            draw(pen, project(diamond(110, 190)[::-1], theta))  # diamond cut into the back
    pen = None
    glyph.width = ADVANCE
    glyph.correctDirection()
    glyph.removeOverlap()


def main():
    font = fontforge.font()
    font.familyname = font.fontname = "KazGlyphs"
    font.fullname = "KazGlyphs Regular"
    # em = ascent + descent in fontforge, so keep them summing to 1000;
    # JetBrains Mono's 1020/300 are line metrics, set below
    font.ascent, font.descent = 800, 200
    font.em = 1000
    # explicit line metrics: by default fontforge derives them from the glyph
    # bounding boxes, and wezterm then scales the whole fallback font down
    font.hhea_ascent_add = font.hhea_descent_add = False
    font.os2_typoascent_add = font.os2_typodescent_add = False
    font.os2_winascent_add = font.os2_windescent_add = False
    font.hhea_ascent, font.hhea_descent, font.hhea_linegap = 1020, -300, 0
    font.os2_typoascent, font.os2_typodescent, font.os2_typolinegap = 1020, -300, 0
    font.os2_winascent, font.os2_windescent = 1020, 300
    font.encoding = "UnicodeFull"

    space = font.createChar(0x20, "space")
    space.width = ADVANCE

    for i in range(FRAMES):
        theta = 2 * math.pi * i / FRAMES
        g = font.createChar(BASE_CP + i, "card%02d" % i)
        card_frame(g, theta)

    font.generate(OUT)
    print("wrote", os.path.normpath(OUT), "frames:", FRAMES)


main()
