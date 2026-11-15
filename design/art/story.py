"""The story pictures (晚安故事): a small silhouette scene for each place, and a prop for each small
happening, laid over it. The app puts the animal and the prop in fixed boxes (lib/features/story):

    story/place_<place>.svg   320 x 200   the place, with the moon at MOON (top right)
    story/thing_<thing>.svg   120 x 180   the prop, drawn for the box THING_BOX of the place picture
    the animal                            animals/<animal>_awake|sleep.svg in ANIMAL_BOX

Places: roof, shop, park, temple, beach, hill. Things: star, pillow, wind, moonHides, rain, friend,
firefly, leaf, countStars, callHome (lib/core/story.dart).
"""
import sys

sys.dont_write_bytecode = True

import kit  # noqa: E402
from kit import MOON, MOON_LT, WARM, WARM_LT, circle, ellipse, poly, rect, rrect, smooth, star  # noqa: E402

W, H = 320, 200
MOON_AT = (262, 42, 17)
THING_BOX = (190, 10, 120, 180)
ANIMAL_BOX = (70, 86, 92, 110)
DARK = "#141836"
DARK2 = "#1B2147"
SKY = [(0, "#26306A"), (1, "#3E4A8C")]


def base(s, moon=True):
    s.path(rect(0, 0, W, H), s.gradient(SKY))
    r = kit.rnd("story_stars")
    for _ in range(14):
        s.circle(r.uniform(6, 314), r.uniform(6, 90), r.uniform(.7, 1.5), "#FFF1C2", r.uniform(.4, .8))
    if moon:
        x, y, rr = MOON_AT
        s.glow(x, y, rr * 2.6, MOON, layers=6, top=0.07)
        s.path(kit.crescent(x, y, rr, dx=0.5, dy=-0.36), s.gradient([(0, MOON_LT), (1, MOON)], 0, 0, 1, 1))


def place_roof():
    s = kit.Svg(W, H)
    base(s)
    # far rooftops with a few warm windows
    s.path(poly([(0, 150), (40, 150), (40, 132), (90, 132), (90, 146), (150, 146), (150, 124), (200, 124), (200, 140), (260, 140),
                 (260, 128), (320, 128), (320, 200), (0, 200)]), "#202858")
    for x, y in ((56, 140), (166, 132), (280, 136)):
        s.path(rect(x, y, 6, 6), WARM, 0.55)
    # our roof: tiles sloping down to the right
    s.path(poly([(0, 168), (40, 156), (300, 176), (320, 180), (320, 200), (0, 200)]), DARK)
    for i in range(1, 5):
        s.stroke(kit.line([(i * 60 - 20, 164 + i * 3), (i * 60 - 10, 200)]), DARK2, 3)
    # a water tank on legs
    s.path(rrect(236, 132, 34, 26, 4), DARK)
    s.path(rect(240, 156, 4, 18) + " " + rect(262, 156, 4, 18), DARK)
    return s.text()


def place_shop():
    s = kit.Svg(W, H)
    s.path(rect(0, 0, W, H), "#1E2452")
    # the window to the night sky (the moon is in it)
    s.path(rect(196, 8, 118, 84), "#141836")
    s.add('<g>')
    sky = s.gradient(SKY)
    s.path(rect(200, 12, 110, 76), sky)
    x, y, rr = MOON_AT
    s.glow(x, y, rr * 2, MOON, layers=5, top=0.08)
    s.path(kit.crescent(x, y, rr, dx=0.5, dy=-0.36), MOON)
    s.add('</g>')
    s.path(rect(254, 12, 3, 76) + " " + rect(200, 48, 110, 3), "#141836")
    # the table, a steamer of buns and the stools
    s.path(rrect(20, 96, 260, 10, 3), DARK)
    s.path(rect(34, 106, 8, 94) + " " + rect(258, 106, 8, 94), DARK)
    s.path(rrect(40, 74, 36, 22, 4), DARK)
    s.path(rrect(44, 62, 28, 13, 4), DARK)
    s.path(ellipse(58, 60, 8, 4), DARK)
    s.path(rrect(214, 82, 16, 14, 3), DARK)
    s.path(ellipse(286, 150, 18, 5) + " " + rect(282, 150, 8, 50), DARK2)
    s.path(rect(0, 194, W, 6), "#141836")
    return s.text()


def place_park():
    s = kit.Svg(W, H)
    base(s)
    s.path(smooth([(0, 168), (120, 160), (220, 170), (320, 162)], close=False) + " L320 200 L0 200 Z", DARK)
    # the big tree
    s.path(poly([(34, 170), (40, 96), (52, 96), (60, 170)]), DARK)
    s.path(kit.blob(46, 70, 52, 42, lumps=11, wobble=0.12, key="park_tree"), DARK)
    s.path(kit.blob(86, 88, 26, 20, lumps=8, wobble=0.12, key="park_tree2"), DARK)
    # a bench
    s.path(rrect(214, 150, 70, 6, 2) + " " + rrect(214, 136, 70, 5, 2), DARK)
    s.path(rect(220, 156, 5, 14) + " " + rect(273, 156, 5, 14), DARK)
    return s.text()


def place_temple():
    s = kit.Svg(W, H)
    base(s)
    # the temple roof with its swallowtail ridge (燕尾), pillars and a lantern
    s.path(f"M-10 84 C30 80 120 82 166 78 C176 70 182 60 192 56 C188 66 184 78 182 88 L170 96 L-10 96 Z", DARK)
    s.path(rect(-10, 96, 180, 8), DARK2)
    s.path(rect(10, 104, 12, 70) + " " + rect(146, 104, 12, 70), DARK)
    s.stroke(kit.line([(120, 104), (120, 116)]), DARK, 1.5)
    s.path(ellipse(120, 126, 9, 11), "#3A2238")
    s.path(rect(0, 172, W, 28), DARK)
    s.path(rect(0, 168, W, 6), DARK2)
    # the stone lion (石獅子), sitting, dozing
    lion = [(14, 172), (14, 140), (20, 124), (34, 116), (50, 120), (56, 132), (52, 146), (58, 160), (58, 172)]
    s.path(smooth(lion), DARK)
    s.path(kit.blob(36, 118, 18, 14, lumps=12, wobble=0.15, key="lion_mane"), DARK)
    s.path(rect(10, 170, 52, 6), DARK2)
    return s.text()


def place_beach():
    s = kit.Svg(W, H)
    base(s)
    s.path(rect(0, 112, W, 52), "#2A3672")
    x, y, rr = MOON_AT
    for i in range(6):
        w = 26 - i * 3
        s.path(rrect(x - w / 2, 118 + i * 7, w, 2.4, 1.2), MOON, 0.5 - i * 0.05)
    for i in range(4):
        yy = 124 + i * 10
        s.stroke(f"M{10 + i * 20} {yy} Q{30 + i * 20} {yy - 4} {50 + i * 20} {yy} T{90 + i * 20} {yy}", "#5A68A8", 1.6, 0.6)
    # a little boat far away, and the sand
    s.path(poly([(30, 112), (62, 112), (56, 118), (36, 118)]) + " " + poly([(46, 112), (46, 96), (58, 110)]), DARK)
    s.path(smooth([(0, 166), (110, 160), (220, 166), (320, 158)], close=False) + " L320 200 L0 200 Z", "#1D2350")
    for px, py in ((210, 186), (240, 180), (290, 190)):
        s.path(ellipse(px, py, 4, 2), "#283068")
    return s.text()


def place_hill():
    s = kit.Svg(W, H)
    base(s)
    # the town far below on the right, its lights going out
    s.path(poly([(170, 182), (190, 182), (190, 170), (210, 170), (210, 176), (236, 176), (236 + 0, 164), (262, 164), (262, 172), (290, 172),
                 (290, 166), (320, 166), (320, 200), (170, 200)]), "#202858")
    for x, y, a in ((196, 175, .7), (246, 168, .4), (300, 170, .6), (272, 176, .3)):
        s.path(rect(x, y, 4, 4), WARM, a)
    # our hilltop with grass
    s.path(smooth([(0, 150), (80, 140), (160, 154), (230, 200)], close=False) + " L0 200 Z", DARK)
    r = kit.rnd("hill_grass")
    for _ in range(9):
        x = r.uniform(4, 150)
        y = 152 - (x - 80) ** 2 / 900 * 0 - 6 + r.uniform(-2, 2) - (6 if x < 120 else -4)
        s.path(f"M{kit.n(x - 3)} {kit.n(y + 6)} L{kit.n(x)} {kit.n(y - 6)} L{kit.n(x + 3)} {kit.n(y + 6)} Z", DARK)
    return s.text()


# ---------------------------------------------------------------- things (120 x 180)
TW, TH = 120, 180
PALE = "#B9C4FF"


def thing_star():
    s = kit.Svg(TW, TH)
    for i in range(5):
        s.circle(70 - i * 9, 40 + i * 18, 2.4 - i * .3, "#FFF1C2", 0.55 - i * .08)
    s.glow(26, 140, 26, WARM, layers=6, top=0.1)
    s.path(star(26, 140, 13, 5.5), s.gradient([(0, "#FFF6D6"), (1, "#FFD27A")]))
    return s.text()


def thing_pillow():
    s = kit.Svg(TW, TH)
    s.glow(40, 156, 30, MOON, layers=5, top=0.08)
    s.path(rrect(14, 142, 54, 26, 11), "#C9C4F0")
    s.path(rrect(18, 156, 46, 10, 5), "#AFA8E0", 0.6)
    return s.text()


def thing_wind():
    s = kit.Svg(TW, TH)
    for i, (y, w) in enumerate(((60, 70), (84, 90), (108, 60))):
        s.stroke(f"M{10 + i * 6} {y} C{40} {y - 12} {60} {y + 12} {10 + w} {y} C{20 + w} {y - 6} {18 + w} {y - 18} {6 + w} {y - 14}", PALE, 2.4, 0.6)
    return s.text()


def thing_moon_hides():
    s = kit.Svg(TW, TH)
    mx, my = MOON_AT[0] - THING_BOX[0], MOON_AT[1] - THING_BOX[1]
    s.path(kit.cloud(mx - 2, my + 6, 76, 38), "#4D5A9C")
    s.path(kit.cloud(mx + 8, my + 2, 54, 26), "#6370B0", 0.7)
    return s.text()


def thing_rain():
    s = kit.Svg(TW, TH)
    s.path(kit.cloud(60, 40, 84, 40), "#4D5A9C")
    r = kit.rnd("rain")
    for i in range(9):
        x, y = 26 + i * 8, r.uniform(66, 110)
        s.stroke(kit.line([(x, y), (x - 3, y + 12)]), PALE, 1.8, 0.65)
    return s.text()


def thing_friend():
    s = kit.Svg(TW, TH)
    body = []
    for i in range(15):
        a = 3.14159 * (1 + i / 14)
        rr = 26 if i % 2 == 0 else 19
        body.append((50 + rr * 1.15 * __import__("math").cos(a), 168 + rr * __import__("math").sin(a)))
    s.path(poly(body + [(80, 172), (20, 172)]), DARK)
    s.path(ellipse(82, 160, 14, 10), DARK)
    s.circle(88, 157, 1.8, "#FFE9B0")
    s.circle(96, 162, 2.2, DARK)
    return s.text()


def thing_firefly():
    s = kit.Svg(TW, TH)
    s.glow(44, 96, 22, "#E8F59A", layers=6, top=0.12)
    s.path(ellipse(44, 96, 6, 5), "#F4FFB8")
    s.path(ellipse(56, 90, 7, 4.5), DARK)
    s.path(ellipse(54, 84, 6, 3), "#5A68A8", 0.8)
    s.stroke("M62 88 L67 83", DARK, 1.2)
    for i in range(4):
        s.circle(70 + i * 9, 80 - i * 8, 1.2, "#E8F59A", 0.5 - i * .1)
    return s.text()


def thing_leaf():
    s = kit.Svg(TW, TH)
    s.path("M20 120 C30 82 74 70 100 74 C96 102 62 128 20 120 Z", "#22406A")
    s.stroke("M22 119 C46 104 70 90 98 75", "#3B5E8E", 1.6)
    s.stroke("M14 126 L22 119", "#22406A", 2)
    return s.text()


def thing_count_stars():
    s = kit.Svg(TW, TH)
    for i, (x, y, r) in enumerate(((20, 44, 7), (52, 26, 6), (84, 52, 8), (40, 78, 5.5), (100, 90, 6))):
        s.glow(x, y, r * 2.4, "#FFF1C2", layers=4, top=0.08)
        s.path(star(x, y, r, r * .42), "#FFF1C2")
    return s.text()


def thing_call_home():
    s = kit.Svg(TW, TH)
    s.path(poly([(56, 150), (84, 128), (112, 150), (112, 178), (56, 178)]), DARK)
    s.glow(84, 158, 22, WARM, layers=5, top=0.1)
    s.path(rect(76, 150, 14, 14), WARM_LT)
    s.path(rect(82, 150, 2, 14) + " " + rect(76, 156, 14, 2), DARK)
    s.path(rect(100, 128, 6, 12), DARK)
    return s.text()


PLACES = {"roof": place_roof, "shop": place_shop, "park": place_park, "temple": place_temple, "beach": place_beach, "hill": place_hill}
THINGS = {"star": thing_star, "pillow": thing_pillow, "wind": thing_wind, "moonHides": thing_moon_hides, "rain": thing_rain,
          "friend": thing_friend, "firefly": thing_firefly, "leaf": thing_leaf, "countStars": thing_count_stars, "callHome": thing_call_home}


def build():
    for k, f in PLACES.items():
        kit.write_svg(f"story/place_{k}.svg", f())
    for k, f in THINGS.items():
        kit.write_svg(f"story/thing_{k}.svg", f())
    print(f"story: {len(PLACES) + len(THINGS)} pictures")


if __name__ == "__main__":
    build()
