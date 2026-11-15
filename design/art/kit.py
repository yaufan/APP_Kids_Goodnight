"""Starlight-silhouette drawing kit for 晚安小鎮 (星光剪影風).

Everything is a soft paper silhouette on a deep blue night: flat shapes with no outlines and no
detail, and the only bright things are warm windows, lanterns, the lamp, the stars and the moon.
Glow is a stack of see-through circles (flutter_svg has no filters). Only plain paths, circles,
ellipses, rects and linear/radial gradients, so flutter_svg draws exactly what Chromium draws.

    import kit
    s = kit.Svg(120, 100)
    s.path(kit.rrect(8, 20, 100, 60, 14), kit.NIGHT)
    s.glow(60, 40, 30, kit.WARM)                 # soft light around (60, 40)
    s.circle(60, 40, 8, kit.MOON)
    kit.write_svg(path, s.text())                # checks the rules, then writes

Placeholders: animal files paint their body `#BODY`, eyes `#EYE` and the closed eyes `#LID`; the app
replaces them (lib/app/widgets.dart `Art(tokens:)`), so one drawing serves the lit window, the dark
window and the story pictures. Single-colour icons use plain black; the app tints them.
"""
import hashlib
import math
import pathlib
import random
import re
import xml.etree.ElementTree as ET

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
ART = ROOT / "app" / "assets" / "art"
SCRATCH = pathlib.Path("/dev/shm") if pathlib.Path("/dev/shm").is_dir() else None

# ---------------------------------------------------------------- palette
SKY_TOP = "#121735"       # deep night
SKY_LOW = "#2B2F6B"       # towards the horizon
NIGHT = "#1E2656"
FAR = "#272F63"           # far hills
MID = "#1C2350"           # back buildings
NEAR = "#151A40"          # the street's buildings
NEAREST = "#0F1331"       # arcade pillars, lamp post, scooter
ROAD = "#0D102A"
PANE = "#283268"          # a window with the light off
PANE_DK = "#20295A"
WARM = "#FFC96B"          # glow
WARM_LT = "#FFE6A6"       # a lit pane
WARM_MID = "#FFD688"
WARM_EDGE = "#F2AE57"
LANTERN = "#F06A55"
LANTERN_LT = "#FF9C7A"
LANTERN_OFF = "#4A2A47"
MOON = "#FFE8A8"
MOON_LT = "#FFF4CF"
STAR = "#FFF1C2"
SHEEP = "#E9E6F7"         # moonlit wool
SHEEP_DK = "#C9C4E6"
INK = "#24193A"           # silhouettes inside lit windows, faces
BLUSH = "#F4A8A0"
MAIL_RED = "#7E3346"
MAIL_GREEN = "#2C5C55"
BODY, EYE, LID = "#BODY", "#EYE", "#LID"
TOKENS = {BODY: "#2A2140", EYE: "#FFE9B0", LID: "#8C98D8"}   # a sample for checks and previews


def rnd(*key):
    """A seeded random generator: the same key always gives the same numbers."""
    h = hashlib.md5("|".join(map(str, key)).encode()).hexdigest()
    return random.Random(int(h[:12], 16))


def mix(a, b, t):
    pa = [int(a[i:i + 2], 16) for i in (1, 3, 5)]
    pb = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return "#%02X%02X%02X" % tuple(round(x + (y - x) * t) for x, y in zip(pa, pb))


def n(v):
    s = f"{v:.1f}"
    if s.endswith(".0"):
        s = s[:-2]
    return "0" if s == "-0" else s


# ---------------------------------------------------------------- path data
def poly(pts, close=True):
    d = "M" + " L".join(f"{n(x)} {n(y)}" for x, y in pts)
    return d + (" Z" if close else "")


def rect(x, y, w, h):
    return poly([(x, y), (x + w, y), (x + w, y + h), (x, y + h)])


def rrect(x, y, w, h, r):
    r = min(r, w / 2, h / 2)
    k = r * 0.5523
    return (f"M{n(x + r)} {n(y)} L{n(x + w - r)} {n(y)} C{n(x + w - r + k)} {n(y)} {n(x + w)} {n(y + r - k)} {n(x + w)} {n(y + r)} "
            f"L{n(x + w)} {n(y + h - r)} C{n(x + w)} {n(y + h - r + k)} {n(x + w - r + k)} {n(y + h)} {n(x + w - r)} {n(y + h)} "
            f"L{n(x + r)} {n(y + h)} C{n(x + r - k)} {n(y + h)} {n(x)} {n(y + h - r + k)} {n(x)} {n(y + h - r)} "
            f"L{n(x)} {n(y + r)} C{n(x)} {n(y + r - k)} {n(x + r - k)} {n(y)} {n(x + r)} {n(y)} Z")


def ellipse(cx, cy, rx, ry=None):
    ry = rx if ry is None else ry
    kx, ky = rx * 0.5523, ry * 0.5523
    return (f"M{n(cx)} {n(cy - ry)} C{n(cx + kx)} {n(cy - ry)} {n(cx + rx)} {n(cy - ky)} {n(cx + rx)} {n(cy)} "
            f"C{n(cx + rx)} {n(cy + ky)} {n(cx + kx)} {n(cy + ry)} {n(cx)} {n(cy + ry)} "
            f"C{n(cx - kx)} {n(cy + ry)} {n(cx - rx)} {n(cy + ky)} {n(cx - rx)} {n(cy)} "
            f"C{n(cx - rx)} {n(cy - ky)} {n(cx - kx)} {n(cy - ry)} {n(cx)} {n(cy - ry)} Z")


def circle(cx, cy, r):
    return ellipse(cx, cy, r, r)


def smooth(pts, close=True, t=0.5):
    """A soft curve through the points (Catmull-Rom as cubic Béziers)."""
    m = len(pts)
    out = [f"M{n(pts[0][0])} {n(pts[0][1])}"]
    rng = range(m) if close else range(m - 1)
    for i in rng:
        p0 = pts[(i - 1) % m] if (close or i > 0) else pts[i]
        p1, p2 = pts[i], pts[(i + 1) % m]
        p3 = pts[(i + 2) % m] if (close or i + 2 < m) else p2
        c1 = (p1[0] + (p2[0] - p0[0]) * t / 3, p1[1] + (p2[1] - p0[1]) * t / 3)
        c2 = (p2[0] - (p3[0] - p1[0]) * t / 3, p2[1] - (p3[1] - p1[1]) * t / 3)
        out.append(f"C{n(c1[0])} {n(c1[1])} {n(c2[0])} {n(c2[1])} {n(p2[0])} {n(p2[1])}")
    return " ".join(out) + (" Z" if close else "")


def blob(cx, cy, rx, ry, lumps=9, wobble=0.08, key="blob"):
    r = rnd(key)
    pts = []
    for i in range(lumps):
        a = 2 * math.pi * i / lumps
        k = 1 + r.uniform(-wobble, wobble)
        pts.append((cx + math.cos(a) * rx * k, cy + math.sin(a) * ry * k))
    return smooth(pts)


def cloud(cx, cy, w, h):
    """A soft cloud: three round puffs on a rounded base."""
    return " ".join([circle(cx - w * .24, cy + h * .06, h * .36), circle(cx + .02 * w, cy - h * .1, h * .5),
                     circle(cx + w * .26, cy + h * .08, h * .34), rrect(cx - w / 2, cy + h * .02, w, h * .44, h * .22)])


def star(cx, cy, R, r=None, points=4, rot=-90):
    r = R * 0.38 if r is None else r
    pts = []
    for i in range(points * 2):
        a = math.radians(rot + 180 * i / points)
        rr = R if i % 2 == 0 else r
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    return poly(pts)


def heart(cx, cy, s):
    return (f"M{n(cx)} {n(cy + s * .9)} C{n(cx - s * 1.3)} {n(cy + s * .1)} {n(cx - s * .9)} {n(cy - s * .9)} {n(cx)} {n(cy - s * .35)} "
            f"C{n(cx + s * .9)} {n(cy - s * .9)} {n(cx + s * 1.3)} {n(cy + s * .1)} {n(cx)} {n(cy + s * .9)} Z")


def arc_pts(cx, cy, rx, ry, a0, a1, steps=24):
    return [(cx + math.cos(math.radians(a0 + (a1 - a0) * i / steps)) * rx, cy + math.sin(math.radians(a0 + (a1 - a0) * i / steps)) * ry)
            for i in range(steps + 1)]


def line(pts):
    return poly(pts, close=False)


def crescent(cx, cy, r, cut=0.62, dx=0.42, dy=-0.28):
    """A crescent moon: a circle with a bite (two arcs), the bite up-right."""
    # outer circle from the tips round the left; inner circle back.
    bx, by, br = cx + r * dx * 1.0, cy + r * dy, r * cut / 0.62 * 0.78
    # tips: intersections of the two circles
    d = math.hypot(bx - cx, by - cy)
    a = (r * r - br * br + d * d) / (2 * d)
    h = math.sqrt(max(r * r - a * a, 0.01))
    mx, my = cx + a * (bx - cx) / d, cy + a * (by - cy) / d
    t1 = (mx + h * (by - cy) / d, my - h * (bx - cx) / d)
    t2 = (mx - h * (by - cy) / d, my + h * (bx - cx) / d)
    return (f"M{n(t1[0])} {n(t1[1])} A{n(r)} {n(r)} 0 1 0 {n(t2[0])} {n(t2[1])} "
            f"A{n(br)} {n(br)} 0 0 1 {n(t1[0])} {n(t1[1])} Z")


# ---------------------------------------------------------------- the document
class Svg:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.defs = []
        self.els = []
        self._ids = 0

    def add(self, text):
        self.els.append(text)

    def path(self, d, fill, op=1.0, stroke=None, sw=0, cap="round"):
        a = f'<path d="{d}" fill="{fill}"'
        if op < 1:
            a += f' fill-opacity="{op:.3g}"'
        if stroke:
            a += f' stroke="{stroke}" stroke-width="{n(sw)}" stroke-linecap="{cap}" stroke-linejoin="round"'
            if op < 1 and fill == "none":
                a += f' stroke-opacity="{op:.3g}"'
        self.els.append(a + "/>")

    def stroke(self, d, col, w, op=1.0, cap="round"):
        self.path(d, "none", op=op, stroke=col, sw=w, cap=cap)

    def circle(self, cx, cy, r, fill, op=1.0):
        a = f'<circle cx="{n(cx)}" cy="{n(cy)}" r="{n(r)}" fill="{fill}"'
        if op < 1:
            a += f' fill-opacity="{op:.3g}"'
        self.els.append(a + "/>")

    def glow(self, cx, cy, r, col=WARM, layers=7, top=0.11, rx=None, ry=None):
        """Soft light: see-through circles from r down to r/4, each adding a little."""
        for i in range(layers):
            k = 1 - i / layers * 0.78
            if rx is None:
                self.circle(cx, cy, r * k, col, top)
            else:
                self.path(ellipse(cx, cy, rx * k, ry * k), col, top)

    def gradient(self, stops, x1=0, y1=0, x2=0, y2=1):
        """A linear gradient (fractions of the shape's box); returns url(#id)."""
        self._ids += 1
        gid = f"g{self._ids}"
        s = "".join(f'<stop offset="{o:.3g}" stop-color="{c}"' + (f' stop-opacity="{a:.3g}"' if a < 1 else "") + "/>"
                    for o, c, a in [(st + (1,))[:3] for st in stops])
        self.defs.append(f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{s}</linearGradient>')
        return f"url(#{gid})"

    def radial(self, stops):
        self._ids += 1
        gid = f"g{self._ids}"
        s = "".join(f'<stop offset="{o:.3g}" stop-color="{c}"' + (f' stop-opacity="{a:.3g}"' if a < 1 else "") + "/>"
                    for o, c, a in [(st + (1,))[:3] for st in stops])
        self.defs.append(f'<radialGradient id="{gid}" cx="0.5" cy="0.5" r="0.5">{s}</radialGradient>')
        return f"url(#{gid})"

    def text(self):
        defs = f"<defs>{''.join(self.defs)}</defs>" if self.defs else ""
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {n(self.w)} {n(self.h)}">' + defs
                + "".join(self.els) + "</svg>\n")


# ---------------------------------------------------------------- checks
FORBIDDEN = ["<filter", "<mask", "<style", "style=", "<text", "<image", "<pattern", "mix-blend", "<clipPath", "<use"]
MAX_KB = 70
DRAWN = {"path", "circle", "ellipse", "rect", "polygon", "polyline", "line"}
_TOK = re.compile(r"[MmLlHhVvCcSsQqTtAaZz]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?")
_NARGS = {"M": 2, "L": 2, "H": 1, "V": 1, "C": 6, "S": 4, "Q": 4, "T": 2, "A": 7, "Z": 0}


def check_path(d):
    toks = _TOK.findall(d)
    if not toks or toks[0] not in "Mm":
        raise ValueError(f"path does not start with M: {d[:40]!r}")
    if len("".join(toks)) != len(re.sub(r"[\s,]", "", d)):
        raise ValueError(f"stray characters in path: {d[:60]!r}")
    i = 0
    while i < len(toks):
        cmd = toks[i]
        if not cmd.isalpha():
            raise ValueError(f"numbers without a command: {d[:60]!r}")
        i += 1
        k = _NARGS[cmd.upper()]
        j = i
        while j < len(toks) and not toks[j].isalpha():
            j += 1
        cnt = j - i
        if (k == 0 and cnt) or (k and (cnt == 0 or cnt % k)):
            raise ValueError(f"command {cmd} has {cnt} numbers: {d[:60]!r}")
        i = j


def check_svg(name, text):
    bad = [f for f in FORBIDDEN if f in text]
    if bad:
        raise SystemExit(f"{name}: uses {bad} (flutter_svg cannot draw these)")
    kb = len(text.encode()) / 1024
    if kb > MAX_KB:
        raise SystemExit(f"{name}: {kb:.0f} KB (keep under {MAX_KB} KB)")
    if not text.rstrip().endswith("</svg>"):
        raise SystemExit(f"{name}: does not end with </svg>")
    try:
        root = ET.fromstring(text)
    except ET.ParseError as e:
        raise SystemExit(f"{name}: not well-formed XML: {e}")
    ns = "{http://www.w3.org/2000/svg}"
    if root.tag != f"{ns}svg":
        raise SystemExit(f"{name}: root is not <svg xmlns=...>")
    vb = [float(v) for v in (root.get("viewBox") or "1 1 0 0").split()]
    if vb[0] or vb[1] or vb[2] <= 0 or vb[3] <= 0:
        raise SystemExit(f"{name}: viewBox must be 0 0 w h")
    for el in root.iter():
        tag = el.tag.replace(ns, "")
        d = el.get("d")
        if d is not None:
            try:
                check_path(d)
            except ValueError as e:
                raise SystemExit(f"{name}: {e}")
        if tag in DRAWN and el.get("fill") is None and el.get("stroke") is None:
            raise SystemExit(f"{name}: a <{tag}> without fill/stroke")
        for a in ("fill", "stroke"):
            v = el.get(a)
            if v and v.startswith("url(#") and root.find(f".//*[@id='{v[5:-1]}']") is None:
                raise SystemExit(f"{name}: {a} points to a missing {v}")
    return kb


def viewbox_of(path):
    vb = [float(v) for v in ET.parse(path).getroot().get("viewBox").split()]
    return vb[2], vb[3]


def write_svg(rel, text):
    """Check, then write app/assets/art/<rel>. Returns the path."""
    path = ART / rel
    check_svg(rel, text)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    return path


def with_tokens(text):
    for k, v in TOKENS.items():
        text = text.replace(k, v)
    return text
