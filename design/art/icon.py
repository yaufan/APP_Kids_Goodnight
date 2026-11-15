"""晚安小鎮's app icon, in the starlight-silhouette look: a sleepy crescent moon over the town's
rooftops on deep blue, one window still warm, a few stars.

    python3 icon.py preview OUT.png      # big, as a phone cuts it (round, squircle, square) at 96 and 48 px,
                                         # and on a light and a dark home screen beside the sibling apps
    python3 icon.py export               # writes the Android and iOS icons into app/

export writes the same files as the sibling apps' icon.py: Android mipmap-*/ic_launcher.png (full
square art), the adaptive icon (mipmap-anydpi-v26/ic_launcher.xml with drawable-*/ic_launcher_foreground
and _background, the subject inside the middle 66 dp circle), and every PNG listed in iOS
AppIcon.appiconset/Contents.json (opaque). Drawn in 200 units, rendered at 1024 px by Chromium, scaled
with Pillow. Deterministic.
"""
import sys

sys.dont_write_bytecode = True

import json  # noqa: E402
import math  # noqa: E402
import pathlib  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import kit  # noqa: E402
from kit import MOON, MOON_LT, WARM, WARM_LT, poly, rect  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
APP = ROOT / "app"
RES = APP / "android" / "app" / "src" / "main" / "res"
IOS = APP / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
FONT = APP / "assets" / "fonts" / "jf-openhuninn-2.1.ttf"

U = 200
C = 1024
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
VIEW = 72 / 108


def background(view):
    s = kit.Svg(U, U)
    s.path(rect(0, 0, U, U), s.gradient([(0, "#151A40"), (1, "#36357A")]))
    r = kit.rnd("icon_stars")
    for _ in range(18):
        x, y = r.uniform(4, 196), r.uniform(4, 120)
        s.circle(U / 2 + (x - U / 2), U / 2 + (y - U / 2), r.uniform(.8, 1.8), "#FFF1C2", r.uniform(.4, .9))
    return s


def subject(s, v):
    """The moon and the rooftops, scaled by v about the middle."""
    def g(x, y):
        return U / 2 + (x - U / 2) * v, U / 2 + (y - U / 2) * v

    mx, my = g(116, 76)
    s.glow(mx, my, 60 * v, MOON, layers=7, top=0.07)
    s.path(kit.crescent(mx, my, 40 * v, dx=0.5, dy=-0.36), s.gradient([(0, MOON_LT), (1, MOON)], 0, 0, 1, 1))
    def pt(x, y):
        return "%s %s" % tuple(kit.n(c) for c in g(x, y))
    face = "#B98A4E"
    s.stroke(f"M{pt(90, 80)} Q{pt(95, 86)} {pt(100, 80)}", face, 3.2 * v)
    s.stroke(f"M{pt(94, 98)} Q{pt(101, 104)} {pt(108, 98)}", face, 3.2 * v)
    s.circle(*g(88, 92), 4.5 * v, kit.BLUSH, 0.6)
    # the rooftops
    roofs = [(14, 200), (14, 150), (40, 150), (40, 132), (66, 132), (66, 142), (86, 142), (86, 120), (100, 108), (114, 120),
             (114, 140), (140, 140), (140, 128), (170, 128), (170, 150), (190, 150), (190, 200)]
    s.path(poly([g(x, y) for x, y in roofs]), "#0F1331")
    for (x, y) in ((48, 146), (148, 140), (74, 154)):
        s.path(poly([g(x, y), g(x + 10, y), g(x + 10, y + 12), g(x, y + 12)]), "#283268")
    wx, wy = 92, 130
    s.glow(*g(wx + 8, wy + 8), 24 * v, WARM, layers=6, top=0.1)
    s.path(poly([g(wx, wy), g(wx + 16, wy), g(wx + 16, wy + 18), g(wx, wy + 18)]), WARM_LT)
    s.path(poly([g(wx + 7, wy), g(wx + 9, wy), g(wx + 9, wy + 18), g(wx + 7, wy + 18)]), "#0F1331")


def doc(s):
    return s.text().replace("<svg ", f'<svg width="{C}" height="{C}" ', 1)


def full_svg():
    s = background(1.0)
    subject(s, 1.0)
    return doc(s)


def bg_svg():
    return doc(background(VIEW))


def fg_svg():
    s = kit.Svg(U, U)
    subject(s, VIEW)
    return doc(s)


RENDER_JS = """
const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const jobs = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const browser = await chromium.launch();
  for (const [inp, out, px] of jobs) {
    const page = await browser.newPage({ viewport: { width: px, height: px }, deviceScaleFactor: 1 });
    await page.goto('file://' + inp);
    await page.screenshot({ path: out, omitBackground: true });
    await page.close();
  }
  await browser.close();
})();
"""


def render_all(svgs):
    with tempfile.TemporaryDirectory(dir=kit.SCRATCH, prefix="gn_icon_") as tmp:
        tmp = pathlib.Path(tmp)
        jobs = []
        for i, (key, text) in enumerate(svgs.items()):
            kit.check_svg(f"icon/{key}", text)
            (tmp / f"{i}.svg").write_text(text)
            jobs.append([str(tmp / f"{i}.svg"), str(tmp / f"{i}.png"), C])
        (tmp / "jobs.json").write_text(json.dumps(jobs))
        (tmp / "r.js").write_text(RENDER_JS)
        subprocess.run(["node", str(tmp / "r.js"), str(tmp / "jobs.json")], check=True, cwd=HERE)
        return {key: Image.open(tmp / f"{i}.png").convert("RGBA").copy() for i, key in enumerate(svgs)}


def art():
    im = render_all({"full": full_svg(), "bg": bg_svg(), "fg": fg_svg()})
    return im["full"].convert("RGB"), im["bg"].convert("RGB"), im["fg"]


def resized(img, px):
    return img.resize((px, px), Image.LANCZOS)


def launcher_view(bg, fg):
    whole = Image.alpha_composite(bg.convert("RGBA"), fg).convert("RGB")
    k = C * 18 / 108
    return whole.crop((round(k), round(k), round(C - k), round(C - k)))


def mask(kind, px):
    s = px * 4
    m = Image.new("L", (s, s), 0)
    dr = ImageDraw.Draw(m)
    if kind == "round":
        dr.ellipse((0, 0, s - 1, s - 1), fill=255)
    elif kind == "squircle":
        pts = []
        for i in range(720):
            t = 2 * math.pi * i / 720
            c, si = math.cos(t), math.sin(t)
            pts.append((s / 2 + s / 2 * math.copysign(abs(c) ** (2 / 5), c), s / 2 + s / 2 * math.copysign(abs(si) ** (2 / 5), si)))
        dr.polygon(pts, fill=255)
    else:
        dr.rounded_rectangle((0, 0, s - 1, s - 1), radius=s * .225, fill=255)
    return m.resize((px, px), Image.LANCZOS)


SIBLINGS = (("畫畫小鎮", "APP_Kids_Paint"), ("字母寵物", "app_kids_paint_for_learning_writing"), ("動物小餐廳", "app_kids_cook"),
            ("小卡認天下", "app_kids_card_game"), ("想一想樂園", "app_kids_brainstorming"), ("眼尖尖", "app_kids_falsecharge"),
            ("迷宮小冒險", "app_kids_maze"), ("小小生活家", "app_kids_live_circ"))


def font(size):
    try:
        return ImageFont.truetype(str(FONT), size)
    except OSError:
        return ImageFont.load_default()


def siblings():
    out = []
    for zh, repo in SIBLINGS:
        p = pathlib.Path("/home/user") / repo / "app" / "android" / "app" / "src" / "main" / "res" / "mipmap-xxxhdpi" / "ic_launcher.png"
        if p.is_file():
            out.append((zh, Image.open(p).convert("RGB")))
    return out


def home_screen(icons, dark, W):
    H = 104
    top, bottom = ("#3A3550", "#1E1B2B") if dark else ("#F6EFE6", "#E3EEF8")
    strip = Image.new("RGB", (W, H))
    dr = ImageDraw.Draw(strip)
    for y in range(H):
        dr.line([(0, y), (W, y)], fill=kit.mix(top, bottom, y / (H - 1)))
    step = W / len(icons)
    f = font(13)
    for i, (label, im) in enumerate(icons):
        x = round(step * i + step / 2 - 24)
        strip.paste(resized(im, 48), (x, 18), mask("round", 48))
        tw = dr.textlength(label, font=f)
        dr.text((x + 24 - tw / 2, 74), label, font=f, fill="#FFFFFF" if dark else "#3B3550")
    return strip


def preview(out):
    full, abg, afg = art()
    view = launcher_view(abg, afg)
    pad, big = 24, 512
    W = pad * 2 + big + 40 + 420
    H = pad + big + pad + 104 * 2 + pad
    sheet = Image.new("RGB", (W, H), "#FFFFFF")
    dr = ImageDraw.Draw(sheet)
    sheet.paste(resized(full, big), (pad, pad))
    x, y = pad + big + 40, pad
    dr.text((x, y), "adaptive (round, squircle), full art: 96 / 48 px", font=font(20), fill="#3B3550")
    y += 40
    for kind, im, s in (("round", view, 96), ("squircle", view, 96), ("square", full, 96)):
        sheet.paste(resized(im, s), (x, y), mask(kind, s))
        x += s + 24
    x, y = pad + big + 40, pad + 40 + 96 + 24
    for kind, im, s in (("round", view, 48), ("squircle", view, 48), ("square", full, 48), ("round", view, 36)):
        sheet.paste(resized(im, s), (x, y + 48 - s), mask(kind, s))
        x += s + 24
    y = pad + big + pad
    icons = siblings() + [("晚安小鎮", view)]
    sheet.paste(home_screen(icons, False, W - 2 * pad), (pad, y))
    sheet.paste(home_screen(icons, True, W - 2 * pad), (pad, y + 104))
    sheet.save(out)
    print(out)


ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
"""


def export():
    full, bg, fg = art()
    written = []
    for d, k in DENSITIES.items():
        mip = RES / f"mipmap-{d}"
        mip.mkdir(parents=True, exist_ok=True)
        resized(full, round(48 * k)).save(mip / "ic_launcher.png")
        dr = RES / f"drawable-{d}"
        dr.mkdir(parents=True, exist_ok=True)
        resized(fg, round(108 * k)).save(dr / "ic_launcher_foreground.png")
        resized(bg, round(108 * k)).save(dr / "ic_launcher_background.png")
        written += [mip / "ic_launcher.png", dr / "ic_launcher_foreground.png", dr / "ic_launcher_background.png"]
    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(ADAPTIVE_XML)
    written.append(anydpi / "ic_launcher.xml")
    contents = json.loads((IOS / "Contents.json").read_text())
    sizes = {}
    for image in contents["images"]:
        if image.get("filename"):
            px = round(float(image["size"].split("x")[0]) * float(image["scale"].rstrip("x")))
            sizes.setdefault(image["filename"], px)
    for fname, px in sizes.items():
        resized(full, px).convert("RGB").save(IOS / fname)
        written.append(IOS / fname)
    print(f"icon: {len(written)} files written")


if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "export":
        export()
    elif len(sys.argv) >= 3 and sys.argv[1] == "preview":
        preview(sys.argv[2])
    else:
        print(__doc__)
