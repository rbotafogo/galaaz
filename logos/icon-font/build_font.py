#!/usr/bin/env python3
"""Build Galaaz Omarchy menu fonts from logos/icon-font/galaaz-mark.svg.

Produces:
  script/omarchy/fonts/galaaz.ttf
      Standalone family "galaaz" (previews / debugging).
  script/omarchy/fonts/omarchy-with-galaaz.ttf
      Omarchy brand font + Galaaz glyph at U+E90E (family still "omarchy").
      Menu rows must use iconFont "omarchy" — Qt already loads that family.
"""
from __future__ import annotations

import re
import sys
import urllib.request
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.misc.transform import Transform
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import SVGPath
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._g_l_y_f import Glyph as TTGlyph
from fontTools.ttLib.tables._g_l_y_f import GlyphCoordinates

ROOT = Path(__file__).resolve().parents[2]
SVG = ROOT / "logos" / "icon-font" / "galaaz-mark.svg"
OUT = ROOT / "script" / "omarchy" / "fonts" / "galaaz.ttf"
OUT_MERGED = ROOT / "script" / "omarchy" / "fonts" / "omarchy-with-galaaz.ttf"
PREVIEW_DIR = ROOT / "logos" / "icon-font" / "preview"
OMARCHY_TTF_URL = (
    "https://raw.githubusercontent.com/basecamp/omarchy/quattro/"
    "default/fonts/omarchy/omarchy.ttf"
)
# Standalone family uses E920 (outside Omarchy E900–E90D).
STANDALONE_CODEPOINT = 0xE920
# Merged into family "omarchy" at first free slot after Omarchy's E90D.
OMARCHY_CODEPOINT = 0xE90E
GLYPH_NAME = "galaaz"
MIN_HOLE_AREA_RATIO = 0.04


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
    """TrueType nonzero fill: outer CW (area < 0), holes CCW (area > 0)."""
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
        want_cw = i != 1
        is_cw = area < 0
        if want_cw != is_cw:
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


def build_glyph() -> TTGlyph:
    d = extract_path_d(SVG.read_text(encoding="utf-8"))
    transform = Transform(1, 0, 0, -1, 0, 1000)
    pen = TTGlyphPen(glyphSet=None)
    SVGPath.fromstring(
        f'<path d="{d}" fill-rule="evenodd"/>', transform=transform
    ).draw(pen)
    glyph = pen.glyph()
    fix_hole_windings(glyph)
    return glyph


def assert_hole_ok(glyph: TTGlyph) -> None:
    coords = list(glyph.coordinates)
    ends = list(glyph.endPtsOfContours)
    start = 0
    areas = []
    for i, end in enumerate(ends):
        pts = coords[start : end + 1]
        a = signed_area(pts)
        areas.append(a)
        print(f"  contour {i}: {'CW' if a < 0 else 'CCW'} area={a:.0f}")
        start = end + 1
    if len(areas) < 2:
        raise SystemExit("expected outer + gem hole contours")
    ratio = abs(areas[1]) / abs(areas[0]) if areas[0] else 0.0
    print(f"  hole/outer area ratio: {ratio:.3f} (min {MIN_HOLE_AREA_RATIO})")
    if ratio < MIN_HOLE_AREA_RATIO:
        raise SystemExit(
            f"gem cutout too small for menu size ({ratio:.3f} < {MIN_HOLE_AREA_RATIO}); "
            "enlarge the hole in galaaz-mark.svg"
        )


def write_previews(ttf_path: Path, codepoint: int) -> None:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("  preview: skipped (pip install pillow)")
        return

    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    for size in (16, 24, 48):
        canvas = max(64, size * 2)
        img = Image.new("RGBA", (canvas, canvas), (30, 30, 30, 255))
        draw = ImageDraw.Draw(img)
        font = ImageFont.truetype(str(ttf_path), size)
        ch = chr(codepoint)
        bbox = draw.textbbox((0, 0), ch, font=font)
        w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
        x = (canvas - w) // 2 - bbox[0]
        y = (canvas - h) // 2 - bbox[1]
        draw.text((x, y), ch, font=font, fill=(230, 230, 230, 255))
        out = PREVIEW_DIR / f"glyph_{size}.png"
        img.save(out)
        print(f"  preview: {out}")


def build_standalone(glyph: TTGlyph) -> None:
    fb = FontBuilder(1000, isTTF=True)
    fb.setupGlyphOrder([".notdef", GLYPH_NAME])
    fb.setupCharacterMap({STANDALONE_CODEPOINT: GLYPH_NAME})
    fb.setupGlyf({".notdef": TTGlyph(), GLYPH_NAME: glyph})
    fb.setupHorizontalMetrics({".notdef": (600, 0), GLYPH_NAME: (1000, 0)})
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
            "uniqueFontIdentifier": "galaaz",
            "fullName": "galaaz",
            "psName": "galaaz",
            "version": "Version 1.003",
            "manufacturer": "Galaaz",
            "description": "Standalone Galaaz mark (U+E920). Menu uses omarchy-with-galaaz.ttf.",
        }
    )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    fb.save(OUT)
    assert TTFont(OUT).getBestCmap().get(STANDALONE_CODEPOINT) == GLYPH_NAME
    print(f"wrote {OUT}  glyph U+{STANDALONE_CODEPOINT:04X} family=galaaz")
    write_previews(OUT, STANDALONE_CODEPOINT)


def scale_glyph(glyph: TTGlyph, factor: float) -> TTGlyph:
    if glyph.numberOfContours <= 0:
        return glyph
    coords = GlyphCoordinates(list(glyph.coordinates))
    coords.scale((factor, factor))
    glyph.coordinates = coords
    if hasattr(glyph, "xMin"):
        glyph.recalcBounds(glyph)
    return glyph


def fetch_omarchy_ttf() -> Path:
    cache = Path("/tmp/omarchy-brand.ttf")
    if cache.is_file() and cache.stat().st_size > 1000:
        return cache
    print(f"  fetching {OMARCHY_TTF_URL}")
    urllib.request.urlretrieve(OMARCHY_TTF_URL, cache)
    return cache


def build_merged(glyph_1000: TTGlyph) -> None:
    from copy import deepcopy

    base_path = fetch_omarchy_ttf()
    base = TTFont(str(base_path))
    upem = base["head"].unitsPerEm
    glyph = deepcopy(glyph_1000)
    scale = upem / 1000.0
    if scale != 1.0:
        scale_glyph(glyph, scale)
    advance = int(round(1000 * scale))

    order = list(base.getGlyphOrder())
    if GLYPH_NAME in order:
        order.remove(GLYPH_NAME)
    order.append(GLYPH_NAME)
    base.setGlyphOrder(order)
    base["glyf"][GLYPH_NAME] = glyph
    base["hmtx"][GLYPH_NAME] = (advance, 0)

    for table in base["cmap"].tables:
        if table.isUnicode():
            table.cmap[OMARCHY_CODEPOINT] = GLYPH_NAME

    for rec in base["name"].names:
        if rec.nameID == 5:  # version
            rec.string = "Version 1.2+galaaz"
        if rec.nameID == 3:  # unique
            rec.string = "omarchy+galaaz"

    OUT_MERGED.parent.mkdir(parents=True, exist_ok=True)
    base.save(OUT_MERGED)
    merged = TTFont(OUT_MERGED)
    assert merged.getBestCmap().get(OMARCHY_CODEPOINT) == GLYPH_NAME
    assert merged["name"].getDebugName(1) == "omarchy"
    print(
        f"wrote {OUT_MERGED}  glyph U+{OMARCHY_CODEPOINT:04X} family=omarchy "
        f"(from {base_path.name}, upem={upem})"
    )


def main() -> int:
    glyph = build_glyph()
    assert_hole_ok(glyph)
    build_standalone(glyph)
    build_merged(glyph)
    return 0


if __name__ == "__main__":
    sys.exit(main())
