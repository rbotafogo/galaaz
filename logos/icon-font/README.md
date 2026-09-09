# Galaaz Omarchy menu icon font

Private TrueType font (`family: galaaz`) with one private-use glyph:

| Codepoint | Name | Role |
|-----------|------|------|
| `U+E90E` | `galaaz` | R + gem in **family omarchy** (`omarchy-with-galaaz.ttf`) |

Menu rows must use `"iconFont": "omarchy"` (not `"galaaz"`). Qt already loads
the Omarchy brand family; a custom family alone renders as missing-glyph tofu.

Do **not** reuse `U+E900`–`U+E90D` — Omarchy's private font already maps those
(waybar logo is `\ue900`).

## Sources

| File | Role |
|------|------|
| `galaaz-mark.svg` | Editable monochrome silhouette (straight segments) |
| `build_font.py` | Builds `../../script/omarchy/fonts/galaaz.ttf` (needs `fonttools`) |
| `../../script/omarchy/fonts/galaaz.ttf` | Shipped with the Omarchy overlay |

Rebuild after editing the SVG:

```bash
python3 -m venv /tmp/galaaz-font-venv
/tmp/galaaz-font-venv/bin/pip install fonttools pillow
/tmp/galaaz-font-venv/bin/python logos/icon-font/build_font.py
```

The build writes `preview/glyph_{16,24,48}.png` and **fails** if the gem
cutout is too small for menu size. Inspect those PNGs before shipping.

`galaaz omarchy` installs the TTF to `~/.local/share/fonts/galaaz/` and the menu
uses `"iconFont": "galaaz"`. Restart the Omarchy shell after install so Qt
reloads fonts (`omarchy menu refresh` alone is not enough for a new family).
