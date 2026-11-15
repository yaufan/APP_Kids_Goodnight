"""Single-colour pictures the app tints (black here): the checklist (晚安清單), the lullaby sounds and
the few buttons.

    checklist/<teeth|potty|water|hug>.svg            100 x 100
    lullaby/<musicBox|humming|rain|waves|fan|heartbeat>.svg   100 x 100
    ui/<close|speak|next|lock>.svg                    100 x 100
"""
import math
import sys

sys.dont_write_bytecode = True

import kit  # noqa: E402
from kit import circle, ellipse, heart, poly, rect, rrect, smooth  # noqa: E402

K = "#000000"


def svg():
    return kit.Svg(100, 100)


# ---------------------------------------------------------------- checklist
def teeth():
    s = svg()
    s.add('<g transform="rotate(-38 50 50)">')
    s.path(rrect(14, 45, 52, 11, 5.5), K)              # the handle
    s.path(rrect(62, 43, 26, 15, 4), K)                # the head
    for i in range(5):
        s.path(rrect(64 + i * 5, 30, 3.4, 14, 1.5), K)   # bristles
    s.path(kit.blob(76, 24, 10, 6, key="paste"), K)     # toothpaste
    s.add("</g>")
    return s.text()


def potty():
    s = svg()
    s.path(rrect(24, 14, 38, 26, 6), K)                 # the tank
    s.path(rrect(18, 42, 66, 10, 5), K)                 # the seat
    s.path("M24 54 L78 54 C76 70 66 78 58 80 L60 90 L36 90 L38 80 C30 78 25 68 24 54 Z", K)
    s.path(rrect(54, 20, 12, 5, 2.5), K)                # the handle
    return s.text()


def water():
    s = svg()
    s.path("M26 30 L74 30 L68 88 C67 92 64 94 60 94 L40 94 C36 94 33 92 32 88 Z", K)
    s.path(rrect(22, 24, 56, 8, 4), K)
    s.path("M50 4 C56 12 60 16 60 20 C60 26 40 26 40 20 C40 16 44 12 50 4 Z", K)
    return s.text()


def hug():
    s = svg()
    s.path(circle(36, 36, 13) + " " + circle(64, 40, 11), K)
    s.path("M14 94 C14 68 24 54 38 54 C46 54 52 58 56 64 L56 94 Z", K)
    s.path("M44 94 L44 70 C48 60 56 56 64 56 C76 56 86 68 86 94 Z", K)
    s.path(heart(50, 14, 8), K)
    return s.text()


# ---------------------------------------------------------------- lullaby sounds
def note(s, x, y, r=6, h=30):
    s.path(ellipse(x, y, r * 1.2, r * .9), K)
    s.path(rect(x + r * 1.2 - 3, y - h, 3, h), K)


def music_box():
    s = svg()
    s.path(rrect(14, 52, 62, 36, 6), K)
    s.path(poly([(14, 50), (22, 30), (82, 30), (76, 50)]), K)        # the open lid
    s.path(rect(76, 64, 12, 4) + " " + rect(85, 58, 4, 16), K)        # the crank
    note(s, 44, 18, 5, 0)
    s.path(ellipse(30, 22, 5, 4), K)
    s.path(rect(33, 6, 2.6, 16), K)
    s.path(poly([(33, 6), (46, 10), (46, 14), (35.6, 10.5)]), K)
    return s.text()


def humming():
    s = svg()
    s.path(ellipse(28, 72, 10, 7.5) + " " + ellipse(70, 64, 10, 7.5), K)
    s.path(rect(35, 22, 4, 50) + " " + rect(77, 14, 4, 50), K)
    s.path(poly([(35, 22), (81, 14), (81, 24), (35, 32)]), K)
    return s.text()


def rain():
    s = svg()
    s.path(kit.cloud(50, 38, 76, 40), K)
    for x in (30, 50, 70):
        s.path(f"M{x} 64 C{x + 5} 72 {x + 6} 76 {x + 6} 79 C{x + 6} 85 {x - 6} 85 {x - 6} 79 C{x - 6} 76 {x - 5} 72 {x} 64 Z", K)
    return s.text()


def waves():
    s = svg()
    for i, y in enumerate((34, 54, 74)):
        s.stroke(f"M10 {y} Q20 {y - 10} 30 {y} T50 {y} T70 {y} T90 {y}", K, 7)
    return s.text()


def fan():
    s = svg()
    for a in (0, 120, 240):
        s.add(f'<g transform="rotate({a} 50 42)">')
        s.path("M50 42 C44 30 46 12 56 10 C66 10 64 30 50 42 Z", K)
        s.add("</g>")
    s.path(circle(50, 42, 6), K)
    s.path(rect(47, 46, 6, 40) + " " + rrect(30, 84, 40, 8, 4), K)
    return s.text()


def heartbeat():
    s = svg()
    s.path(heart(50, 50, 40), K)
    return s.text()


# ---------------------------------------------------------------- buttons
def close():
    s = svg()
    s.stroke("M28 28 L72 72 M72 28 L28 72", K, 9)
    return s.text()


def speak():
    s = svg()
    s.path(poly([(12, 38), (30, 38), (52, 18), (52, 82), (30, 62), (12, 62)]), K)
    s.stroke("M64 36 Q72 50 64 64", K, 6)
    s.stroke("M74 26 Q88 50 74 74", K, 6)
    return s.text()


def next_page():
    s = svg()
    s.stroke("M38 22 L66 50 L38 78", K, 10)
    return s.text()


def lock():
    s = svg()
    s.stroke("M34 46 L34 34 C34 16 66 16 66 34 L66 46", K, 8)
    s.path(rrect(24, 44, 52, 42, 8), K)
    return s.text()


GROUPS = {
    "checklist": {"teeth": teeth, "potty": potty, "water": water, "hug": hug},
    "lullaby": {"musicBox": music_box, "humming": humming, "rain": rain, "waves": waves, "fan": fan, "heartbeat": heartbeat},
    "ui": {"close": close, "speak": speak, "next": next_page, "lock": lock},
}


def build():
    n = 0
    for folder, items in GROUPS.items():
        for name, f in items.items():
            kit.write_svg(f"{folder}/{name}.svg", f())
            n += 1
    print(f"icons: {n} pictures")


if __name__ == "__main__":
    build()
