#!/usr/bin/env python3
"""Draws the KeepScore2 app icon into assets/icon/.

A trophy held above a podium, both white, over an orange gradient carrying a
large 2 as a watermark. Written by hand because the toolchain has no image
library: every shape is an analytic distance field, sampled once per pixel with
a one-pixel antialiasing ramp, and the result is deflated into a PNG.

Three files come out: the full icon, the watermarked background on its own and
the white mark on its own — the last two are Android's adaptive layers.

    python3 scripts/generate_icon.py
"""

import struct
import zlib
from math import cos, hypot, radians
from pathlib import Path

COS30 = cos(radians(30))

SIZE = 1024
OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"

BG_TOP = (0xFF, 0x9E, 0x1B)
BG_BOTTOM = (0xB3, 0x3A, 0x06)
MARK = (0xFF, 0xFF, 0xFF)
WATERMARK_ALPHA = 0.20

PODIUM = (
    (192, 649, 382),
    (417, 596, 607),
    (642, 696, 832),
)
BASELINE = 837
BAR_RADIUS = 40

# The 2 is drawn around this point at its natural size, then blown up until the
# bowl runs off the top and the diagonal off the bottom-left. The foot clears
# the canvas entirely, which it must: a foot that lands part-way onto the canvas
# shows only its straight top edge, with the corner that would explain it either
# below the edge or behind a podium block, and then it reads as a band detached
# from the numeral however solidly the two shapes overlap.
GLYPH_CENTRE = (512, 610)
WATERMARK_SCALE = 7.6
WATERMARK_CENTRE = (512, 545)


def rounded_rect(x, y, left, top, right, bottom, radius):
    cx, cy = (left + right) / 2, (top + bottom) / 2
    dx = max(abs(x - cx) - ((right - left) / 2 - radius), 0)
    dy = max(abs(y - cy) - ((bottom - top) / 2 - radius), 0)
    return hypot(dx, dy) - radius


def circle(x, y, cx, cy, radius):
    return hypot(x - cx, y - cy) - radius


def ellipse(x, y, cx, cy, rx, ry):
    return (hypot((x - cx) / rx, (y - cy) / ry) - 1) * min(rx, ry)


def ellipse_ring(x, y, cx, cy, rx, ry, hole_rx, hole_ry):
    return max(
        ellipse(x, y, cx, cy, rx, ry),
        -ellipse(x, y, cx, cy, hole_rx, hole_ry),
    )


def ring(x, y, cx, cy, outer, inner):
    return max(circle(x, y, cx, cy, outer), -circle(x, y, cx, cy, inner))


def capsule(x, y, ax, ay, bx, by, radius):
    vx, vy = bx - ax, by - ay
    px, py = x - ax, y - ay
    span = vx * vx + vy * vy
    t = 0.0 if span == 0 else min(max((px * vx + py * vy) / span, 0.0), 1.0)
    return hypot(px - vx * t, py - vy * t) - radius


def coverage(distance):
    return min(max(0.5 - distance, 0.0), 1.0)


def trophy(x, y):
    # The bowl is the lower half of an ellipse — deeper than it is wide, so the
    # cup reads tall. Its flat cut hides under the rim.
    bowl = ellipse(x, y, 512, 222, 120, 175) if y >= 222 else 1e9
    return min(
        rounded_rect(x, y, 382, 186, 642, 228, 16),
        bowl,
        # Upright ovals, set out far enough that each hole falls clear of the
        # bowl instead of biting into it.
        ellipse_ring(x, y, 370, 292, 52, 66, 24, 40),
        ellipse_ring(x, y, 654, 292, 52, 66, 24, 40),
        capsule(x, y, 512, 391, 512, 500, 22),
        rounded_rect(x, y, 442, 500, 582, 540, 8),
    )


def podium(x, y):
    return min(
        rounded_rect(x, y, left, top, right, BASELINE, BAR_RADIUS)
        for left, top, right in PODIUM
    )


def two(x, y):
    # A 240° bowl, a diagonal down to the left, and a foot. The bowl is cut
    # along its radii at 30° and 150°, which leaves the stroke's true width at
    # each terminal — a horizontal cut would leave a wider, oblique end that no
    # round cap can cover, and the joins would step. The diagonal starts and
    # ends exactly on a centreline: the bowl's at (555, 595), the foot's at
    # y 700, so both joins close with nothing sticking out.
    dx, dy = x - 512, y - 570
    wedge = min(COS30 * dy - 0.5 * dx, 0.5 * dx + COS30 * dy)
    return min(
        max(ring(x, y, 512, 570, 65, 35), wedge),
        capsule(x, y, 555, 595, 467, 700, 15),
        capsule(x, y, 452, 700, 572, 700, 15),
    )


def scaled(shape, x, y, factor, centre, anchor):
    """The shape blown up by `factor` about `centre`, distances still in pixels."""
    u = (x - centre[0]) / factor + anchor[0]
    v = (y - centre[1]) / factor + anchor[1]
    return shape(u, v) * factor


def mark_alpha(x, y, factor=1.0, centre=(512, 512)):
    u = (x - centre[0]) / factor + 512
    v = (y - centre[1]) / factor + 512
    return max(coverage(trophy(u, v) * factor), coverage(podium(u, v) * factor))


def watermark_alpha(x, y):
    distance = scaled(two, x, y, WATERMARK_SCALE, WATERMARK_CENTRE, GLYPH_CENTRE)
    return coverage(distance) * WATERMARK_ALPHA


def blend(base, alpha):
    return [round(base[i] + (MARK[i] - base[i]) * alpha) for i in range(3)]


def write_png(path, rows, alpha):
    raw = b"".join(b"\x00" + row for row in rows)

    def chunk(tag, data):
        block = tag + data
        return struct.pack(">I", len(data)) + block + struct.pack(
            ">I", zlib.crc32(block) & 0xFFFFFFFF
        )

    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6 if alpha else 2, 0, 0, 0)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )
    print(f"{path.name}  {SIZE}x{SIZE}  {'RGBA' if alpha else 'RGB'}")


def render():
    OUT.mkdir(parents=True, exist_ok=True)

    full, background, foreground = [], [], []
    # flutter_launcher_icons insets the adaptive foreground by 16%. At 0.92 the
    # far corners of the podium land just inside Android's 66dp safe circle
    # once that inset is applied.
    fg_scale = 0.92

    for y in range(SIZE):
        opaque, plain, transparent = bytearray(), bytearray(), bytearray()
        t = y / (SIZE - 1)
        base = tuple(
            round(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3)
        )

        for x in range(SIZE):
            behind = blend(base, watermark_alpha(x + 0.5, y + 0.5))
            plain.extend(behind)
            opaque.extend(blend(behind, mark_alpha(x + 0.5, y + 0.5)))

            transparent.extend(MARK)
            transparent.append(
                round(mark_alpha(x + 0.5, y + 0.5, fg_scale) * 255)
            )

        full.append(bytes(opaque))
        background.append(bytes(plain))
        foreground.append(bytes(transparent))

    write_png(OUT / "app_icon.png", full, alpha=False)
    write_png(OUT / "app_icon_background.png", background, alpha=False)
    write_png(OUT / "app_icon_foreground.png", foreground, alpha=True)


if __name__ == "__main__":
    render()
