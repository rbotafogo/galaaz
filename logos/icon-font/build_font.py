#!/usr/bin/env python3
"""Build script/omarchy/fonts/galaaz.ttf from logos/icon-font/galaaz-mark.svg."""
from __future__ import annotations

import re
import sys
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.misc.transform import Transform
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import SVGPath
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._g_l_y_f import Glyph as TTGlyph
from fontTools.ttLib.tables._g_l_y_f import GlyphCoordinates
from fontTools.ttLib.tables._g_l_y_f import flagOnCurve

ROOT = Path(__file__).resolve().parents[2]
SVG = ROOT / "logos" / "icon-font" / "galaaz-mark.svg"
OUT = ROOT / "script" / "omarchy" / "fonts" / "galaaz.ttf"
CODEPOINT = 0xE900


def extract_path_d(svg_text: str) -> str:
    m = re.search(r'<path[^>]*\sd="([^"]+)"', svg_text, re.DOTALL)
    if not m:
        raise SystemExit("no <path d=...> in SVG")
    return re.sub(r"\s+", " ", m.group(1)).strip()


def signed_area(pts) -> float:
    a = 0.0
    n = len(pts)
    for i in range(n):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % n]
        a += x1 * y2 - x2 * y1
    return 0.5 * a


def fix_hole_windings(glyph: TTGlyph) -> None:
    """TrueType: outer CW (area < 0), holes CCW (area > 0)."""
    if glyph.numberOfContours <= 0:
        return
    coords = list(glyph.coordinates)
    ends = list(glyph.endPtsOfContours)
    flags = list(glyph.flags)
    start = 0
    new_coords = []
    new_flags = []
    new_ends = []
    for i, end in enumerate(ends):
        pts = coords[start : end + 1]
        fl = flags[start : end + 1]
        area = signed_area(pts)
        # First contour = outer; rest = holes (rails are positive fills — keep CW)
        # Contours after first that are nested holes need opposite winding.
        # Heuristic: second contour in our SVG is the gem hole; rails stay CW.
        if i == 1 and area < 0:
            pts = list(reversed(pts))
            fl = list(reversed(fl))
        new_coords.extend(pts)
        new_flags.extend(fl)
        new_ends.append(len(new_coords) - 1)
        start = end + 1
    glyph.coordinates = GlyphCoordinates(new_coords)
    glyph.flags = new_flags
    glyph.endPtsOfContours = new_ends
    glyph.numberOfContours = len(new_ends)


def main() -> int:
    d = extract_path_d(SVG.read_text(encoding="utf-8"))
    transform = Transform(1, 0, 0, -1, 0, 1000)

    pen = TTGlyphPen(glyphSet=None)
    SVGPath.fromstring(
        f'<path d="{d}" fill-rule="evenodd"/>', transform=transform
    ).draw(pen)
    glyph = pen.glyph()
    fix_hole_windings(glyph)

    fb = FontBuilder(1000, isTTF=True)
    fb.setupGlyphOrder([".notdef", "galaaz"])
    fb.setupCharacterMap({CODEPOINT: "galaaz"})
    fb.setupGlyf({".notdef": TTGlyph(), "galaaz": glyph})
    fb.setupHorizontalMetrics({".notdef": (600, 0), "galaaz": (1000, 0)})
    fb.setupHorizontalHeader(ascent=1000, descent=0)
    fb.setupOS2(
        sTypoAscender=1000,
        sTypoDescender=0,
        sTypoLineGap=0,
        usWinAscent=1000,
        usWinDescent=0,
        sxHeight=500,
        sCapHeight=700,
    )
    fb.setupPost()
    fb.setupNameTable(
        {
            "familyName": "galaaz",
            "styleName": "Regular",
            "uniqueFontIdentifier": "galaaz Regular",
            "fullName": "galaaz Regular",
            "psName": "galaaz-Regular",
            "version": "Version 1.000",
            "manufacturer": "Galaaz",
            "description": "Monochrome Galaaz mark for Omarchy menu rows (U+E900).",
        }
    )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    fb.save(OUT)

    tt = TTFont(OUT)
    assert tt["cmap"].getBestCmap().get(CODEPOINT) == "galaaz"
    g = tt["glyf"]["galaaz"]
    coords = list(g.coordinates)
    ends = list(g.endPtsOfContours)
    start = 0
    for i, end in enumerate(ends):
        pts = coords[start : end + 1]
        a = signed_area(pts)
        print(f"  contour {i}: {'CW' if a < 0 else 'CCW'} area={a:.0f}")
        start = end + 1
    print(f"wrote {OUT}  glyph U+{CODEPOINT:04X} family=galaaz")
    return 0


if __name__ == "__main__":
    sys.exit(main())
