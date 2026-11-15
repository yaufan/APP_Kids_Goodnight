"""The moon (docs/design.md: the sky over every screen after the lights).

    sky/moon.svg        120 x 120  a sleepy crescent moon with its glow (the street, the sheep, the lullaby)
    sky/moon_full.svg   200 x 200  the round, sleepy-faced moon to breathe with (呼吸小月亮)
    sky/zz.svg           40 x 40   the little 'z z' over a sleeper (no <text> in flutter_svg: drawn)
"""
import sys

sys.dont_write_bytecode = True

import kit  # noqa: E402
from kit import BLUSH, MOON, MOON_LT, circle, poly  # noqa: E402

FACE = "#B98A4E"


def moon():
    s = kit.Svg(120, 120)
    s.glow(60, 60, 58, MOON, layers=7, top=0.06)
    s.path(kit.crescent(60, 62, 34, cut=0.62, dx=0.5, dy=-0.36), s.gradient([(0, MOON_LT), (1, MOON)], 0, 0, 1, 1))
    # a sleepy face on the crescent's belly
    s.stroke("M40 66 Q44 70 48 66", FACE, 2.4)
    s.stroke("M43 80 Q48 85 54 81", FACE, 2.4)
    s.circle(37, 74, 3.6, BLUSH, 0.6)
    return s.text()


def moon_full():
    s = kit.Svg(200, 200)
    s.glow(100, 100, 98, MOON, layers=8, top=0.05)
    s.path(circle(100, 100, 62), s.radial([(0, MOON_LT), (0.75, MOON), (1, "#F6D98E")]))
    for x, y, r in ((70, 72, 9), (132, 128, 7), (124, 66, 5), (78, 132, 5)):
        s.circle(x, y, r, "#EBCB80", 0.45)
    s.stroke("M72 98 Q81 106 90 98", FACE, 3.4)
    s.stroke("M110 98 Q119 106 128 98", FACE, 3.4)
    s.stroke("M93 120 Q100 126 107 120", FACE, 3.2)
    s.circle(66, 114, 7, BLUSH, 0.55)
    s.circle(134, 114, 7, BLUSH, 0.55)
    return s.text()


def zz():
    s = kit.Svg(40, 40)
    for x, y, k in ((6, 22, 1.0), (22, 6, 0.7)):
        z = poly([(x, y), (x + 12 * k, y), (x + 12 * k, y + 2.6 * k), (x + 4 * k, y + 11 * k), (x + 12 * k, y + 11 * k), (x + 12 * k, y + 14 * k),
                  (x, y + 14 * k), (x, y + 11.4 * k), (x + 8 * k, y + 3 * k), (x, y + 3 * k)])
        s.path(z, "#D9DEFF", 0.85)
    return s.text()


def build():
    kit.write_svg("sky/moon.svg", moon())
    kit.write_svg("sky/moon_full.svg", moon_full())
    kit.write_svg("sky/zz.svg", zz())
    print("sky: 3 pictures")


if __name__ == "__main__":
    build()
