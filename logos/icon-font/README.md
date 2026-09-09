# Galaaz Omarchy menu icon font

Private TrueType font (`family: galaaz`) with one private-use glyph:

| Codepoint | Name | Role |
|-----------|------|------|
| `U+E900` | `galaaz` | Monochrome R + gem cutout for Install menu rows |

## Sources

| File | Role |
|------|------|
| `galaaz-mark.svg` | Editable monochrome silhouette (straight segments) |
| `build_font.py` | Builds `../../script/omarchy/fonts/galaaz.ttf` (needs `fonttools`) |
| `../../script/omarchy/fonts/galaaz.ttf` | Shipped with the Omarchy overlay |

Rebuild after editing the SVG:

```bash
python3 -m venv /tmp/galaaz-font-venv
/tmp/galaaz-font-venv/bin/pip install fonttools
/tmp/galaaz-font-venv/bin/python logos/icon-font/build_font.py
```

`galaaz omarchy` installs the TTF to `~/.local/share/fonts/galaaz/` and the menu
uses `"iconFont": "galaaz"`. Restart the Omarchy shell after install so Qt
reloads fonts (`omarchy menu refresh` alone is not enough for a new family).
