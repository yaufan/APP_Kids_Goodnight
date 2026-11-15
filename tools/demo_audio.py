#!/usr/bin/env python3
"""Puts the music and sounds under the demo video.

test/demo/demo_video_test.dart writes, next to the silent video, which music
the app asked for and which sounds it played, frame by frame
(app/build/demo/sounds.txt). This mixes the same files from app/assets/sounds
into one track, at about the app's own balance, and writes
app/build/demo/demo.mp4.

    python3 tools/demo_audio.py
"""
import pathlib
import subprocess
import sys
import wave

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEMO = ROOT / "app/build/demo"
SOUNDS = ROOT / "app/assets/sounds"
RATE = 16000
MUSIC_GAIN, SFX_GAIN = 0.8, 0.9
FADE = 0.35  # seconds, when the music changes


def load(name):
    with wave.open(str(SOUNDS / f"{name}.wav")) as w:
        rate, n, width = w.getframerate(), w.getnframes(), w.getsampwidth()
        data = np.frombuffer(w.readframes(n), dtype=np.int16).astype(np.float64) / 32768
        if w.getnchannels() > 1:
            data = data.reshape(-1, w.getnchannels()).mean(axis=1)
    assert width == 2
    if rate != RATE:
        t = np.arange(int(len(data) * RATE / rate)) * rate / RATE
        data = np.interp(t, np.arange(len(data)), data)
    return data


def main():
    lines = (DEMO / "sounds.txt").read_text().split("\n")
    fps = int(lines[0].split()[1])
    frames = int(lines[1].split()[1])
    total = int(frames / fps * RATE) + RATE
    music = np.zeros(total)
    sfx = np.zeros(total)
    changes = []
    cache = {}
    for line in lines[2:]:
        if not line.strip():
            continue
        parts = line.split()
        frame, kind, name = parts[:3]
        level = float(parts[3]) if len(parts) > 3 else 1.0
        at = int(int(frame) / fps * RATE)
        if kind == "sfx":
            s = cache.setdefault(name, load(name))
            end = min(total, at + len(s))
            sfx[at:end] += s[: end - at]
        else:
            changes.append((at, None if name == "-" else name, level))
    # Each loop plays from its start until the next change (a new level counts as one).
    changes.append((total, None, 1.0))
    fade = int(FADE * RATE)
    origin = 0
    for i, ((start, name, level), (end, nxt, _)) in enumerate(zip(changes, changes[1:])):
        prev = changes[i - 1][1] if i else None
        if name != prev:
            origin = start
        if name is None or end <= start:
            continue
        loop = cache.setdefault(name, load(name))
        n = end - start
        # The same loop at a new level goes on where it was; a new loop fades in.
        piece = loop[(np.arange(start, end) - origin) % len(loop)].copy()
        ramp = min(fade, n // 2)
        if name != prev:
            piece[:ramp] *= np.linspace(0, 1, ramp)
        if nxt != name:
            piece[n - ramp:] *= np.linspace(1, 0, ramp)
        music[start:end] += piece * level
    mix = music * MUSIC_GAIN + sfx * SFX_GAIN
    peak = np.abs(mix).max()
    if peak > 0.95:
        mix *= 0.95 / peak
    pcm = (mix * 32767).astype(np.int16)
    out = DEMO / "demo_audio.wav"
    with wave.open(str(out), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", str(DEMO / "demo_silent.mp4"), "-i", str(out),
         "-c:v", "copy", "-c:a", "aac", "-b:a", "96k", "-shortest", "-movflags", "+faststart", str(DEMO / "demo.mp4")],
        check=True,
    )
    print(f"{DEMO / 'demo.mp4'}: {frames / fps:.1f} s, peak {peak:.2f}")


if __name__ == "__main__":
    sys.exit(main())
