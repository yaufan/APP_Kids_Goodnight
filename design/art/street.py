"""The street at dusk (docs/design.md 「畫面：一條黃昏的台灣小街」): apartments with iron window cages
(鐵窗), the breakfast shop and the snack shop under the arcade (騎樓) with a red lantern, a convenience
store sign, a street lamp, the red and green mailboxes and a scooter; hills far behind.

The street is one picture, `street/street.svg` (W x H, transparent sky: the app paints the sky), with
every window drawn DARK. Each light is a separate piece laid over it: `street/glow_<light>.svg` is the
light ON (its warm pane and the soft glow around it); fading it out turns the light off. The windows'
iron cages are `street/grille.svg`, laid over the animal. The app places the pieces with
lib/core/street_layout.dart, which this script writes (the same numbers, in street units):

    python3 street.py            # writes the pictures and the Dart layout
"""
import sys

sys.dont_write_bytecode = True

import kit  # noqa: E402
from kit import (FAR, MID, NEAR, NEAREST, PANE, PANE_DK, ROAD, WARM, WARM_EDGE, WARM_LT, WARM_MID, LANTERN, LANTERN_LT,  # noqa: E402
                 LANTERN_OFF, MAIL_GREEN, MAIL_RED, circle, ellipse, poly, rect, rrect, smooth)

W, H = 700, 520
GROUND = 448          # the arcade's floor / the pavement
PW, PH = 36, 42       # a window pane

# The lights: (id, pane rect, animal box or None, art margin, kind)
WINDOWS = {
    "cat": (170, 206), "duck": (214, 268),                                   # building A
    "rabbit": (346, 150), "bear": (288, 210), "window": (346, 210), "pig": (288, 270),   # building B
    "owl": (470, 232),                                                       # building C
}
SHOP = (288, 400, 58, 40)        # the breakfast shop's window (the dog)
DOOR = (356, 396, 28, 52)
LANTERN_AT = (430, 404, 20, 26)  # x, y, w, h of the red lantern
SIGN = (470, 374, 66, 16)
LAMP_HEAD = (214, 352, 30, 9)    # the lamp's shade
LAMP_POST_X = 204

BUILDINGS = {   # x, top, w
    "A": (160, 180, 98),
    "B": (266, 124, 138),
    "C": (412, 206, 128),
}
ROWS = {"A": [206, 268, 330], "B": [150, 210, 270, 330], "C": [232, 294]}
COLS = {"A": [170, 214], "B": [288, 346], "C": [426, 470]}


def lit_windows():
    return {(x, y) for x, y in WINDOWS.values()}


# ---------------------------------------------------------------- the street (all dark)
def street():
    s = kit.Svg(W, H)
    # far hills and a little temple roof far away
    hills = [(0, 330), (60, 318), (130, 296), (210, 312), (300, 290), (380, 306), (470, 284), (560, 300), (640, 288), (700, 300)]
    s.path(smooth(hills, close=False) + f" L700 {GROUND} L0 {GROUND} Z", FAR)
    # back buildings (between and beyond)
    for x, top, w in [(30, 262, 70), (96, 238, 60), (236, 250, 40), (396, 262, 40), (540, 246, 60), (598, 268, 80), (650, 236, 44)]:
        s.path(rect(x, top, w, GROUND - top), MID)
        for wy in range(top + 18, GROUND - 60, 34):
            for wx in range(x + 10, x + w - 16, 22):
                s.path(rect(wx, wy, 12, 16), PANE_DK, 0.8)
    # side buildings, nearer (visible on wide screens)
    for x, top, w in [(0, 214, 70), (74, 236, 82), (546, 232, 80), (630, 204, 70)]:
        s.path(rect(x, top, w, GROUND - top), NEAR)
        for wy in range(top + 22, GROUND - 70, 52):
            for wx in range(x + 12, x + w - 24, 34):
                s.path(rect(wx - 3, wy - 3, PW * .8 + 6, PH * .8 + 6), kit.mix(NEAR, PANE, .45))
                s.path(rect(wx, wy, PW * .8, PH * .8), PANE)
        _arcade(s, x, w)
    # main buildings
    for b, (x, top, w) in BUILDINGS.items():
        s.path(rect(x, top, w, GROUND - top), NEAR)
        s.path(rect(x - 3, top - 5, w + 6, 7), NEAREST)                      # the roof's edge
        for y in ROWS[b]:
            for cx in COLS[b]:
                _window(s, cx, y)
        _arcade(s, x, w)
    # roof things: water tanks, an antenna, a little shed
    x, top, w = BUILDINGS["A"]
    s.path(rect(226, top - 26, 24, 18), NEAREST)
    s.path(rect(229, top - 8, 3, 8) + " " + rect(244, top - 8, 3, 8), NEAREST)
    s.path(rect(170, top - 16, 30, 16), NEAR)
    x, top, w = BUILDINGS["B"]
    s.stroke(kit.line([(384, top - 4), (384, top - 46)]), NEAREST, 3)
    s.stroke(kit.line([(372, top - 34), (396, top - 34)]), NEAREST, 2.5)
    s.stroke(kit.line([(375, top - 24), (393, top - 24)]), NEAREST, 2.5)
    s.path(rect(278, top - 22, 36, 22), NEAR)
    x, top, w = BUILDINGS["C"]
    s.path(rect(500, top - 22, 26, 17), NEAREST)
    s.path(rect(503, top - 5, 3, 5) + " " + rect(519, top - 5, 3, 5), NEAREST)
    # a balcony with plants on C
    s.path(rect(504, 300, 34, 4), NEAREST)
    for i in range(4):
        s.path(rect(507 + i * 8, 304, 2, 18), NEAREST)
    s.path(rect(504, 320, 34, 3), NEAREST)
    s.path(kit.blob(512, 296, 7, 6, key="plant1"), NEAREST)
    s.path(kit.blob(528, 294, 6, 8, key="plant2"), NEAREST)
    # the shops under the arcade
    sx, sy, sw, sh = SHOP
    s.path(rect(sx - 3, sy - 3, sw + 6, sh + 6), NEAREST)
    s.path(rect(sx, sy, sw, sh), PANE)
    s.path(rect(sx, sy + sh - 8, sw, 8), PANE_DK)                            # the counter
    dx, dy, dw, dh = DOOR
    s.path(rect(dx - 3, dy - 3, dw + 6, dh + 3), NEAREST)
    s.path(rect(dx, dy, dw, dh), PANE)
    s.path(rect(dx + dw - 8, dy + dh / 2, 4, 2), NEAREST)
    # the snack shop's lantern, off; its shop front
    lx, ly, lw, lh = LANTERN_AT
    s.stroke(kit.line([(lx + lw / 2, 392), (lx + lw / 2, ly)]), NEAREST, 1.5)
    s.path(ellipse(lx + lw / 2, ly + lh / 2, lw / 2, lh / 2), LANTERN_OFF)
    s.path(rect(lx + lw / 2 - 5, ly - 2, 10, 4) + " " + rect(lx + lw / 2 - 5, ly + lh - 2, 10, 4), NEAREST)
    s.path(rect(418, 412, 40, 30), kit.mix(NEAR, PANE, .35))
    # the convenience store: its sign (off) and its glass front
    gx, gy, gw, gh = SIGN
    s.path(rrect(gx, gy, gw, gh, 3), kit.mix(NEAR, PANE, .55))
    for i, col in enumerate(["#3E3A52", "#2E4A4A", "#4A3040"]):
        s.path(rect(gx + 4, gy + 3 + i * 4, gw - 8, 2.4), col)
    s.path(rect(470, 400, 66, 44), kit.mix(NEAR, PANE, .45))
    s.path(rect(502, 400, 2, 44), NEAREST)
    # the mailboxes, the scooter, the lamp (off)
    s.path(rrect(396, 418, 12, 30, 3), MAIL_RED)
    s.path(rect(394, 414, 16, 6), kit.mix(MAIL_RED, "#000000", .3))
    s.path(rrect(410, 418, 12, 30, 3), MAIL_GREEN)
    s.path(rect(408, 414, 16, 6), kit.mix(MAIL_GREEN, "#000000", .3))
    _scooter(s, 452, GROUND)
    _lamp(s)
    # pavement and road
    s.path(rect(0, GROUND, W, 10), "#161A3D")
    s.path(rect(0, GROUND + 10, W, H - GROUND - 10), ROAD)
    for x in range(10, W, 46):
        s.path(rect(x, 492, 24, 3), "#262D5C")
    return s.text()


def _window(s, x, y):
    s.path(rect(x - 4, y - 4, PW + 8, PH + 8), kit.mix(NEAR, PANE, .35))     # the iron cage's frame
    s.path(rect(x, y, PW, PH), PANE)
    s.path(rect(x - 6, y + PH + 4, PW + 12, 3), NEAREST)                     # the cage's bottom
    if (x, y) not in lit_windows():
        _bars(s, x, y, NEAREST)


def _bars(s, x, y, col):
    """The iron cage (鐵窗): bars over the lower half, so the faces in the windows show."""
    for i in range(1, 4):
        s.path(rect(x + i * PW / 4 - 0.8, y + PH * .55, 1.6, PH * .45 + 2), col)
    s.path(rect(x - 2, y + PH * .55, PW + 4, 1.8), col)
    s.path(rect(x - 2, y - 2, PW + 4, 1.6), col)


def _arcade(s, x, w):
    """The arcade (騎樓): a beam and pillars along the ground floor."""
    s.path(rect(x, 390, w, 6), NEAREST)
    for px in (x, x + w - 8):
        s.path(rect(px, 390, 8, GROUND - 390), NEAREST)


def _scooter(s, x, g):
    s.path(circle(x + 8, g - 7, 7) + " " + circle(x + 44, g - 7, 7), NEAREST)
    body = [(x + 2, g - 14), (x + 14, g - 20), (x + 28, g - 18), (x + 38, g - 26), (x + 46, g - 20), (x + 50, g - 10), (x + 36, g - 8), (x + 10, g - 8)]
    s.path(smooth(body), NEAREST)
    s.path(poly([(x + 38, g - 26), (x + 34, g - 42), (x + 38, g - 43), (x + 43, g - 26)]), NEAREST)
    s.path(rect(x + 30, g - 46, 14, 3), NEAREST)
    s.path(ellipse(x + 20, g - 22, 10, 4), NEAREST)                          # the seat


def _lamp(s):
    hx, hy, hw, hh = LAMP_HEAD
    post = f"M{LAMP_POST_X - 3} {GROUND} L{LAMP_POST_X - 3} {hy + 4} C{LAMP_POST_X - 3} {hy - 10} {hx} {hy - 6} {hx + 6} {hy - 3} L{hx + 7} {hy + 1} C{hx} {hy - 2} {LAMP_POST_X + 3} {hy - 4} {LAMP_POST_X + 3} {hy + 6} L{LAMP_POST_X + 3} {GROUND} Z"
    s.path(post, NEAREST)
    s.path(rect(LAMP_POST_X - 6, GROUND - 8, 12, 8), NEAREST)
    s.path(poly([(hx, hy), (hx + hw, hy), (hx + hw - 4, hy + hh), (hx + 4, hy + hh)]), "#2A3060")


# ---------------------------------------------------------------- the lights (on)
MARGIN = 26     # glow around a window


def glow_window(name):
    """The pane lit warm, the glow around it; the empty window has curtains and a plant."""
    w, h = PW + 2 * MARGIN, PH + 2 * MARGIN
    s = kit.Svg(w, h)
    cx, cy = w / 2, h / 2
    s.glow(cx, cy, MARGIN + PH * .62, WARM, layers=8, top=0.075)
    g = s.gradient([(0, WARM_LT), (1, WARM_MID)])
    s.path(rect(MARGIN, MARGIN, PW, PH), g)
    s.path(rect(MARGIN, MARGIN + PH - 5, PW, 5), WARM_EDGE, 0.55)
    if name == "window":
        s.path(f"M{MARGIN} {MARGIN} L{MARGIN + 9} {MARGIN} C{MARGIN + 6} {MARGIN + 14} {MARGIN + 7} {MARGIN + 26} {MARGIN + 11} {MARGIN + PH} L{MARGIN} {MARGIN + PH} Z", WARM_EDGE, 0.8)
        r = MARGIN + PW
        s.path(f"M{r} {MARGIN} L{r - 9} {MARGIN} C{r - 6} {MARGIN + 14} {r - 7} {MARGIN + 26} {r - 11} {MARGIN + PH} L{r} {MARGIN + PH} Z", WARM_EDGE, 0.8)
        s.path(poly([(cx - 5, MARGIN + PH - 10), (cx + 5, MARGIN + PH - 10), (cx + 4, MARGIN + PH - 2), (cx - 4, MARGIN + PH - 2)]), kit.INK)
        for dx, dy, rx, ry in ((-5, -15, 3.2, 6), (0, -18, 3.2, 7.5), (5, -15, 3.2, 6)):
            s.path(ellipse(cx + dx, MARGIN + PH + dy, rx, ry), kit.INK)
    return s.text()


def glow_box(x, y, w, h, m):
    return (x - m, y - m, w + 2 * m, h + 2 * m)


def glow_shop():
    x, y, w, h = SHOP
    m = 24
    s = kit.Svg(w + 2 * m, h + 2 * m)
    s.glow(m + w / 2, m + h / 2, 0, WARM, layers=8, top=0.075, rx=w / 2 + m, ry=h / 2 + m * .9)
    s.path(rect(m, m, w, h), s.gradient([(0, WARM_LT), (1, WARM_MID)]))
    s.path(rect(m, m + h - 8, w, 8), WARM_EDGE, 0.7)                           # the counter
    # steamed buns and a soy-milk jug on the counter, as shapes
    for i in range(3):
        s.path(ellipse(m + 8 + i * 7, m + h - 10, 4, 3), kit.INK, 0.85)
    s.path(rrect(m + w - 12, m + h - 20, 7, 12, 2), kit.INK, 0.85)
    return s.text()


def glow_door():
    x, y, w, h = DOOR
    m = 20
    s = kit.Svg(w + 2 * m, h + 2 * m)
    s.glow(m + w / 2, m + h * .55, 0, WARM, layers=7, top=0.08, rx=w / 2 + m, ry=h / 2 + m * .8)
    s.path(rect(m, m, w, h), s.gradient([(0, WARM_LT), (1, WARM_MID)]))
    s.path(rect(m + w - 8, m + h / 2, 4, 2), kit.INK)
    s.path(poly([(m, m + h), (m + w, m + h), (m + w + 10, m + h + m), (m - 10, m + h + m)]), WARM, 0.18)   # light on the pavement
    return s.text()


def glow_lantern():
    x, y, w, h = LANTERN_AT
    m = 22
    s = kit.Svg(w + 2 * m, h + 2 * m)
    cx, cy = m + w / 2, m + h / 2
    s.glow(cx, cy, m + h * .5, LANTERN_LT, layers=7, top=0.09)
    s.path(ellipse(cx, cy, w / 2, h / 2), s.gradient([(0, LANTERN_LT), (1, LANTERN)]))
    for dx in (-5, 0, 5):
        s.stroke(kit.line([(cx + dx, cy - h / 2 + 2), (cx + dx * 1.3, cy), (cx + dx, cy + h / 2 - 2)]), "#D24A3F", 1)
    s.path(rect(cx - 5, m - 2, 10, 4) + " " + rect(cx - 5, m + h - 2, 10, 4), "#3A2030")
    s.path(rect(cx - 1, m + h + 2, 2, 6), "#E8C46A")
    return s.text()


def glow_sign():
    x, y, w, h = SIGN
    m = 18
    s = kit.Svg(w + 2 * m, h + 2 * m)
    s.glow(m + w / 2, m + h / 2, 0, "#FFF1C8", layers=6, top=0.08, rx=w / 2 + m, ry=h / 2 + m)
    s.path(rrect(m, m, w, h, 3), "#FFF6DE")
    for i, col in enumerate(["#F59A4E", "#5DBB8A", "#E8625A"]):
        s.path(rect(m + 4, m + 3 + i * 4, w - 8, 2.4), col)
    return s.text()


LAMP_ART = (192, 336, 74, 112)    # the lamp's head and the light it throws, down to the pavement


def glow_lamp():
    x, y, w, h = LAMP_ART
    hx, hy, hw, hh = LAMP_HEAD
    s = kit.Svg(w, h)
    ox, oy = hx - x, hy - y
    s.path(poly([(ox + 4, oy + hh), (ox + hw - 4, oy + hh), (w - 2, h), (2, h)]), s.gradient([(0, WARM_LT, .45), (1, WARM, .05)]))
    s.glow(ox + hw / 2, oy + hh, 30, WARM, layers=6, top=0.1)
    s.path(poly([(ox, oy), (ox + hw, oy), (ox + hw - 4, oy + hh), (ox + 4, oy + hh)]), "#3A3A6A")
    s.path(ellipse(ox + hw / 2, oy + hh, hw / 2 - 4, 3), WARM_LT)
    return s.text()


def grille():
    """The iron cage's bars, laid over the window and its animal."""
    s = kit.Svg(PW, PH)
    for i in range(1, 4):
        s.path(rect(i * PW / 4 - 0.8, PH * .55, 1.6, PH * .45), NEAREST)
    s.path(rect(0, PH * .55, PW, 1.8), NEAREST)
    s.path(rect(0, 0, PW, 1.6), NEAREST)
    return s.text()


# ---------------------------------------------------------------- layout for the app
def layout():
    """{light: (art box, tap box, animal box or None, pane box or None)} in street units."""
    out = {}
    for name, (x, y) in WINDOWS.items():
        art = glow_box(x, y, PW, PH, MARGIN)
        tap = (x - 5, y - 5, PW + 10, PH + 10)
        out[name] = (art, tap, None if name == "window" else (x, y, PW, PH), (x, y, PW, PH))
    sx, sy, sw, sh = SHOP
    out["dog"] = (glow_box(*SHOP, 24), (sx - 4, sy - 4, sw + 8, sh + 8), (sx + sw / 2 - 17, sy + 1, 34, 41), None)
    dx, dy, dw, dh = DOOR
    out["door"] = (glow_box(*DOOR, 20), (dx - 4, dy - 6, dw + 8, dh + 6), None, None)
    lx, ly, lw, lh = LANTERN_AT
    out["lantern"] = (glow_box(*LANTERN_AT, 22), (lx - 10, ly - 10, lw + 20, lh + 18), None, None)
    gx, gy, gw, gh = SIGN
    out["sign"] = (glow_box(*SIGN, 18), (gx - 4, gy - 8, gw + 8, gh + 14), None, None)
    hx, hy, hw, hh = LAMP_HEAD
    out["lamp"] = (LAMP_ART, (hx - 14, hy - 16, hw + 22, 46), None, None)
    return out


ORDER = ["cat", "rabbit", "bear", "duck", "pig", "owl", "dog", "window", "door", "lantern", "sign", "lamp"]


def dart():
    def r(b):
        return f"Rect.fromLTWH({kit.n(b[0])}, {kit.n(b[1])}, {kit.n(b[2])}, {kit.n(b[3])})"
    lines = [
        "// Written by design/art/street.py: do not edit by hand.",
        "import 'dart:ui';",
        "",
        "import 'content.dart';",
        "",
        "/// The street picture's size (assets/art/street/street.svg), in street units.",
        f"const streetSize = Size({W}, {H});",
        "",
        "/// The middle of the street that every screen shows whole (the lights are inside it).",
        "const streetCore = Rect.fromLTWH(150, 120, 400, 400);",
        "",
        "/// Where a light's pieces go on the street.",
        "class LightPlace {",
        "  const LightPlace({required this.art, required this.tap, this.animal, this.pane});",
        "",
        "  /// assets/art/street/glow_<light>.svg.",
        "  final Rect art;",
        "",
        "  /// Where a finger turns it off.",
        "  final Rect tap;",
        "",
        "  /// Where its animal sits (null: no animal).",
        "  final Rect? animal;",
        "",
        "  /// A window pane with an iron cage (assets/art/street/grille.svg) over it and its animal.",
        "  final Rect? pane;",
        "}",
        "",
        "const lightPlaces = <Light, LightPlace>{",
    ]
    for name in ORDER:
        art, tap, animal, gr = layout()[name]
        a = f", animal: {r(animal)}" if animal else ""
        g = f", pane: {r(gr)}" if gr else ""
        lines.append(f"  Light.{name}: LightPlace(art: {r(art)}, tap: {r(tap)}{a}{g}),")
    lines += ["};", ""]
    return "\n".join(lines)


def build():
    kit.write_svg("street/street.svg", street())
    for name in WINDOWS:
        kit.write_svg(f"street/glow_{name}.svg", glow_window(name))
    kit.write_svg("street/glow_dog.svg", glow_shop())
    kit.write_svg("street/glow_door.svg", glow_door())
    kit.write_svg("street/glow_lantern.svg", glow_lantern())
    kit.write_svg("street/glow_sign.svg", glow_sign())
    kit.write_svg("street/glow_lamp.svg", glow_lamp())
    kit.write_svg("street/grille.svg", grille())
    (kit.ROOT / "app" / "lib" / "core" / "street_layout.dart").write_text(dart())
    # every art box matches its file's viewBox
    for name, (art, *_rest) in layout().items():
        vw, vh = kit.viewbox_of(kit.ART / "street" / f"glow_{name}.svg")
        if abs(vw - art[2]) > .05 or abs(vh - art[3]) > .05:
            raise SystemExit(f"glow_{name}: viewBox {vw}x{vh} but box {art[2]}x{art[3]}")
    print("street: 15 pictures, lib/core/street_layout.dart")


if __name__ == "__main__":
    build()
