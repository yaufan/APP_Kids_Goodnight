"""The town's animals as window silhouettes (docs/design.md: 「暖黃色窗戶裡的黑影」), awake and asleep.

`animals/<animal>_awake.svg` and `animals/<animal>_sleep.svg`, 60 x 72 (a window pane is 30 x 36),
seen from the chest up, facing out. The body is `#BODY`, open eyes `#EYE`, closed eyes `#LID`: the
app paints them (a black shape in a warm window; a soft blue sleeper in a dark one; a dark shape in the
story pictures). Asleep, the head drops and tilts and the eyes close.

    python3 animals.py
"""
import sys

sys.dont_write_bytecode = True

import kit  # noqa: E402
from kit import BODY, EYE, LID, circle, ellipse, poly, smooth  # noqa: E402

W, H = 60, 72
ANIMALS = ["cat", "rabbit", "bear", "duck", "pig", "owl", "dog", "sheep"]


def shoulders():
    return ellipse(30, 78, 23, 24)


def head_parts(a):
    """(head shapes, (left eye, right eye), eye radius) for an animal, head about (30, 38)."""
    if a == "cat":
        shapes = [circle(30, 40, 15), poly([(16, 34), (15, 17), (27, 27)]), poly([(44, 34), (45, 17), (33, 27)])]
        return shapes, ((24.5, 40), (35.5, 40)), 2.1
    if a == "rabbit":
        shapes = [circle(30, 44, 14), ellipse(24, 22, 4.6, 14), ellipse(36, 22, 4.6, 14)]
        return shapes, ((25, 44), (35, 44)), 2.0
    if a == "bear":
        shapes = [circle(18, 28, 6.5), circle(42, 28, 6.5), circle(30, 40, 16), ellipse(30, 47, 7, 5.5)]
        return shapes, ((24, 38), (36, 38)), 2.0
    if a == "duck":
        shapes = [circle(28, 38, 13.5), ellipse(43, 42, 9, 4.2), ellipse(27, 25, 3, 4.5)]
        return shapes, ((24, 36), (33, 36)), 1.9
    if a == "pig":
        shapes = [ellipse(30, 41, 17, 14.5), poly([(15, 33), (13, 21), (25, 29)]), poly([(45, 33), (47, 21), (35, 29)]), ellipse(30, 47, 7.5, 5.5)]
        return shapes, ((23.5, 38), (36.5, 38)), 1.9
    if a == "owl":
        shapes = [ellipse(30, 44, 18, 22), poly([(13, 30), (14, 16), (24, 25)]), poly([(47, 30), (46, 16), (36, 25)])]
        return shapes, ((23, 38), (37, 38)), 4.6
    if a == "dog":
        shapes = [circle(30, 39, 14.5), ellipse(16.5, 41, 5.5, 11), ellipse(43.5, 41, 5.5, 11), ellipse(30, 47, 7.5, 5.5)]
        return shapes, ((25, 37), (35, 37)), 2.0
    if a == "sheep":
        fluff = kit.blob(30, 38, 17, 15, lumps=11, wobble=0.1, key="sheep_head")
        shapes = [fluff, ellipse(12, 40, 6, 3.2), ellipse(48, 40, 6, 3.2)]
        return shapes, ((25, 41), (35, 41)), 2.0
    raise KeyError(a)


def extras(s, a, asleep):
    """Things beside the head: the cat's tail, the owl's beak, the pig's nostrils."""
    if a == "cat":
        s.stroke(smooth([(48, 72), (54, 62), (53, 52), (48, 47)], close=False), BODY, 5)
    if a == "owl":
        s.path(poly([(28, 44), (32, 44), (30, 49)]), EYE if not asleep else LID, 0.9)
    if a == "pig":
        s.circle(27.5, 47, 1.3, EYE if not asleep else LID, 0.7)
        s.circle(32.5, 47, 1.3, EYE if not asleep else LID, 0.7)


def draw(a, asleep):
    s = kit.Svg(W, H)
    s.path(shoulders(), BODY)
    shapes, eyes, er = head_parts(a)
    if asleep:
        # the head drops a little and leans
        s.add('<g transform="translate(0 3) rotate(-11 30 60)">')
    for d in shapes:
        s.path(d, BODY)
    extras(s, a, asleep)
    for ex, ey in eyes:
        if asleep:
            w = max(er * 1.5, 3)
            s.stroke(f"M{kit.n(ex - w)} {kit.n(ey)} Q{kit.n(ex)} {kit.n(ey + w * .8)} {kit.n(ex + w)} {kit.n(ey)}", LID, 1.7)
        elif a == "owl":
            s.circle(ex, ey, er, EYE)
            s.circle(ex + .6, ey + .4, er * .45, BODY)
        else:
            s.path(ellipse(ex, ey, er * .85, er), EYE)
    if asleep:
        s.add("</g>")
    return s.text()


def build():
    for a in ANIMALS:
        kit.write_svg(f"animals/{a}_awake.svg", draw(a, False))
        kit.write_svg(f"animals/{a}_sleep.svg", draw(a, True))
    print(f"animals: {len(ANIMALS) * 2} pictures")


if __name__ == "__main__":
    build()
