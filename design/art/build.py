"""Writes the pictures of 晚安小鎮 (kit.py: starlight silhouettes) and checks them.

    python3 build.py all                    # every module below, then the checks
    python3 build.py <module>               # one module (street, animals, sky, sheep, story, icons)
    python3 build.py check                  # flutter_svg's rules on every SVG under app/assets/art
    python3 build.py street OUT.png [dark=cat,rabbit,...]   # the street composed as the app draws it
    python3 build.py sheet OUT.png [folder] # every picture on the night blue, with its name
    python3 build.py fluttercheck [folder]  # draw every file with the real flutter_svg (a throw-away
                                            # Flutter project in /dev/shm) and with Chromium; compare

Needs Python 3 (no packages for building), Node.js with Playwright (Chromium) for the previews and
fluttercheck, numpy + Pillow for fluttercheck, Flutter at /home/user/flutter/bin (or $FLUTTER) with
flutter_svg in the pub cache. Never runs git.
"""
import sys

sys.dont_write_bytecode = True      # no __pycache__ in design/art

import base64  # noqa: E402
import importlib  # noqa: E402
import json  # noqa: E402
import os  # noqa: E402
import pathlib  # noqa: E402
import re  # noqa: E402
import shutil  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402

import kit  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
MODULES = ("street", "animals", "sky", "sheep", "story", "icons")


def check_all():
    files = sorted(kit.ART.rglob("*.svg"))
    total = 0
    for p in files:
        total += kit.check_svg(str(p.relative_to(kit.ROOT)), p.read_text())
    print(f"check: {len(files)} SVG files are fine ({total:.0f} KB)")


SHOT_JS = r"""
const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const [html, out, w, h] = process.argv.slice(2);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 1 });
  await page.goto('file://' + html);
  await page.waitForTimeout(300);
  await page.screenshot({ path: out, fullPage: true });
  await browser.close();
})();
"""


def shot(html, out, w, h):
    with tempfile.TemporaryDirectory(dir=kit.SCRATCH, prefix="gn_shot_") as tmp:
        tmp = pathlib.Path(tmp)
        (tmp / "page.html").write_text(html)
        (tmp / "s.js").write_text(SHOT_JS)
        subprocess.run(["node", str(tmp / "s.js"), str(tmp / "page.html"), str(out), str(w), str(h)], check=True, cwd=HERE)
    print(out)


def uri(path, tokens=None):
    text = pathlib.Path(path).read_text()
    for k, v in (tokens or kit.TOKENS).items():
        text = text.replace(k, v)
    return "data:image/svg+xml;base64," + base64.b64encode(text.encode()).decode()


def street_preview(out, dark=()):
    """The street as the app draws it: sky, the street, the lights (on unless in `dark`), the animals."""
    import street
    k = 1.4
    W, H = street.W * k, street.H * k
    sky = "linear-gradient(#1A1F4A, #3A3576 55%, #B9708A)"
    els = [f'<img src="{uri(kit.ART / "street/street.svg")}" style="position:absolute;left:0;top:0;width:{W}px;height:{H}px">']
    for name, (art, tap, animal, pane) in street.layout().items():
        on = name not in dark
        if on:
            els.append(f'<img src="{uri(kit.ART / f"street/glow_{name}.svg")}" style="position:absolute;left:{art[0] * k}px;top:{art[1] * k}px;width:{art[2] * k}px;height:{art[3] * k}px">')
        if animal:
            a = name
            tok = kit.TOKENS if on else {kit.BODY: "#3E4A8A", kit.EYE: "#FFE9B0", kit.LID: "#9AA6E0"}
            f = kit.ART / f"animals/{a}_{'awake' if on else 'sleep'}.svg"
            els.append(f'<img src="{uri(f, tok)}" style="position:absolute;left:{animal[0] * k}px;top:{animal[1] * k}px;width:{animal[2] * k}px;height:{animal[3] * k}px">')
        if pane:
            els.append(f'<img src="{uri(kit.ART / "street/grille.svg")}" style="position:absolute;left:{pane[0] * k}px;top:{pane[1] * k}px;width:{pane[2] * k}px;height:{pane[3] * k}px">')
        els.append(f'<div style="position:absolute;left:{tap[0] * k}px;top:{tap[1] * k}px;width:{tap[2] * k}px;height:{tap[3] * k}px;outline:1px dashed rgba(255,255,255,.25)"></div>')
    els.append(f'<div style="position:absolute;left:{150 * k}px;top:0;width:{400 * k}px;height:{H}px;outline:2px solid rgba(255,120,120,.4)"></div>')
    html = f'<html><body style="margin:0;background:{sky}"><div style="position:relative;width:{W}px;height:{H}px">{"".join(els)}</div></body></html>'
    shot(html, out, int(W), int(H))


def story_preview(out):
    """Every place with an animal and a prop, as the story page shows them."""
    import story
    k = 1.0
    things = list(story.THINGS)
    animals = ["cat", "rabbit", "bear", "duck", "pig", "owl", "dog", "sheep"]
    tok = {kit.BODY: "#141836", kit.EYE: "#FFE9B0", kit.LID: "#9AA6E0"}
    cells = []
    for i, place in enumerate(list(story.PLACES) * 2):
        thing = things[i % len(things)]
        a = animals[i % len(animals)]
        asleep = i >= len(story.PLACES)
        ax, ay, aw, ah = story.ANIMAL_BOX
        tx, ty, tw, th = story.THING_BOX
        cells.append(f'<div style="position:relative;display:inline-block;width:320px;height:200px;margin:4px">'
                     f'<img src="{uri(kit.ART / f"story/place_{place}.svg")}" style="position:absolute;left:0;top:0;width:320px;height:200px">'
                     + ("" if asleep else f'<img src="{uri(kit.ART / f"story/thing_{thing}.svg")}" style="position:absolute;left:{tx}px;top:{ty}px;width:{tw}px;height:{th}px">')
                     + f'<img src="{uri(kit.ART / f"animals/{a}_{"sleep" if asleep else "awake"}.svg", tok)}" style="position:absolute;left:{ax}px;top:{ay}px;width:{aw}px;height:{ah}px;object-fit:contain;object-position:bottom">'
                     f'</div>')
    html = f'<html><body style="margin:6px;background:#0d1028;width:{3 * 330}px">{"".join(cells)}</body></html>'
    shot(html, out, 3 * 330 + 12, 400)


def sheet(out, folder=None):
    files = sorted((kit.ART / folder).rglob("*.svg") if folder else kit.ART.rglob("*.svg"))
    cells = []
    for f in files:
        vw, vh = kit.viewbox_of(f)
        s = 150 / max(vw, vh)
        cells.append(f'<div style="display:inline-block;width:170px;height:200px;margin:4px;vertical-align:top;text-align:center;'
                     f'font:11px sans-serif;color:#cfd3ff"><div style="height:170px;display:flex;align-items:center;justify-content:center;'
                     f'background:#232a5c"><img src="{uri(f)}" style="width:{vw * s}px;height:{vh * s}px"></div>{f.relative_to(kit.ART)}</div>')
    html = f'<html><body style="margin:8px;background:#151a3a;width:{8 * 178}px">{"".join(cells)}</body></html>'
    shot(html, out, 8 * 178 + 16, 400)


# ---------------------------------------------------------------- flutter_svg against Chromium
DART_TEST = r"""
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('render svgs', (tester) async {
    final lines = File('list.txt').readAsLinesSync().where((l) => l.trim().isNotEmpty);
    final failed = <String>[];
    for (final line in lines) {
      final p = line.split('|');
      final w = int.parse(p[2]), h = int.parse(p[3]);
      await tester.runAsync(() async {
        try {
          final info = await vg.loadPicture(SvgStringLoader(File(p[0]).readAsStringSync()), null);
          final rec = ui.PictureRecorder();
          final c = Canvas(rec);
          c.scale(w / info.size.width, h / info.size.height);
          c.drawPicture(info.picture);
          final img = await rec.endRecording().toImage(w, h);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          File(p[1]).writeAsBytesSync(bytes!.buffer.asUint8List());
          info.picture.dispose();
        } catch (e) {
          failed.add('${p[0]}: $e');
        }
      });
    }
    File('failed.txt').writeAsStringSync(failed.join('\n'));
  });
}
"""

CHROME_JS = r"""
const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const lines = fs.readFileSync(process.argv[2], 'utf8').split('\n').filter(l => l.trim());
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 400, height: 400 }, deviceScaleFactor: 1 });
  for (const line of lines) {
    const [inp, out, w, h] = line.split('|');
    const svg = fs.readFileSync(inp);
    await page.setViewportSize({ width: +w, height: +h });
    await page.setContent(`<html><body style="margin:0;background:transparent"><img style="display:block;width:${w}px;height:${h}px" src="data:image/svg+xml;base64,${svg.toString('base64')}"></body></html>`);
    await page.waitForFunction(() => document.images[0].complete);
    await page.screenshot({ path: out, omitBackground: true });
  }
  await browser.close();
})();
"""


def fluttercheck(which=None, px=300):
    import numpy as np
    from PIL import Image
    files = sorted((kit.ART / which).rglob("*.svg") if which else kit.ART.rglob("*.svg"))
    flutter = pathlib.Path(os.environ.get("FLUTTER", "/home/user/flutter/bin")) / "flutter"
    work = pathlib.Path(tempfile.mkdtemp(prefix="gn_svgcheck_", dir=kit.SCRATCH))
    try:
        for sub in ("lib", "test", "out", "src"):
            (work / sub).mkdir()
        (work / "pubspec.yaml").write_text("name: svgcheck\npublish_to: 'none'\nversion: 0.0.1\nenvironment:\n  sdk: ^3.13.7\n"
                                           "dependencies:\n  flutter:\n    sdk: flutter\n  flutter_svg: ^2.3.0\n"
                                           "dev_dependencies:\n  flutter_test:\n    sdk: flutter\n")
        (work / "lib" / "main.dart").write_text("void main() {}\n")
        (work / "test" / "render_test.dart").write_text(DART_TEST)
        (work / "shot.js").write_text(CHROME_JS)
        fl, cr = [], []
        for i, f in enumerate(files):
            src = work / "src" / f"{i}.svg"
            src.write_text(kit.with_tokens(f.read_text()))
            vw, vh = kit.viewbox_of(f)
            s = px / max(vw, vh)
            w, h = max(8, round(vw * s)), max(8, round(vh * s))
            fl.append(f"{src}|{work / 'out' / f'{i}_f.png'}|{w}|{h}")
            cr.append(f"{src}|{work / 'out' / f'{i}_c.png'}|{w}|{h}")
        (work / "list.txt").write_text("\n".join(fl))
        (work / "crlist.txt").write_text("\n".join(cr))
        r = subprocess.run([str(flutter), "pub", "get", "--offline"], cwd=work, capture_output=True, text=True)
        if r.returncode:
            raise SystemExit("flutter pub get --offline failed:\n" + r.stdout[-1500:] + r.stderr[-1500:])
        r = subprocess.run([str(flutter), "test", "test/render_test.dart"], cwd=work, capture_output=True, text=True)
        if r.returncode:
            raise SystemExit("flutter test failed:\n" + r.stdout[-3000:] + r.stderr[-3000:])
        failed = (work / "failed.txt").read_text().strip()
        if failed:
            print("flutter_svg could not draw:\n" + failed)
        subprocess.run(["node", str(work / "shot.js"), str(work / "crlist.txt")], cwd=HERE, check=True)
        rows = []
        for i, f in enumerate(files):
            a, b = work / "out" / f"{i}_f.png", work / "out" / f"{i}_c.png"
            if not a.exists():
                rows.append((1.0, 1.0, f))
                continue
            A = np.asarray(Image.open(a).convert("RGBA")).astype(float)
            B = np.asarray(Image.open(b).convert("RGBA")).astype(float)

            def flat(X):
                al = X[..., 3:4] / 255
                return X[..., :3] * al + 255 * (1 - al)
            D = np.abs(flat(A) - flat(B)).max(axis=2)
            big = D > 60
            core = big[1:-1, 1:-1] & big[:-2, 1:-1] & big[2:, 1:-1] & big[1:-1, :-2] & big[1:-1, 2:]
            rows.append((core.mean(), D.mean() / 255, f))
        rows.sort(key=lambda r: (-r[0], -r[1]))
        bad = [r for r in rows if r[0] > .004]
        print(f"fluttercheck: {len(files)} files; worst:")
        for frac, mean, f in rows[:6]:
            print(f"  {frac * 100:6.2f}% solid differences, mean {mean * 100:.2f}%  {f.relative_to(kit.ROOT)}")
        if bad or failed:
            raise SystemExit(f"{len(bad)} files draw differently in flutter_svg")
        print("fluttercheck: flutter_svg draws every file like Chromium")
    finally:
        shutil.rmtree(work, ignore_errors=True)


def main(argv):
    if not argv:
        print(__doc__)
        return
    cmd, rest = argv[0], argv[1:]
    if cmd == "all":
        for m in MODULES:
            if (HERE / f"{m}.py").exists():
                importlib.import_module(m).build()
        check_all()
    elif cmd == "check":
        check_all()
    elif cmd == "street" and rest:
        dark = rest[1].split("=", 1)[1].split(",") if len(rest) > 1 else ()
        street_preview(rest[0], dark)
    elif cmd == "story" and rest:
        story_preview(rest[0])
    elif cmd == "sheet":
        sheet(rest[0], rest[1] if len(rest) > 1 else None)
    elif cmd == "fluttercheck":
        fluttercheck(rest[0] if rest else None)
    elif cmd in MODULES:
        importlib.import_module(cmd).build()
    else:
        raise SystemExit(f"unknown: {cmd}")


if __name__ == "__main__":
    main(sys.argv[1:])
