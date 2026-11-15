"""Counting sheep (數羊): a night meadow with a little fence, and a fluffy moonlit sheep.

    sheep/meadow.svg       400 x 260  the hills and the fence (the fence's top is at FENCE_TOP)
    sheep/sheep.svg        100 x 80   a sheep mid-hop (legs tucked)
    sheep/sheep_sleep.svg  100 x 80   a sheep lying down asleep
"""
import sys

sys.dont_write_bytecode = True

import kit  # noqa: E402
from kit import INK, SHEEP, SHEEP_DK, ellipse, rect, rrect, smooth  # noqa: E402

FENCE_X, FENCE_TOP, FENCE_W = 160, 150, 80


def meadow():
    s = kit.Svg(400, 260)
    s.path(smooth([(0, 150), (90, 128), (200, 140), (300, 120), (400, 136)], close=False) + " L400 260 L0 260 Z", "#202A5C")
    s.path(smooth([(0, 196), (110, 178), (230, 186), (330, 172), (400, 180)], close=False) + " L400 260 L0 260 Z", "#171E48")
    # the fence: posts and two rails
    post = "#2B336A"
    for i in range(5):
        x = FENCE_X + i * FENCE_W / 4
        s.path(rrect(x - 3.5, FENCE_TOP, 7, 50, 2.5), post)
    s.path(rrect(FENCE_X - 8, FENCE_TOP + 10, FENCE_W + 16, 6, 3), post)
    s.path(rrect(FENCE_X - 8, FENCE_TOP + 28, FENCE_W + 16, 6, 3), post)
    # tufts of grass and a few flowers closed for the night
    r = kit.rnd("grass")
    for i in range(16):
        x, y = r.uniform(5, 395), r.uniform(205, 250)
        s.path(f"M{kit.n(x - 5)} {kit.n(y)} Q{kit.n(x - 3)} {kit.n(y - 9)} {kit.n(x - 1)} {kit.n(y - 12)} Q{kit.n(x)} {kit.n(y - 5)} {kit.n(x + 1)} {kit.n(y - 12)} "
               f"Q{kit.n(x + 3)} {kit.n(y - 8)} {kit.n(x + 5)} {kit.n(y)} Z", "#25306A")
    return s.text()


def wool(s, cx, cy, rx, ry, key):
    s.path(kit.blob(cx, cy, rx, ry, lumps=13, wobble=0.09, key=key), SHEEP)
    s.path(kit.blob(cx + 2, cy + ry * .35, rx * .8, ry * .45, lumps=9, wobble=0.1, key=key + "s"), SHEEP_DK, 0.55)


def sheep():
    s = kit.Svg(100, 80)
    for x0, x1 in ((34, 24), (42, 34), (60, 68), (68, 76)):            # legs reaching out
        s.stroke(f"M{x0} 50 L{x1} 64", INK, 4.5)
    wool(s, 50, 40, 30, 20, "sheep_body")
    s.path(ellipse(80, 30, 10, 12), INK)                                 # the face
    s.path(ellipse(73, 21, 6, 3.2), INK)                                 # an ear
    s.path(kit.blob(78, 19, 8, 5, key="sheep_top"), SHEEP)               # the fluffy top
    s.path(ellipse(84, 30, 1.8, 2.2), "#FFE9B0")
    s.path(ellipse(18, 36, 5, 4), SHEEP)                                 # the tail
    return s.text()


def sheep_sleep():
    s = kit.Svg(100, 80)
    s.path(ellipse(50, 70, 40, 5), "#0F1331", 0.35)
    wool(s, 48, 54, 34, 17, "sheep_lie")
    s.path(ellipse(78, 58, 10, 9), INK)
    s.path(ellipse(70, 52, 6, 3), INK)
    s.path(kit.blob(76, 49, 8, 5, key="sheep_top2"), SHEEP)
    s.stroke("M77 59 Q80.5 62 84 59", "#9AA6E0", 1.6)
    return s.text()


def build():
    kit.write_svg("sheep/meadow.svg", meadow())
    kit.write_svg("sheep/sheep.svg", sheep())
    kit.write_svg("sheep/sheep_sleep.svg", sheep_sleep())
    print("sheep: 3 pictures")


if __name__ == "__main__":
    build()
