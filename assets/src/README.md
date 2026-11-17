# Background generators

Scripts that produced the theme backgrounds in `assets/`. They need Python with
`numpy` and `pillow` (a throwaway venv is fine), plus Menlo for the code previews (macOS).

| Script | Output | Notes |
|---|---|---|
| `recolor_gold.py SRC OUT` | `aegis-gold.png` | lavender Aegis -> Metaphor-like gold |
| `light_from_art.py SRC OUT_DIR` | `metaphor-light-*.png` | dark artwork -> high-key parchment print; the `strong` variant is the base |
| `light_ornate.py BASE OUT_DIR` | `*-ornate.png` + `frame-*.png` | astrolabe (left) + celestial map (right) over the base = `metaphor-light1.png`; the frame is a separate transparent overlay = `frame-metaphor-light.png`, stretched to the window so it is never cropped and clears the tab bar |
| `parchment.py [OUT_DIR]` | `parchment-*.png` | procedural parchment + linework; also the module `light_ornate.py` imports |

Every script also writes `*-preview.png` with mock gruvbox code on top, to check
readability before using a background.
