"""Design-stage sketches for 「晚安小鎮」 (a bedtime wind-down app for 2-5 year olds).

    python3 make_mockups.py          # writes docs/mockups/*.png (needs Node.js + Playwright)
    python3 make_mockups.py 3        # only one page: 0 = style page, 1..7 = a screen, c = contact sheet

Every picture is drawn here as SVG by code (no outside pictures, no emoji). render.js turns each page
into a PNG with Playwright's Chromium at 390x844, deviceScaleFactor 2. The font is jf open-huninn from a
sibling app's checkout.

    0_畫風選擇.png      the same street at night in three styles:
                        A 星光剪影風 (recommended), B 夜燈毛玻璃風, C 刺繡被子風
    1_小鎮黃昏.png      關燈巡邏 starts: dusk, every window lit, 「天黑了，幫大家關燈吧」
    2_關燈.png          a finger taps a window: it goes dark, the bunny yawns, half the town already asleep
    3_數羊.png          one sheep hops the fence, the number 3 / 三
    4_晚安故事.png      a story page: small picture, big slow words, 念給我聽 / 下一頁
    5_呼吸小月亮.png    press and hold: the moon grows while breathing in, 3 breaths
    6_搖籃曲.png        lullaby / white noise with a 20-minute timer, the screen fading to black
    7_家長模式.png      parents' settings
    8_晚安清單.png      the first step: 刷牙／尿尿／喝水／抱抱, tap each one when it is really done
    contact_sheet.png   the screens small, in the order the child sees them (8, 1-7), with titles
"""
import hashlib
import math
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
FONT = None
for _c in ("app_kids_falsecharge", "app_kids_maze", "app_kids_live_circ", "app_kids_brainstorming", "app_kids_card_game", "app_kids_cook"):
    _p = HERE.parents[3] / _c / "app" / "assets" / "fonts" / "jf-openhuninn-2.1.ttf"
    if _p.exists():
        FONT = _p
        break
SCRATCH = pathlib.Path("/dev/shm") if pathlib.Path("/dev/shm").is_dir() else pathlib.Path(tempfile.gettempdir())
W, H = 390, 844

# ---------------------------------------------------------------- colours
CREAM = "#F6EFE0"      # words on the night sky
DIM = "#A8B3CF"        # quieter words
WARM = "#FFD782"       # a lit window
WARM2 = "#FFB85C"      # the glow around it
WARM3 = "#FFE9B8"
OFF = "#1C2846"        # a window that is off
INK = "#3E3A4A"        # words on the parents' page
SOFT = "#8B8699"
PAGE = "#F5F1EA"       # the parents' page
TEAL = "#5FA8A0"
STAR = "#FFF4C8"


class Defs:
    def __init__(self):
        self.d = {}

    def add(self, key, svg):
        self.d.setdefault(key, svg)
        return key

    def svg(self):
        return "<defs>" + "".join(self.d.values()) + "</defs>"


D = Defs()


def _h(*parts):
    return hashlib.md5("|".join(map(str, parts)).encode()).hexdigest()[:10]


def _stops(stops):
    return "".join(f'<stop offset="{s[0]}" stop-color="{s[1]}"' + (f' stop-opacity="{s[2]}"' if len(s) > 2 else "") + "/>" for s in stops)


def lg(stops, x1=0, y1=0, x2=0, y2=1):
    k = "lg" + _h(stops, x1, y1, x2, y2)
    D.add(k, f'<linearGradient id="{k}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{_stops(stops)}</linearGradient>')
    return f"url(#{k})"


def rg(stops):
    k = "rg" + _h(stops)
    D.add(k, f'<radialGradient id="{k}">{_stops(stops)}</radialGradient>')
    return f"url(#{k})"


def blur(sd):
    k = "bl" + str(sd).replace(".", "_")
    D.add(k, f'<filter id="{k}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{sd}"/></filter>')
    return f"url(#{k})"


def clip(x, y, w, h, r=0):
    k = "cp" + _h(x, y, w, h, r)
    D.add(k, f'<clipPath id="{k}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}"/></clipPath>')
    return f"url(#{k})"


def _rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mixc(a, b, t):
    ra, rb = _rgb(a), _rgb(b)
    return "#" + "".join(f"{round(ra[i] + (rb[i] - ra[i]) * t):02X}" for i in range(3))


def lighter(c, t=.3):
    return mixc(c, "#FFFFFF", t)


def darker(c, t=.3):
    return mixc(c, "#000000", t)


def tx(x, y, s, size=16, col=CREAM, anchor="middle", weight="", op=1.0, ls=0):
    extra = f' letter-spacing="{ls}"' if ls else ""
    return (f'<text x="{x}" y="{y}" font-family="Huninn, sans-serif" font-size="{size}" fill="{col}" '
            f'text-anchor="{anchor}" opacity="{op}"{extra}>{s}</text>')


def pill(x, y, w, h, fill, stroke=None, op=1.0):
    st = f' stroke="{stroke}" stroke-width="1.5"' if stroke else ""
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h / 2}" fill="{fill}" opacity="{op}"{st}/>'


def card(x, y, w, h, r=18, fill="#FFFFFF"):
    return f'<rect x="{x}" y="{y + 2}" width="{w}" height="{h}" rx="{r}" fill="#E4DDD2"/><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"/>'


def lcg(seed):
    s = seed
    while True:
        s = (s * 1103515245 + 12345) & 0x7FFFFFFF
        yield s / 0x7FFFFFFF


# ================================================================ THE THREE STYLES
STYLE = "sil"      # "sil" (A 星光剪影), "frost" (B 夜燈毛玻璃), "quilt" (C 刺繡被子)


def weave():
    k = "weave"
    D.add(k, '<pattern id="weave" width="6" height="6" patternUnits="userSpaceOnUse">'
             '<rect width="6" height="6" fill="none"/><path d="M0,3 H6 M3,0 V6" stroke="#FFFFFF" stroke-width=".8" opacity=".16"/></pattern>')
    return "url(#weave)"


def gingham(col):
    k = "gh" + _h(col)
    D.add(k, f'<pattern id="{k}" width="12" height="12" patternUnits="userSpaceOnUse">'
             f'<rect width="12" height="12" fill="{col}"/><rect width="6" height="12" fill="#FFFFFF" opacity=".07"/><rect width="12" height="6" fill="#FFFFFF" opacity=".07"/></pattern>')
    return f"url(#{k})"


def dots(col):
    k = "dt" + _h(col)
    D.add(k, f'<pattern id="{k}" width="10" height="10" patternUnits="userSpaceOnUse">'
             f'<rect width="10" height="10" fill="{col}"/><circle cx="5" cy="5" r="1.3" fill="#FFFFFF" opacity=".12"/></pattern>')
    return f"url(#{k})"


def shape(d, col, kind="wall"):
    """One silhouette piece in the current style. d: a path, or 'rect:x,y,w,h,r' / 'circ:cx,cy,r'."""
    if d.startswith("rect:"):
        x, y, w, h, r = (float(v) for v in d[5:].split(","))
        el = lambda extra="": f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}"{extra}/>'
    elif d.startswith("circ:"):
        cx, cy, r = (float(v) for v in d[5:].split(","))
        el = lambda extra="": f'<circle cx="{cx}" cy="{cy}" r="{r}"{extra}/>'
    else:
        el = lambda extra="": f'<path d="{d}"{extra}/>'
    if STYLE == "frost":
        c = lighter(col, .18)
        return el(f' fill="{c}" filter="{blur(1.6)}"') + el(f' fill="{lighter(c, .35)}" opacity=".35" filter="{blur(6)}"')
    if STYLE == "quilt":
        pat = gingham(col) if kind == "wall" else dots(col)
        return (el(f' fill="{pat}"') + el(f' fill="{weave()}"')
                + el(f' fill="none" stroke="{lighter(col, .5)}" stroke-width="1.3" stroke-dasharray="3.5 2.6" stroke-linecap="round" transform="translate(0 0)"'))
    return el(f' fill="{col}"')


def glow(cx, cy, r, col=WARM2, op=.55):
    if STYLE == "frost":
        r, op = r * 1.5, op * .9
    if STYLE == "quilt":
        r, op = r * .8, op * .7
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{rg([(0, col, op), (.45, col, op * .35), (1, col, 0)])}"/>'


def window(x, y, w, h, lit=True, animal=None, r=3):
    """A window: warm and glowing when lit (with an animal's silhouette in it), dark when off."""
    o = []
    cx, cy = x + w / 2, y + h / 2
    if lit:
        o.append(glow(cx, cy, max(w, h) * 1.25))
        fill = lg([(0, WARM3), (1, WARM)])
        if STYLE == "quilt":
            fill = dots(WARM)
        o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"' + (f' filter="{blur(1)}"' if STYLE == "frost" else "") + "/>")
        if STYLE == "quilt":
            o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="none" stroke="{WARM3}" stroke-width="1.2" stroke-dasharray="3 2.4"/>')
        if animal:
            o.append(f'<g clip-path="{clip(x, y, w, h, r)}">' + ANIMALS[animal](cx, y + h - (h * .06 if w > h * 1.4 else 0), min(w, h) * (.8 if w > h * 1.4 else .95), "#2A2240") + "</g>")
    else:
        o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{OFF}"/>')
        if STYLE == "quilt":
            o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="none" stroke="{lighter(OFF, .35)}" stroke-width="1" stroke-dasharray="3 2.4"/>')
        if animal:
            o.append(f'<g clip-path="{clip(x, y, w, h, r)}">' + ANIMALS[animal](cx, y + h, min(w, h) * .95, lighter(OFF, .14), asleep=True) + "</g>")
            o.append(zz(x + w - 4, y + 6, 5, lighter(OFF, .45)))
    return "".join(o)


def zz(x, y, s, col=DIM, op=.9):
    o = []
    for i, (dx, dy, k) in enumerate(((0, 0, 1.0), (s * .9, -s * 1.3, .75), (s * 1.7, -s * 2.5, .55))):
        z = s * k
        o.append(f'<path d="M{x + dx - z / 2:.1f},{y + dy - z:.1f} h{z:.1f} l{-z:.1f},{z:.1f} h{z:.1f}" fill="none" stroke="{col}" stroke-width="{max(1.2, z * .28):.1f}" stroke-linecap="round" stroke-linejoin="round" opacity="{op}"/>')
    return "".join(o)


# ---------------------------------------------------------------- animals (silhouettes; feet at (cx, by), about s tall)
def _eyes(cx, ey, s, col="#FFF1C2", asleep=False):
    if asleep:
        return (f'<path d="M{cx - s * .2:.1f},{ey:.1f} q{s * .07:.1f},{s * .06:.1f} {s * .14:.1f},0 M{cx + s * .06:.1f},{ey:.1f} q{s * .07:.1f},{s * .06:.1f} {s * .14:.1f},0" '
                f'fill="none" stroke="{col}" stroke-width="{max(1.2, s * .035):.1f}" stroke-linecap="round" opacity=".8"/>')
    return f'<circle cx="{cx - s * .13:.1f}" cy="{ey:.1f}" r="{s * .045:.1f}" fill="{col}"/><circle cx="{cx + s * .13:.1f}" cy="{ey:.1f}" r="{s * .045:.1f}" fill="{col}"/>'


def a_cat(cx, by, s, col, asleep=False, yawn=False):
    hy = by - s * .62
    o = [f'<ellipse cx="{cx:.1f}" cy="{by - s * .28:.1f}" rx="{s * .3:.1f}" ry="{s * .3:.1f}" fill="{col}"/>',
         f'<path d="M{cx - s * .3:.1f},{by - s * .25:.1f} q{-s * .25:.1f},{-s * .1:.1f} {-s * .14:.1f},{-s * .42:.1f}" fill="none" stroke="{col}" stroke-width="{s * .09:.1f}" stroke-linecap="round"/>',
         f'<circle cx="{cx:.1f}" cy="{hy:.1f}" r="{s * .26:.1f}" fill="{col}"/>',
         f'<path d="M{cx - s * .24:.1f},{hy - s * .1:.1f} l{-s * .04:.1f},{-s * .28:.1f} l{s * .2:.1f},{s * .14:.1f}Z M{cx + s * .24:.1f},{hy - s * .1:.1f} l{s * .04:.1f},{-s * .28:.1f} l{-s * .2:.1f},{s * .14:.1f}Z" fill="{col}"/>',
         _eyes(cx, hy - s * .02, s, asleep=asleep)]
    if yawn:
        o.append(f'<ellipse cx="{cx:.1f}" cy="{hy + s * .12:.1f}" rx="{s * .06:.1f}" ry="{s * .08:.1f}" fill="#FFF1C2" opacity=".85"/>')
    return "".join(o)


def a_bunny(cx, by, s, col, asleep=False, yawn=False):
    hy = by - s * .5
    o = [f'<ellipse cx="{cx:.1f}" cy="{by - s * .22:.1f}" rx="{s * .3:.1f}" ry="{s * .25:.1f}" fill="{col}"/>',
         f'<circle cx="{cx:.1f}" cy="{hy:.1f}" r="{s * .25:.1f}" fill="{col}"/>',
         f'<ellipse cx="{cx - s * .12:.1f}" cy="{hy - s * .42:.1f}" rx="{s * .07:.1f}" ry="{s * .26:.1f}" fill="{col}" transform="rotate(-10 {cx - s * .12:.1f} {hy - s * .42:.1f})"/>',
         f'<ellipse cx="{cx + s * .12:.1f}" cy="{hy - s * .42:.1f}" rx="{s * .07:.1f}" ry="{s * .26:.1f}" fill="{col}" transform="rotate(12 {cx + s * .12:.1f} {hy - s * .42:.1f})"/>',
         _eyes(cx, hy - s * .02, s, asleep=asleep)]
    if yawn:
        o.append(f'<ellipse cx="{cx:.1f}" cy="{hy + s * .11:.1f}" rx="{s * .06:.1f}" ry="{s * .075:.1f}" fill="#FFF1C2" opacity=".85"/>')
    return "".join(o)


def a_bear(cx, by, s, col, asleep=False, yawn=False):
    hy = by - s * .55
    o = [f'<ellipse cx="{cx:.1f}" cy="{by - s * .24:.1f}" rx="{s * .34:.1f}" ry="{s * .28:.1f}" fill="{col}"/>',
         f'<circle cx="{cx - s * .22:.1f}" cy="{hy - s * .22:.1f}" r="{s * .1:.1f}" fill="{col}"/><circle cx="{cx + s * .22:.1f}" cy="{hy - s * .22:.1f}" r="{s * .1:.1f}" fill="{col}"/>',
         f'<circle cx="{cx:.1f}" cy="{hy:.1f}" r="{s * .28:.1f}" fill="{col}"/>',
         _eyes(cx, hy - s * .03, s, asleep=asleep),
         f'<circle cx="{cx:.1f}" cy="{hy + s * .09:.1f}" r="{s * .035:.1f}" fill="#FFF1C2" opacity=".7"/>']
    return "".join(o)


def a_duck(cx, by, s, col, asleep=False, yawn=False):
    hy = by - s * .55
    return "".join([f'<ellipse cx="{cx:.1f}" cy="{by - s * .22:.1f}" rx="{s * .34:.1f}" ry="{s * .22:.1f}" fill="{col}"/>',
                    f'<circle cx="{cx + s * .05:.1f}" cy="{hy:.1f}" r="{s * .22:.1f}" fill="{col}"/>',
                    f'<path d="M{cx + s * .22:.1f},{hy + s * .02:.1f} l{s * .22:.1f},{s * .05:.1f} l{-s * .22:.1f},{s * .08:.1f}Z" fill="{col}"/>',
                    _eyes(cx + s * .05, hy - s * .04, s * .8, asleep=asleep)])


def a_pig(cx, by, s, col, asleep=False, yawn=False):
    hy = by - s * .5
    return "".join([f'<ellipse cx="{cx:.1f}" cy="{by - s * .22:.1f}" rx="{s * .36:.1f}" ry="{s * .25:.1f}" fill="{col}"/>',
                    f'<path d="M{cx - s * .28:.1f},{hy - s * .1:.1f} l{-s * .02:.1f},{-s * .22:.1f} l{s * .2:.1f},{s * .1:.1f}Z M{cx + s * .28:.1f},{hy - s * .1:.1f} l{s * .02:.1f},{-s * .22:.1f} l{-s * .2:.1f},{s * .1:.1f}Z" fill="{col}"/>',
                    f'<circle cx="{cx:.1f}" cy="{hy:.1f}" r="{s * .28:.1f}" fill="{col}"/>',
                    _eyes(cx, hy - s * .05, s, asleep=asleep),
                    f'<ellipse cx="{cx:.1f}" cy="{hy + s * .1:.1f}" rx="{s * .1:.1f}" ry="{s * .065:.1f}" fill="#FFF1C2" opacity=".55"/>',
                    f'<circle cx="{cx - s * .035:.1f}" cy="{hy + s * .1:.1f}" r="{s * .02:.1f}" fill="{col}"/><circle cx="{cx + s * .035:.1f}" cy="{hy + s * .1:.1f}" r="{s * .02:.1f}" fill="{col}"/>'])


def a_owl(cx, by, s, col, asleep=False, yawn=False):
    hy = by - s * .5
    return "".join([f'<ellipse cx="{cx:.1f}" cy="{by - s * .36:.1f}" rx="{s * .3:.1f}" ry="{s * .4:.1f}" fill="{col}"/>',
                    f'<path d="M{cx - s * .28:.1f},{hy - s * .2:.1f} l{-s * .06:.1f},{-s * .22:.1f} l{s * .22:.1f},{s * .1:.1f}Z M{cx + s * .28:.1f},{hy - s * .2:.1f} l{s * .06:.1f},{-s * .22:.1f} l{-s * .22:.1f},{s * .1:.1f}Z" fill="{col}"/>',
                    f'<circle cx="{cx - s * .13:.1f}" cy="{hy - s * .05:.1f}" r="{s * .1:.1f}" fill="#FFF1C2" opacity=".9"/><circle cx="{cx + s * .13:.1f}" cy="{hy - s * .05:.1f}" r="{s * .1:.1f}" fill="#FFF1C2" opacity=".9"/>',
                    (f'<circle cx="{cx - s * .13:.1f}" cy="{hy - s * .05:.1f}" r="{s * .045:.1f}" fill="{col}"/><circle cx="{cx + s * .13:.1f}" cy="{hy - s * .05:.1f}" r="{s * .045:.1f}" fill="{col}"/>' if not asleep else
                     f'<path d="M{cx - s * .22:.1f},{hy - s * .05:.1f} h{s * .18:.1f} M{cx + s * .04:.1f},{hy - s * .05:.1f} h{s * .18:.1f}" stroke="{col}" stroke-width="{s * .04:.1f}" stroke-linecap="round"/>'),
                    f'<path d="M{cx - s * .04:.1f},{hy + s * .06:.1f} l{s * .04:.1f},{s * .08:.1f} l{s * .04:.1f},{-s * .08:.1f}Z" fill="#FFF1C2" opacity=".8"/>'])


def a_dog(cx, by, s, col, asleep=False, yawn=False):
    hy = by - s * .55
    return "".join([f'<ellipse cx="{cx:.1f}" cy="{by - s * .24:.1f}" rx="{s * .34:.1f}" ry="{s * .26:.1f}" fill="{col}"/>',
                    f'<path d="M{cx + s * .3:.1f},{by - s * .3:.1f} q{s * .15:.1f},{-s * .2:.1f} {s * .08:.1f},{-s * .34:.1f}" fill="none" stroke="{col}" stroke-width="{s * .08:.1f}" stroke-linecap="round"/>',
                    f'<circle cx="{cx:.1f}" cy="{hy:.1f}" r="{s * .27:.1f}" fill="{col}"/>',
                    f'<ellipse cx="{cx - s * .27:.1f}" cy="{hy + s * .02:.1f}" rx="{s * .09:.1f}" ry="{s * .2:.1f}" fill="{col}"/><ellipse cx="{cx + s * .27:.1f}" cy="{hy + s * .02:.1f}" rx="{s * .09:.1f}" ry="{s * .2:.1f}" fill="{col}"/>',
                    _eyes(cx, hy - s * .04, s, asleep=asleep),
                    f'<ellipse cx="{cx:.1f}" cy="{hy + s * .08:.1f}" rx="{s * .05:.1f}" ry="{s * .035:.1f}" fill="#FFF1C2" opacity=".7"/>'])


def a_sheep(cx, by, s, col="#F3EEE4", asleep=False, hop=False):
    """A fluffy sheep facing right (the one who hops the fence)."""
    dark = "#2B2A3C"
    o = []
    for i, (dx, dy, r) in enumerate(((-.3, -.3, .22), (-.1, -.38, .24), (.12, -.36, .23), (.3, -.28, .2), (0, -.22, .3))):
        o.append(f'<circle cx="{cx + dx * s:.1f}" cy="{by + dy * s:.1f}" r="{r * s:.1f}" fill="{col}"/>')
    legs = ((-.2, -.08, -.26, .0), (.18, -.08, .26, .0)) if hop else ((-.2, 0, -.2, 0), (.18, 0, .18, 0))
    for x1, y1, x2, y2 in legs:
        o.append(f'<path d="M{cx + x1 * s:.1f},{by - s * .05:.1f} L{cx + x2 * s:.1f},{by + s * .02:.1f}" stroke="{dark}" stroke-width="{s * .07:.1f}" stroke-linecap="round"/>')
    hx, hy = cx + s * .38, by - s * .42
    o.append(f'<ellipse cx="{hx:.1f}" cy="{hy:.1f}" rx="{s * .2:.1f}" ry="{s * .17:.1f}" fill="{dark}"/>')
    o.append(f'<ellipse cx="{hx - s * .12:.1f}" cy="{hy - s * .08:.1f}" rx="{s * .09:.1f}" ry="{s * .05:.1f}" fill="{dark}" transform="rotate(-25 {hx - s * .12:.1f} {hy - s * .08:.1f})"/>')
    o.append(f'<circle cx="{hx - s * .02:.1f}" cy="{hy - s * .22:.1f}" r="{s * .1:.1f}" fill="{col}"/>')
    if asleep:
        o.append(f'<path d="M{hx + s * .02:.1f},{hy - s * .02:.1f} q{s * .05:.1f},{s * .05:.1f} {s * .1:.1f},0" fill="none" stroke="{col}" stroke-width="1.6" stroke-linecap="round"/>')
    else:
        o.append(f'<circle cx="{hx + s * .07:.1f}" cy="{hy - s * .03:.1f}" r="{s * .03:.1f}" fill="{col}"/>')
    return "".join(o)


ANIMALS = {"cat": a_cat, "bunny": a_bunny, "bear": a_bear, "duck": a_duck, "pig": a_pig, "owl": a_owl, "dog": a_dog}


# ================================================================ SKY, MOON, STARS
def sky(w, h, mode="night"):
    if mode == "dusk":
        g = lg([(0, "#1A2650"), (.45, "#3D3A6E"), (.75, "#8A5577"), (1, "#E3875C")])
    elif mode == "morning":
        g = lg([(0, "#9AD1F0"), (.6, "#CFE8F5"), (1, "#FFE2B8")])
    elif mode == "deep":
        g = lg([(0, "#070E22"), (.6, "#101B3A"), (1, "#1A2850")])
    else:
        g = lg([(0, "#0D1733"), (.55, "#1A2A52"), (1, "#2F3F70")])
    if STYLE == "quilt" and mode == "night":
        g = dots("#1A2650")
    return f'<rect width="{w}" height="{h}" fill="{g}"/>'


def stars(w, h, n=60, seed=3, op=1.0, big=4):
    r = lcg(seed)
    o = []
    for i in range(n):
        x, y, k = next(r) * w, next(r) * h, next(r)
        rad = .8 + k * 1.3
        o.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rad:.1f}" fill="{STAR}" opacity="{(.35 + k * .55) * op:.2f}"/>')
    spots = ((.12, .48), (.58, .22), (.86, .62), (.3, .8), (.7, .9))
    for i in range(min(big, len(spots))):
        x, y = spots[i][0] * w, spots[i][1] * h
        s = 5 + (i % 3) * 1.5
        o.append(f'<path d="M{x:.1f},{y - s:.1f} Q{x:.1f},{y:.1f} {x + s:.1f},{y:.1f} Q{x:.1f},{y:.1f} {x:.1f},{y + s:.1f} Q{x:.1f},{y:.1f} {x - s:.1f},{y:.1f} Q{x:.1f},{y:.1f} {x:.1f},{y - s:.1f}Z" fill="{STAR}" opacity="{.8 * op:.2f}"/>')
    return "".join(o)


def moon(cx, cy, r, crescent=True, face=True, col="#FFF0B9"):
    o = [glow(cx, cy, r * 2.6, col, .35)]
    if crescent:
        k = "mc" + _h(cx, cy, r)
        D.add(k, f'<mask id="{k}"><circle cx="{cx}" cy="{cy}" r="{r}" fill="#fff"/><circle cx="{cx + r * .55}" cy="{cy - r * .35}" r="{r * .85}" fill="#000"/></mask>')
        o.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{col}" mask="url(#{k})"/>')
        if face:
            o.append(f'<path d="M{cx - r * .45:.1f},{cy - r * .05:.1f} q{r * .08:.1f},{r * .1:.1f} {r * .16:.1f},0" fill="none" stroke="#B49A5E" stroke-width="{r * .07:.1f}" stroke-linecap="round"/>')
            o.append(f'<path d="M{cx - r * .42:.1f},{cy + r * .3:.1f} q{r * .1:.1f},{r * .12:.1f} {r * .22:.1f},{r * .02:.1f}" fill="none" stroke="#B49A5E" stroke-width="{r * .06:.1f}" stroke-linecap="round"/>')
    else:
        o.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{rg([(0, "#FFF8DC"), (.8, col), (1, mixc(col, "#E8C57A", .5))])}"/>')
        if face:
            for sx in (-1, 1):
                o.append(f'<path d="M{cx + sx * r * .3 - r * .09:.1f},{cy - r * .08:.1f} q{r * .09:.1f},{r * .12:.1f} {r * .18:.1f},0" fill="none" stroke="#B49A5E" stroke-width="{r * .05:.1f}" stroke-linecap="round"/>')
            o.append(f'<path d="M{cx - r * .1:.1f},{cy + r * .22:.1f} q{r * .1:.1f},{r * .1:.1f} {r * .2:.1f},0" fill="none" stroke="#B49A5E" stroke-width="{r * .045:.1f}" stroke-linecap="round"/>')
            o.append(f'<circle cx="{cx - r * .42:.1f}" cy="{cy + r * .12:.1f}" r="{r * .08:.1f}" fill="#F5B9A8" opacity=".5"/><circle cx="{cx + r * .42:.1f}" cy="{cy + r * .12:.1f}" r="{r * .08:.1f}" fill="#F5B9A8" opacity=".5"/>')
    return "".join(o)


# ================================================================ THE TOWN (designed in a 390 x 600 box; the ground line is y = 540)
# lights: name -> (x, y, w, h, animal). Each one is a thing the child taps to turn off.
LIGHTS = {
    "w1": (46, 262, 30, 34, "cat"), "w2": (46, 318, 30, 34, "duck"),
    "w3": (150, 212, 32, 36, "bunny"), "w4": (150, 268, 32, 36, "bear"), "w5": (200, 268, 32, 36, None),
    "w6": (284, 282, 30, 34, "pig"), "w7": (330, 282, 30, 34, "owl"),
    "shop": (144, 432, 110, 60, "dog"),     # the 早餐店's bright front
    "lantern": (300, 436, 0, 0, None),      # the 小吃店's red lantern
    "sign": (268, 398, 112, 22, None),      # the 便利商店's sign box
    "lamp": (90, 330, 0, 0, None),          # the street lamp
}


def town(lit=None, mode="night", yawn=None, finger=None):
    """The whole street. lit: the names of the lights that are still on (None = all). yawn: the name of the
    window whose animal is yawning right now."""
    lit = set(LIGHTS) if lit is None else set(lit)
    dusk = mode == "dusk"
    morning = mode == "morning"
    if morning:
        back, mid, front, ground, hill = "#9FB6CC", "#B7C7DA", "#C9D4E2", "#A7B8A3", "#B5CBB0"
    elif STYLE == "frost":
        back, mid, front, ground, hill = "#3A4878", "#2F3D6A", "#26335C", "#1F2A4E", "#34437A"
    elif STYLE == "quilt":
        back, mid, front, ground, hill = "#3B4B7C", "#2F3E6C", "#263460", "#1E2A50", "#36467C"
    else:
        back, mid, front, ground, hill = ("#2C2F5E", "#20244C", "#171A3C", "#101230", "#2B2A58") if dusk else ("#1C2A4E", "#162040", "#0F1731", "#0A1024", "#1D2D52")
    o = []
    # hills far away
    o.append(shape("M-10,400 Q60,330 150,372 Q230,320 320,364 Q360,350 400,372 L400,560 L-10,560Z", hill, "hill"))
    # back row: three apartment blocks with Taiwanese flat roofs, water tanks, a tin-roof add-on
    o.append(shape("rect:28,240,70,300,3", back))                          # left block
    o.append(shape("rect:40,218,20,22,2", back) + shape("rect:70,226,16,14,2", back))   # water tank + stairwell
    o.append(shape("M50,218 h0 M44,218 l8,-14 l8,14Z", back))              # a little peak on the tank
    o.append(shape("rect:136,190,112,350,3", back))                        # middle, tallest
    o.append(shape("M136,190 L160,170 L248,170 L248,190Z", back))          # tin-roof add-on (鐵皮屋)
    o.append(shape("rect:236,150,5,40,1", back) + shape("rect:226,158,25,4,1", back))   # TV antenna
    o.append(shape("rect:272,262,100,278,3", back))                        # right block
    o.append(shape("rect:356,236,10,26,1", back))                          # chimney pipe
    # iron window grilles: a lighter frame around the back windows
    for name in ("w1", "w2", "w3", "w4", "w5", "w6", "w7"):
        x, y, w, h, an = LIGHTS[name]
        o.append(window(x, y, w, h, name in lit, an))
        if STYLE != "frost":
            o.append(f'<rect x="{x - 3}" y="{y - 3}" width="{w + 6}" height="{h + 6}" rx="3" fill="none" stroke="{lighter(back, .18)}" stroke-width="2"/>')
            o.append(f'<path d="M{x + w / 2:.0f},{y - 3} v{h + 6} M{x - 3},{y + h / 2:.0f} h{w + 6}" stroke="{lighter(back, .12)}" stroke-width="1.2"/>')
        if yawn == name and an:
            o.append(ANIMALS[an](x + w / 2, y + h, min(w, h) * .95, "#2A2240", yawn=True))
    # balcony with laundry on the middle block
    o.append(shape("rect:150,318,84,6,2", mid) + shape("rect:150,324,84,16,1", mid))
    o.append(f'<path d="M156,310 h72" stroke="{lighter(back, .25)}" stroke-width="1.5"/>')
    for i, x in enumerate((164, 184, 206)):
        o.append(shape(f"M{x},311 l-5,14 h18 l-5,-14Z", lighter(mid, .22), "cloth"))
    # front row: 騎樓 shops (arcade with round arches), 早餐店 / 小吃店 / 便利商店
    o.append(shape("rect:0,380,390,160,0", front))
    o.append(shape("M0,380 L390,380 L390,372 L0,372Z", lighter(front, .1)))
    # arches
    for x in (18, 108, 268, 350):
        o.append(f'<path d="M{x},540 V468 A24,24 0 0 1 {x + 48},468 V540Z" fill="{darker(front, .35)}"/>')
    # the 早餐店's bright front (a wide window-door with the dog)
    x, y, w, h, an = LIGHTS["shop"]
    o.append(window(x, y, w, h, "shop" in lit, an, r=5))
    o.append(f'<rect x="{x - 4}" y="{y - 4}" width="{w + 8}" height="{h + 8}" rx="6" fill="none" stroke="{lighter(front, .25)}" stroke-width="3"/>')
    # 招牌 above the shop (a little sign board with three bars = words)
    o.append(shape("rect:150,404,98,20,4", lighter(front, .14)))
    for i in range(3):
        o.append(f'<rect x="{166 + i * 24}" y="409" width="16" height="10" rx="2" fill="{lighter(front, .35)}" opacity=".9"/>')
    # 小吃店's red lantern
    lx, ly = LIGHTS["lantern"][:2]
    o.append(f'<path d="M{lx},412 v10" stroke="{lighter(front, .3)}" stroke-width="2"/>')
    if "lantern" in lit:
        o.append(glow(lx, ly + 10, 40, "#FF7A5C", .5))
        o.append(f'<ellipse cx="{lx}" cy="{ly + 12}" rx="13" ry="16" fill="#F26B5A"/><path d="M{lx - 6},{ly + 1} v22 M{lx + 6},{ly + 1} v22" stroke="#C94E40" stroke-width="1.5"/>'
                 f'<rect x="{lx - 5}" y="{ly - 4}" width="10" height="5" rx="1.5" fill="#D9A441"/><path d="M{lx},{ly + 28} v8" stroke="#D9A441" stroke-width="2"/>')
    else:
        o.append(f'<ellipse cx="{lx}" cy="{ly + 12}" rx="13" ry="16" fill="{lighter(front, .1)}"/><rect x="{lx - 5}" y="{ly - 4}" width="10" height="5" rx="1.5" fill="{lighter(front, .2)}"/>')
    # 便利商店 sign on the far right: a lit box with three stripes when on, a dark box when off
    sx, sy, sw, sh_, _ = LIGHTS["sign"]
    if "sign" in lit:
        o.append(glow(sx + sw / 2, sy + sh_ / 2, 60, WARM2, .4))
        o.append(f'<rect x="{sx}" y="{sy}" width="{sw}" height="{sh_}" rx="4" fill="{WARM3}"/>')
        for i, c in enumerate(("#E8803A", "#3E9E5E", "#D9534F")):
            o.append(f'<rect x="{sx + 8}" y="{sy + 4 + i * 5}" width="{sw - 16}" height="3.5" rx="1.5" fill="{c}" opacity=".85"/>')
    else:
        o.append(f'<rect x="{sx}" y="{sy}" width="{sw}" height="{sh_}" rx="4" fill="{lighter(front, .12)}"/>')
    # the street lamp (in front of everything, a little lighter so it reads against the shops)
    lx, ly = LIGHTS["lamp"][:2]
    pc = lighter(front, .22)
    o.append(shape(f"rect:{lx - 2.5},{ly},5,210,2", pc, "pole"))
    o.append(f'<path d="M{lx - 1},{ly} q0,-22 22,-22 h12" fill="none" stroke="{pc}" stroke-width="5" stroke-linecap="round"/>')
    if "lamp" in lit:
        o.append(glow(lx + 32, ly - 20, 46, WARM2, .6))
        o.append(f'<path d="M{lx + 22},{ly - 24} h22 l-4,10 h-14Z" fill="{WARM}"/>')
        o.append(f'<path d="M{lx + 22},{ly - 14} L{lx + 10},540 L{lx + 56},540 Z" fill="{WARM}" opacity=".10"/>')
    else:
        o.append(f'<path d="M{lx + 22},{ly - 24} h22 l-4,10 h-14Z" fill="{lighter(front, .3)}"/>')
    # the ground: road, a 郵筒 (red + green), a scooter
    o.append(f'<rect x="0" y="540" width="390" height="60" fill="{ground}"/>')
    o.append(f'<path d="M0,552 H390" stroke="{lighter(ground, .14)}" stroke-width="2" stroke-dasharray="14 10"/>')
    o.append(shape("rect:236,506,12,34,3", "#C0392B" if not morning else "#D9534F", "box") + shape("rect:250,506,12,34,3", "#2E8B57", "box"))
    o.append(shape("rect:234,500,30,8,3", lighter(front, .1)))
    o.append(scooter(330, 540, lighter(front, .2) if not morning else "#7A8BA3"))
    return "".join(o)


def scooter(x, y, col):
    return (f'<circle cx="{x - 18}" cy="{y - 8}" r="8" fill="{col}"/><circle cx="{x + 18}" cy="{y - 8}" r="8" fill="{col}"/>'
            f'<path d="M{x - 18},{y - 14} q6,-12 22,-10 l6,-18 h8 M{x + 2},{y - 24} q-12,-4 -14,6 q12,6 24,0" fill="none" stroke="{col}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<rect x="{x - 10}" y="{y - 30}" width="24" height="8" rx="4" fill="{col}"/>')


def town_block(x, y, w, h, lit=None, mode="night", yawn=None, crop_top=0, with_sky=True, moon_at=None, star_op=1.0):
    """The town fitted into a w x h box (designed 390 wide, ground at 540)."""
    s = w / 390
    th = 600 * s
    inner = ""
    if with_sky:
        inner += sky(390, 640, mode)
        if mode != "morning":
            inner += stars(390, 420, 70, 5, star_op)
        if moon_at:
            inner += moon(*moon_at)
    inner += town(lit, mode, yawn)
    o = [f'<g clip-path="{clip(x, y, w, h)}"><g transform="translate({x} {y - crop_top * s}) scale({s:.4f})">{inner}</g></g>']
    return "".join(o)


def finger(x, y, s=1.0, col="#F3D9C3"):
    """A little pointing hand with soft ripples where it touches."""
    return (f'<circle cx="{x}" cy="{y}" r="{14 * s}" fill="none" stroke="#FFFFFF" stroke-width="2" opacity=".55"/>'
            f'<circle cx="{x}" cy="{y}" r="{24 * s}" fill="none" stroke="#FFFFFF" stroke-width="1.5" opacity=".3"/>'
            f'<g transform="translate({x} {y}) scale({s})">'
            f'<path d="M-2,4 q-14,-2 -16,10 q0,22 10,32 q14,8 28,0 q10,-10 8,-24 l-2,-6 q-3,-6 -8,-2 l-2,6 l-2,-8 q-3,-6 -8,-2 l-1,6 L4,-4 q-1,-8 -8,-6 q-5,1 -5,8 Z" fill="{col}" stroke="#D9B79B" stroke-width="1.5" stroke-linejoin="round"/>'
            f'</g>')


def soft_bubble(x, y, w, h, s, size=17, col="#1C2743", textcol=CREAM, op=.85):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h / 2}" fill="{col}" opacity="{op}" stroke="#6B7AA8" stroke-opacity=".5"/>'
            + tx(x + w / 2, y + h / 2 + size * .36, s, size, textcol))


def top_bar(title, light=False):
    """A tiny title and a quiet 'close' button; everything stays dim."""
    col = INK if light else DIM
    o = [tx(W / 2, 54, title, 15, col, op=.9)]
    o.append(f'<circle cx="{W - 34}" cy="48" r="16" fill="{"#E9E3D9" if light else "#FFFFFF"}" opacity="{1 if light else .08}"/>'
             f'<path d="M{W - 40},42 l12,12 M{W - 28},42 l-12,12" stroke="{col}" stroke-width="2" stroke-linecap="round" opacity=".8"/>')
    return "".join(o)


# ================================================================ SCREENS
def screen_dusk():
    """1: 關燈巡邏 begins. Dusk, every light on, a quiet prompt."""
    o = [f'<rect width="{W}" height="{H}" fill="{lg([(0, "#141E44"), (.4, "#3A376E"), (.68, "#8A5577"), (.82, "#E3875C"), (1, "#F2B06A")])}"/>',
         stars(W, 420, 40, 2, .6, 2), moon(326, 214, 28)]
    o.append(town_block(0, 244, W, 600, None, "dusk", with_sky=False))
    o.append(top_bar("關燈巡邏"))
    o.append(soft_bubble(55, 112, 280, 46, "天黑了，幫大家關燈吧", 19, "#241F3E", CREAM, .82))
    o.append(tx(W / 2, 192, "點一下亮著的窗戶和燈", 14, DIM, op=.85))
    x, y, w, h, _ = LIGHTS["w3"]
    o.append(finger(x + w + 8, 244 + y + h + 6, .9))
    return page("".join(o), "#1A2650")


def screen_lightoff():
    """2: a window is tapped: the bunny yawns, the window goes dark; half the town already asleep."""
    lit = {"w3", "w5", "w6", "shop", "lantern"}
    o = [sky(W, H, "night"), stars(W, 420, 60, 7, 1.0, 3), moon(326, 214, 28)]
    o.append(town_block(0, 244, W, 600, lit, "night", yawn="w3", with_sky=False))
    o.append(top_bar("關燈巡邏"))
    x, y, w, h, _ = LIGHTS["w3"]
    cx, cy = x + w / 2, 244 + y
    o.append(soft_bubble(cx - 52, cy - 70, 104, 40, "哈～～", 18, "#241F3E", CREAM, .85))
    o.append(f'<path d="M{cx - 6},{cy - 30} l6,10 l6,-10Z" fill="#241F3E" opacity=".85"/>')
    o.append(finger(x + w + 8, cy + h + 6, .9))
    o.append(tx(W / 2, 136, "小兔子打哈欠了，晚安～", 17, CREAM, op=.9))
    o.append(tx(W / 2, 164, "還有 5 盞燈亮著", 13, DIM, op=.8))
    return page("".join(o), "#0D1733")


def fence(x, y, w, col):
    o = [f'<rect x="{x}" y="{y + 14}" width="{w}" height="7" rx="3" fill="{col}"/><rect x="{x}" y="{y + 36}" width="{w}" height="7" rx="3" fill="{col}"/>']
    n = max(2, int(w / 34))
    for i in range(n + 1):
        px = x + i * w / n
        o.append(f'<path d="M{px - 6},{y + 58} v-50 l6,-8 l6,8 v50Z" fill="{col}"/>')
    return "".join(o)


def screen_sheep():
    """3: 數羊. One sheep hops the fence very slowly; the number is said in Mandarin."""
    o = [sky(W, H, "night"), stars(W, 420, 70, 11), moon(300, 110, 36)]
    # a soft meadow
    o.append(f'<path d="M0,520 Q100,470 200,500 Q300,530 390,490 L390,844 L0,844Z" fill="#17254A"/>')
    o.append(f'<path d="M0,600 Q130,560 250,590 Q330,610 390,580 L390,844 L0,844Z" fill="#111C3A"/>')
    # the big number, dim and slow
    o.append(tx(W / 2, 300, "3", 128, WARM3, op=.95))
    o.append(tx(W / 2, 352, "三", 36, WARM3, op=.9))
    o.append(tx(W / 2, 392, "第三隻小羊，跳過去了", 17, DIM, op=.9))
    # fence and the hopping sheep
    o.append(fence(120, 540, 150, "#2A3A66"))
    o.append(f'<path d="M60,610 Q130,500 200,590" fill="none" stroke="{WARM3}" stroke-width="2" stroke-dasharray="2 9" stroke-linecap="round" opacity=".5"/>')
    o.append(f'<g transform="rotate(-12 130 520)">' + a_sheep(130, 520, 72, "#F1ECE1", hop=True) + "</g>")
    # the sheep that already crossed, sleeping in a row; the ones waiting on the left
    o.append(a_sheep(276, 640, 48, "#D8D4CD", asleep=True) + a_sheep(338, 640, 48, "#D8D4CD", asleep=True))
    o.append(zz(300, 598, 6, DIM, .7))
    for i, x in enumerate((26, 70)):
        o.append(a_sheep(x, 652 + i * 2, 44, "#E8E3D8"))
    o.append(top_bar("數羊"))
    o.append(tx(W / 2, 760, "點一下，下一隻小羊才會跳", 14, DIM, op=.8))
    o.append(tx(W / 2, 784, "數到 10 就好", 13, DIM, op=.6))
    return page("".join(o), "#0D1733")


def screen_story():
    """4: 晚安故事. One page: a small picture, big slow words, read by the app or by the parent."""
    o = [sky(W, H, "deep"), stars(W, 300, 40, 13, .7, 2)]
    o.append(top_bar("晚安故事"))
    # picture: a tree, an owl, the little cat looking at a star
    px, py, pw, ph = 30, 84, 330, 250
    o.append(f'<rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="22" fill="{lg([(0, "#16244A"), (1, "#24356A")])}"/>')
    o.append(f'<g clip-path="{clip(px, py, pw, ph, 22)}">' + stars(pw, ph * .7, 25, 21, .8, 1).replace("<circle", f'<circle transform="translate({px} {py})"').replace("<path", f'<path transform="translate({px} {py})"') + "</g>")
    o.append(moon(px + 270, py + 60, 24, face=False))
    o.append(f'<path d="M{px},{py + 190} Q{px + 80},{py + 160} {px + 160},{py + 185} Q{px + 250},{py + 205} {px + pw},{py + 175} V{py + ph} H{px}Z" fill="#0E1733"/>')
    tx_, ty = px + 80, py + 190
    o.append(f'<rect x="{tx_ - 7}" y="{ty - 70}" width="14" height="72" rx="4" fill="#0B1229"/>')
    o.append(f'<circle cx="{tx_}" cy="{ty - 95}" r="46" fill="#0B1229"/><circle cx="{tx_ - 34}" cy="{ty - 72}" r="30" fill="#0B1229"/><circle cx="{tx_ + 36}" cy="{ty - 70}" r="32" fill="#0B1229"/>')
    o.append(f'<path d="M{tx_ + 4},{ty - 56} q50,-6 96,-12" fill="none" stroke="#0B1229" stroke-width="6" stroke-linecap="round"/>')
    o.append(a_owl(tx_ + 96, ty - 68, 40, "#0B1229"))
    o.append(a_cat(px + 230, ty + 2, 56, "#0B1229"))
    sx, sy = px + 205, py + 70
    o.append(glow(sx, sy, 22, STAR, .5) + f'<path d="M{sx},{sy - 9} Q{sx},{sy} {sx + 9},{sy} Q{sx},{sy} {sx},{sy + 9} Q{sx},{sy} {sx - 9},{sy} Q{sx},{sy} {sx},{sy - 9}Z" fill="{STAR}"/>')
    o.append(f'<path d="M{sx + 20},{sy - 40} Q{sx + 10},{sy - 20} {sx + 2},{sy - 12}" fill="none" stroke="{STAR}" stroke-width="1.5" stroke-dasharray="2 5" opacity=".6"/>')
    # the words: big, few, slow
    lines = ["小貓咪坐在屋頂上，", "看到一顆小星星，", "慢慢地、慢慢地，", "掉到樹上，", "被貓頭鷹接住了。"]
    for i, ln in enumerate(lines):
        o.append(tx(W / 2, 400 + i * 44, ln, 23, CREAM, op=.95))
    # page dots
    for i in range(5):
        o.append(f'<circle cx="{W / 2 - 32 + i * 16}" cy="640" r="{5 if i == 1 else 3.5}" fill="{WARM3 if i == 1 else DIM}" opacity="{1 if i == 1 else .5}"/>')
    # buttons: read to me / next page (big, dim, two only)
    o.append(pill(32, 690, 150, 56, "#22304F", "#6B7AA8"))
    o.append(f'<path d="M62,718 q0,-10 8,-10 q8,0 8,10 M62,718 q0,10 8,10 q8,0 8,-10 M66,710 v16" fill="none" stroke="{CREAM}" stroke-width="2" stroke-linecap="round" opacity=".9"/>')
    o.append(tx(124, 725, "念給我聽", 18, CREAM))
    o.append(pill(208, 690, 150, 56, "#22304F", "#6B7AA8"))
    o.append(tx(272, 725, "下一頁", 18, CREAM))
    o.append(f'<path d="M322,710 l9,8 l-9,8" fill="none" stroke="{CREAM}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>')
    o.append(tx(W / 2, 790, "今天的故事：小貓咪 ＋ 屋頂 ＋ 小星星（第 2 頁，共 5 頁）", 12, DIM, op=.7))
    return page("".join(o), "#070E22")


def screen_breath():
    """5: 呼吸小月亮. Press and hold: the moon grows while breathing in, shrinks while breathing out, 3 times."""
    o = [sky(W, H, "deep"), stars(W, 500, 60, 17, .7, 3)]
    o.append(top_bar("呼吸小月亮"))
    cx, cy = W / 2, 400
    o.append(f'<circle cx="{cx}" cy="{cy}" r="132" fill="none" stroke="{DIM}" stroke-width="1.5" stroke-dasharray="3 7" opacity=".45"/>')
    o.append(f'<circle cx="{cx}" cy="{cy}" r="70" fill="none" stroke="{DIM}" stroke-width="1" stroke-dasharray="3 7" opacity=".3"/>')
    o.append(moon(cx, cy, 104, crescent=False))
    o.append(tx(W / 2, 170, "吸氣……", 34, WARM3, op=.95))
    o.append(tx(W / 2, 206, "小月亮慢慢變大", 16, DIM, op=.85))
    # three breaths: two done, one going
    for i in range(3):
        done = i < 1
        now = i == 1
        o.append(f'<circle cx="{W / 2 - 36 + i * 36}" cy="600" r="{9 if now else 7}" fill="{WARM3 if done or now else "none"}" stroke="{WARM3 if not done and not now else "none"}" stroke-width="1.5" opacity="{1 if now else .6}"/>')
    o.append(tx(W / 2, 646, "按住小月亮，跟著一起吸氣；", 16, CREAM, op=.85))
    o.append(tx(W / 2, 672, "放開，慢慢吐氣。三次就好。", 16, CREAM, op=.85))
    o.append(finger(cx + 26, cy + 62, 1.0))
    return page("".join(o), "#070E22")


def wave(x, y, w, col, amp=4, n=3):
    seg = w / n
    d = f"M{x},{y}" + "".join(f" q{seg / 4:.1f},{-amp} {seg / 2:.1f},0 t{seg / 2:.1f},0" for _ in range(n))
    return f'<path d="{d}" fill="none" stroke="{col}" stroke-width="2.2" stroke-linecap="round"/>'


def sound_icon(kind, x, y, col=CREAM):
    """Small icons for the six sounds, drawn round (x, y)."""
    if kind == "box":     # a music box: a little box with a key
        return (f'<rect x="{x - 12}" y="{y - 6}" width="24" height="16" rx="3" fill="none" stroke="{col}" stroke-width="2"/>'
                f'<path d="M{x - 12},{y - 6} l0,-6 h24 l0,6 M{x + 14},{y + 2} h6 M{x + 20},{y - 2} v8" stroke="{col}" stroke-width="2" fill="none" stroke-linecap="round"/>'
                f'<circle cx="{x - 3}" cy="{y + 2}" r="2.2" fill="{col}"/><path d="M{x - 1},{y + 2} v-8 l5,-1.5" stroke="{col}" stroke-width="1.8" fill="none" stroke-linecap="round"/>')
    if kind == "hum":     # humming: a mouth and a soft note
        return (f'<path d="M{x - 10},{y + 2} q10,10 20,0" fill="none" stroke="{col}" stroke-width="2.2" stroke-linecap="round"/>'
                f'<circle cx="{x + 6}" cy="{y - 10}" r="2.6" fill="{col}"/><path d="M{x + 8.4},{y - 10} v-9 l5,-2" stroke="{col}" stroke-width="1.8" fill="none" stroke-linecap="round"/>'
                f'<circle cx="{x - 8}" cy="{y - 6}" r="1.6" fill="{col}"/><path d="M{x - 6.5},{y - 6} v-6 l4,-1.5" stroke="{col}" stroke-width="1.4" fill="none" stroke-linecap="round"/>')
    if kind == "rain":
        o = f'<path d="M{x - 12},{y - 2} a6,6 0 0 1 4,-11 a9,9 0 0 1 17,2 a6,6 0 0 1 2,12 Z" fill="none" stroke="{col}" stroke-width="2" stroke-linejoin="round"/>'
        for dx in (-7, 0, 7):
            o += f'<path d="M{x + dx},{y + 6} l-2,7" stroke="{col}" stroke-width="2" stroke-linecap="round"/>'
        return o
    if kind == "sea":
        return wave(x - 14, y - 4, 28, col, 4, 2) + wave(x - 14, y + 6, 28, col, 4, 2)
    if kind == "fan":
        o = f'<circle cx="{x}" cy="{y}" r="3" fill="{col}"/>'
        for a in (0, 120, 240):
            o += f'<ellipse cx="{x}" cy="{y - 9}" rx="4.5" ry="8" fill="none" stroke="{col}" stroke-width="2" transform="rotate({a} {x} {y})"/>'
        return o
    if kind == "heart":
        return f'<path d="M{x},{y + 10} C{x - 18},{y - 4} {x - 8},{y - 16} {x},{y - 6} C{x + 8},{y - 16} {x + 18},{y - 4} {x},{y + 10}Z" fill="none" stroke="{col}" stroke-width="2.2" stroke-linejoin="round"/>'
    return ""


def screen_lullaby():
    """6: 搖籃曲與白噪音 with a timer; the screen fades to black so the phone can lie face down."""
    o = [sky(W, H, "deep"), stars(W, 400, 40, 23, .5, 2)]
    o.append(top_bar("搖籃曲"))
    # the six sounds; 音樂盒 is chosen
    names = [("box", "音樂盒"), ("hum", "哼歌"), ("rain", "雨聲"), ("sea", "海浪"), ("fan", "風扇"), ("heart", "心跳")]
    for i, (k, n) in enumerate(names):
        r, c = divmod(i, 3)
        x, y = 48 + c * 115, 96 + r * 92
        on = i == 0
        o.append(f'<rect x="{x}" y="{y}" width="98" height="78" rx="18" fill="{"#2A3A6A" if on else "#121C3A"}" stroke="{WARM3 if on else "#2E3B62"}" stroke-width="{2 if on else 1.2}"/>')
        o.append(sound_icon(k, x + 49, y + 30, WARM3 if on else DIM))
        o.append(tx(x + 49, y + 66, n, 14, CREAM if on else DIM, op=.95 if on else .8))
    # the timer
    o.append(tx(W / 2, 318, "多久以後關掉", 13, DIM, op=.8))
    for i, (m, on) in enumerate(((10, False), (20, True), (30, False))):
        x = 56 + i * 98
        o.append(pill(x, 332, 82, 40, "#2A3A6A" if on else "#121C3A", WARM3 if on else "#2E3B62"))
        o.append(tx(x + 41, 358, f"{m} 分鐘", 15, CREAM if on else DIM))
    # the moon and the remaining time, already dim
    o.append(moon(W / 2, 480, 44, face=True))
    o.append(tx(W / 2, 560, "還剩 18 分鐘", 16, DIM, op=.8))
    # the fade: the lower part of the screen is going black
    o.append(f'<rect x="0" y="420" width="{W}" height="424" fill="{lg([(0, "#000000", 0), (.5, "#000000", .8), (1, "#000000", 1)])}"/>')
    o.append(tx(W / 2, 700, "螢幕慢慢變黑，", 17, DIM, op=.85))
    o.append(tx(W / 2, 728, "手機可以蓋起來放旁邊。", 17, DIM, op=.85))
    o.append(tx(W / 2, 790, "搖籃曲停了，APP 就自己關掉。", 13, DIM, op=.55))
    return page("".join(o), "#070E22")


def toggle(x, y, on=True):
    return (f'<rect x="{x}" y="{y}" width="48" height="28" rx="14" fill="{TEAL if on else "#D9D3C8"}"/>'
            f'<circle cx="{x + (34 if on else 14)}" cy="{y + 14}" r="11" fill="#FFFFFF"/>')


def chip(x, y, w, s, on=False):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="36" rx="18" fill="{TEAL if on else "#F1ECE3"}" stroke="{TEAL if on else "#D7D0C5"}" stroke-width="1.5"/>'
            + tx(x + w / 2, y + 24, s, 15, "#FFFFFF" if on else INK))


def screen_parents():
    """7: 家長模式 (after the parent gate). Light page, like the sibling apps."""
    o = [f'<rect width="{W}" height="{H}" fill="{PAGE}"/>']
    o.append(tx(W / 2, 46, "家長模式", 23, INK))
    o.append(f'<circle cx="{W - 34}" cy="40" r="17" fill="#E9E3D9"/><path d="M{W - 41},33 l14,14 M{W - 27},33 l-14,14" stroke="{INK}" stroke-width="2.2" stroke-linecap="round"/>')
    y = 70
    # age
    o.append(card(18, y, 354, 84))
    o.append(tx(34, y + 26, "年齡", 13.5, SOFT, "start"))
    o.append(chip(34, y + 38, 150, "2～3 歲（短）", True) + chip(194, y + 38, 162, "4～5 歲（長一點）"))
    y += 96
    # how long
    o.append(card(18, y, 354, 84))
    o.append(tx(34, y + 26, "每次最多幾分鐘（整個 APP）", 13.5, SOFT, "start"))
    o.append(chip(34, y + 38, 60, "5", False) + chip(102, y + 38, 60, "8", True) + chip(170, y + 38, 60, "10", False) + tx(244, y + 62, "分鐘，到了就關掉", 13, SOFT, "start"))
    y += 96
    # which modules, in order
    o.append(card(18, y, 354, 258))
    o.append(tx(34, y + 26, "今晚要做哪些（照順序，可以拖著換）", 13.5, SOFT, "start"))
    items = [("晚安清單", True), ("關燈巡邏", True), ("數羊", True), ("晚安故事", True), ("呼吸小月亮", False), ("搖籃曲", True)]
    for i, (n, on) in enumerate(items):
        yy = y + 40 + i * 34
        o.append(f'<path d="M36,{yy + 10} h10 M36,{yy + 15} h10 M36,{yy + 20} h10" stroke="#C8C1B5" stroke-width="1.6" stroke-linecap="round"/>')
        o.append(tx(56, yy + 20, n, 15.5, INK if on else SOFT, "start"))
        if n == "晚安清單":
            o.append(tx(130, yy + 20, "刷牙、尿尿、喝水、抱抱", 12, SOFT, "start"))
        o.append(toggle(308, yy + 2, on))
    y += 270
    # lullaby, voice, brightness
    o.append(card(18, y, 354, 204))
    o.append(tx(34, y + 34, "搖籃曲", 15.5, INK, "start"))
    o.append(chip(190, y + 14, 80, "音樂盒", True) + chip(278, y + 14, 78, "哼歌"))
    o.append(tx(34, y + 80, "搖籃曲最多幾分鐘", 15.5, INK, "start"))
    o.append(chip(190, y + 60, 50, "10") + chip(246, y + 60, 50, "20", True) + chip(302, y + 60, 54, "30"))
    o.append(f'<path d="M34,{y + 108} h322" stroke="#EDE7DD" stroke-width="1.5"/>')
    o.append(tx(34, y + 134, "念故事給小朋友聽（國語）", 15.5, INK, "start") + toggle(308, y + 116, True))
    o.append(tx(34, y + 154, "關掉的話，由家長看著螢幕念", 12, SOFT, "start"))
    o.append(tx(34, y + 186, "螢幕亮度", 15.5, INK, "start"))
    o.append(f'<rect x="150" y="{y + 178}" width="190" height="6" rx="3" fill="#E6E0D5"/><rect x="150" y="{y + 178}" width="66" height="6" rx="3" fill="{TEAL}"/><circle cx="216" cy="{y + 181}" r="10" fill="#FFFFFF" stroke="{TEAL}" stroke-width="2"/>')
    o.append(tx(356, y + 186, "亮", 12, SOFT, "end") + tx(134, y + 186, "暗", 12, SOFT, "end"))
    y += 216
    o.append(card(18, y, 354, 62))
    o.append(tx(34, y + 25, "最近七天", 13.5, SOFT, "start"))
    o.append(tx(34, y + 48, "用了 5 個晚上，平均 6 分鐘；最常跳過：呼吸小月亮", 13, INK, "start"))
    return page("".join(o), PAGE)


# ================================================================ 晚安清單
def c_icon(kind, cx, cy, col):
    """Big simple icons for the four checklist things, drawn round (cx, cy), about 70 wide."""
    sw = 'stroke-width="5" stroke-linecap="round" stroke-linejoin="round" fill="none"'
    if kind == "teeth":    # a toothbrush
        return (f'<g transform="rotate(-35 {cx} {cy})"><rect x="{cx - 34}" y="{cy - 7}" width="56" height="14" rx="7" fill="{col}"/>'
                f'<rect x="{cx + 14}" y="{cy - 13}" width="22" height="26" rx="5" fill="{col}"/>'
                f'<path d="M{cx + 19},{cy - 8} v16 M{cx + 25},{cy - 8} v16 M{cx + 31},{cy - 8} v16" stroke="#0D1733" stroke-width="2.2" stroke-linecap="round"/></g>')
    if kind == "pee":      # a little toilet
        return (f'<rect x="{cx - 12}" y="{cy - 34}" width="28" height="30" rx="6" fill="{col}"/>'
                f'<path d="M{cx - 30},{cy - 4} h56 a28,22 0 0 1 -56,0Z" fill="{col}"/>'
                f'<ellipse cx="{cx - 2}" cy="{cy - 4}" rx="20" ry="7" fill="#0D1733" opacity=".35"/>'
                f'<rect x="{cx + 12}" y="{cy - 44}" width="12" height="8" rx="3" fill="{col}"/>')
    if kind == "water":    # a cup with water
        return (f'<path d="M{cx - 24},{cy - 30} h48 l-6,58 h-36Z" {sw} stroke="{col}"/>'
                f'<path d="M{cx - 19},{cy - 4} h38 l-3.5,30 h-31Z" fill="{col}" opacity=".9"/>'
                f'<path d="M{cx - 16},{cy - 6} q10,-6 20,0 t16,0" stroke="{col}" stroke-width="3" fill="none" stroke-linecap="round"/>')
    if kind == "hug":      # two round heads leaning together, a heart above
        return (f'<circle cx="{cx - 16}" cy="{cy - 10}" r="13" fill="{col}"/><circle cx="{cx + 16}" cy="{cy - 10}" r="13" fill="{col}"/>'
                f'<path d="M{cx - 36},{cy + 34} q0,-30 20,-30 q10,0 16,8 q6,-8 16,-8 q20,0 20,30Z" fill="{col}"/>'
                f'<path d="M{cx},{cy - 28} C{cx - 10},{cy - 36} {cx - 6},{cy - 46} {cx},{cy - 40} C{cx + 6},{cy - 46} {cx + 10},{cy - 36} {cx},{cy - 28}Z" fill="#F5B9A8"/>')
    return ""


def screen_checklist():
    """8: 晚安清單, the first step. Four big things; tap one when it is really done and it goes dark and yawns."""
    o = [sky(W, H, "night"), stars(W, 500, 60, 29, .8, 3), moon(326, 150, 28)]
    o.append(top_bar("晚安清單"))
    o.append(tx(W / 2, 112, "睡覺前的四件事，做好了就點一下", 16, CREAM, op=.9))
    items = [("teeth", "刷牙", True), ("pee", "尿尿", True), ("water", "喝水", False), ("hug", "抱抱", False)]
    for i, (k, n, done) in enumerate(items):
        r, c = divmod(i, 2)
        x, y = 36 + c * 170, 190 + r * 230
        if done:
            o.append(f'<rect x="{x}" y="{y}" width="148" height="196" rx="30" fill="{OFF}" stroke="{lighter(OFF, .2)}" stroke-width="1.5"/>')
            o.append(c_icon(k, x + 74, y + 86, lighter(OFF, .22)))
            o.append(zz(x + 118, y + 44, 7, lighter(OFF, .5), .9))
            o.append(tx(x + 74, y + 166, n, 20, DIM, op=.7))
        else:
            o.append(glow(x + 74, y + 98, 130, WARM2, .28))
            o.append(f'<rect x="{x}" y="{y}" width="148" height="196" rx="30" fill="{lg([(0, WARM3), (1, WARM)])}"/>')
            o.append(c_icon(k, x + 74, y + 86, "#2A2240"))
            o.append(tx(x + 74, y + 166, n, 22, "#2A2240"))
    o.append(finger(36 + 128, 420 + 100, .95))
    o.append(tx(W / 2, 700, "刷牙和尿尿已經睡了，", 15, DIM, op=.85))
    o.append(tx(W / 2, 726, "喝完水、抱抱，再去幫大家關燈。", 15, DIM, op=.85))
    o.append(tx(W / 2, 790, "不想點也沒關係，等一下會自己往下走。", 12.5, DIM, op=.55))
    return page("".join(o), "#0D1733")


# ================================================================ STYLE PAGE
def style_sheet():
    global STYLE
    ph = 1180
    o = [f'<rect width="{W}" height="{ph}" fill="#F7F2EA"/>']
    o.append(tx(W / 2, 58, "選一個畫風", 30, INK))
    o.append(tx(W / 2, 90, "同一條小街的晚上，三種畫法", 16, SOFT))
    bands = [("A 星光剪影風（建議）", "深藍的夜，房子和動物是紙剪影，只有窗和燈籠亮著。", "sil"),
             ("B 夜燈毛玻璃風", "像隔著毛玻璃看小夜燈：邊邊糊糊的、暖暖的，沒有硬線。", "frost"),
             ("C 刺繡被子風", "像繡在被子上：布的格紋和點點，邊是一針一針的縫線。", "quilt")]
    y = 116
    for title, desc, st in bands:
        h = 330
        if st == "sil":
            o.append(f'<rect x="12" y="{y - 4}" width="366" height="{h + 8}" rx="28" fill="#5FA8A0"/>')
            o.append(f'<rect x="16" y="{y}" width="358" height="{h}" rx="24" fill="#FFFFFF"/>')
            o.append(f'<rect x="270" y="{y - 14}" width="92" height="30" rx="15" fill="#5FA8A0"/>' + tx(316, y + 7, "我建議這個", 14, "#FFFFFF"))
        else:
            o.append(f'<rect x="16" y="{y + 4}" width="358" height="{h}" rx="24" fill="#E9DED3"/><rect x="16" y="{y}" width="358" height="{h}" rx="24" fill="#FFFFFF"/>')
        o.append(tx(34, y + 40, title, 22, INK, "start"))
        o.append(tx(34, y + 66, desc, 12.5, "#6E5C52", "start"))
        px, py, pw, phh = 30, y + 84, 330, 230
        STYLE = st
        inner = sky(390, 640, "night") + stars(390, 420, 60, 5, 1.0, 2) + moon(318, 212, 24) + town(None, "night")
        s = pw / 390
        o.append(f'<g clip-path="{clip(px, py, pw, phh, 14)}"><g transform="translate({px} {py - 190 * s:.1f}) scale({s:.4f})">{inner}</g></g>')
        if st == "quilt":
            o.append(f'<rect x="{px}" y="{py}" width="{pw}" height="{phh}" rx="14" fill="none" stroke="#9AA8D0" stroke-width="2" stroke-dasharray="6 4"/>')
        STYLE = "sil"
        y += h + 22
    return page("".join(o), "#F7F2EA", W, ph), ph


# ================================================================ PAGE, RENDER, CONTACT SHEET, MAIN
def page(body, bg, w=W, h=H):
    css = (f"@font-face {{ font-family: Huninn; src: url('file://{FONT}'); }}"
           f"* {{ margin: 0; padding: 0; }} body {{ width: {w}px; height: {h}px; overflow: hidden; background: {bg}; }}")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{D.svg()}{body}</svg>'
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head><body>{svg}</body></html>'


def render(html, out, w, h, scale):
    with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp:
        p = pathlib.Path(tmp) / "page.html"
        p.write_text(html)
        subprocess.run(["node", str(HERE / "render.js"), str(p), str(out), str(w), str(h), str(scale)], check=True)
    if pathlib.Path(out).stat().st_size > 450_000:
        from PIL import Image
        im = Image.open(out).convert("RGB")
        im.quantize(colors=256, method=Image.Quantize.MEDIANCUT, kmeans=2, dither=Image.Dither.FLOYDSTEINBERG).save(out, optimize=True)


def contact_sheet(names):
    cw_, ch_, gap, m = 232, 502, 24, 30
    per = 4
    rows = (len(names) + per - 1) // per
    w = per * cw_ + (per - 1) * gap + 2 * m
    rowh = ch_ + 64
    h = rows * rowh + 40
    items = []
    for i, n in enumerate(names):
        r, c = divmod(i, per)
        k = min(per, len(names) - r * per)
        x = m + c * (cw_ + gap) + (per - k) * (cw_ + gap) / 2
        y = 28 + r * rowh
        items.append(f'<div style="position:absolute;left:{x}px;top:{y}px;width:{cw_}px;text-align:center">'
                     f'<img src="file://{HERE / (n + ".png")}" style="width:{cw_}px;height:{ch_}px;border-radius:18px;box-shadow:0 6px 16px rgba(40,40,80,.25)">'
                     f'<div style="font:19px Huninn, sans-serif;color:{INK};margin-top:10px">{n.replace("_", " ")}</div></div>')
    css = f"@font-face {{ font-family: Huninn; src: url('file://{FONT}'); }} * {{ margin:0; padding:0 }} body {{ width:{w}px; height:{h}px; background:#F7F1E8; position:relative }}"
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head><body>{"".join(items)}</body></html>', w, h


SCREENS = {"8_晚安清單": screen_checklist, "1_小鎮黃昏": screen_dusk, "2_關燈": screen_lightoff, "3_數羊": screen_sheep,
           "4_晚安故事": screen_story, "5_呼吸小月亮": screen_breath, "6_搖籃曲": screen_lullaby, "7_家長模式": screen_parents}


def main(only=None):
    global D
    if only in (None, "0"):
        D = Defs()
        html, ph = style_sheet()
        render(html, HERE / "0_畫風選擇.png", W, ph, 2)
        print("0_畫風選擇")
    for name, make in SCREENS.items():
        if only not in (None, name.split("_")[0]):
            continue
        D = Defs()
        render(make(), HERE / f"{name}.png", W, H, 2)
        print(name)
    if only in (None, "c"):
        html, w, h = contact_sheet(list(SCREENS))
        render(html, HERE / "contact_sheet.png", w, h, 1.25)
        print("contact_sheet")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
