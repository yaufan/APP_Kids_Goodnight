#!/usr/bin/env python3
"""Synthesises every sound of 晚安小鎮 with numpy (docs/design.md 「聲音」): quiet, slow, soft.

    python3 make_sounds.py            # writes app/assets/sounds/*.wav (16 kHz, mono, 16 bit)
    python3 make_sounds.py rain puff  # only these

Deterministic: every sound has its own random generator, seeded by its name, so building again gives
the same bytes. Loops are seamless: noise is filtered in the frequency domain (which wraps round), and
notes that run past the end of a tune ring on at its start.

The tunes: 小星星 (Twinkle, Twinkle, Little Star) and Brahms's Wiegenlied are old folk/classical
melodies free of copyright; the third music-box tune and the second humming tune are written here.
"""
import pathlib
import sys
import wave
import zlib

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "assets" / "sounds"
SR = 16000


def rng(name):
    return np.random.default_rng(zlib.crc32(name.encode()))


def write(name, x, peak):
    x = np.asarray(x, dtype=np.float64)
    m = np.abs(x).max()
    if m > 0:
        x = x / m * peak
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def t_of(dur):
    return np.arange(int(dur * SR)) / SR


def fade(x, a=0.01, b=0.05):
    n = len(x)
    ia, ib = int(a * SR), int(b * SR)
    if ia:
        x[:ia] *= np.linspace(0, 1, ia) ** 2
    if ib:
        x[n - ib:] *= np.linspace(1, 0, ib) ** 2
    return x


def spectral(noise, lo=None, hi=None, tilt=0.0):
    """Circular band filter (seamless for loops): keep lo..hi Hz with soft edges; tilt in dB/octave."""
    n = len(noise)
    F = np.fft.rfft(noise)
    f = np.fft.rfftfreq(n, 1 / SR)
    g = np.ones_like(f)
    if lo:
        g *= 1 / (1 + (lo / np.maximum(f, 1)) ** 4)
    if hi:
        g *= 1 / (1 + (f / hi) ** 4)
    if tilt:
        g *= (np.maximum(f, 20) / 1000) ** (tilt / 6.02)
    return np.fft.irfft(F * g, n)


def smooth_noise(n, rate_hz, r):
    """A slowly wandering 0..1 curve, periodic over n samples."""
    k = max(1, int(n / SR * rate_hz))
    pts = r.uniform(0, 1, k)
    xs = np.linspace(0, k, n, endpoint=False)
    i = xs.astype(int)
    fr = xs - i
    a, b = pts[i % k], pts[(i + 1) % k]
    w = (1 - np.cos(np.pi * fr)) / 2
    return a + (b - a) * w


def lowpass1(x, fc):
    a = np.exp(-2 * np.pi * fc / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y


# ---------------------------------------------------------------- ambience (loops)
def crickets(n, r, density):
    out = np.zeros(n)
    t = np.arange(int(0.05 * SR)) / SR
    for _ in range(int(n / SR * density)):
        at = r.integers(0, n)
        f = r.uniform(4200, 4800)
        pulses = r.integers(2, 4)
        for p in range(pulses):
            s = at + int(p * 0.06 * SR)
            chirp = np.sin(2 * np.pi * f * t) * np.sin(np.pi * t / t[-1]) ** 2 * r.uniform(.4, 1)
            idx = (s + np.arange(len(t))) % n
            out[idx] += chirp
    return out


def wind(n, r, level=1.0):
    w = spectral(r.normal(0, 1, n), lo=80, hi=700, tilt=-3)
    w /= np.abs(w).max()
    return w * (0.35 + 0.65 * smooth_noise(n, 0.15, r)) * level


def scooter(n, r):
    """A scooter passing far away, once in the loop (silent at the loop's edges)."""
    t = np.arange(n) / SR
    mid, width = n / SR * 0.55, 5.0
    env = np.exp(-((t - mid) / width) ** 2)
    f0 = 70 + 8 * np.tanh((t - mid) / 2)
    ph = 2 * np.pi * np.cumsum(f0) / SR
    tone = sum(np.sin(ph * k) / k for k in range(1, 6))
    hiss = spectral(r.normal(0, 1, n), lo=200, hi=1200)
    hiss /= np.abs(hiss).max()
    return env * (tone * 0.35 + hiss * 0.25)


def amb(name, dur, cricket_density, scooter_on):
    r = rng(name)
    n = int(dur * SR)
    x = wind(n, r) * 0.6
    if cricket_density:
        c = crickets(n, r, cricket_density)
        x += c / max(np.abs(c).max(), 1e-9) * 0.25
    if scooter_on:
        x += scooter(n, r) * 0.5
    return x


# ---------------------------------------------------------------- music box and humming
NOTE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def hz(note):
    """'C4', 'G#3', 'C5'."""
    name, octave = note[:-1], int(note[-1])
    semis = NOTE[name[0]] + (1 if "#" in name else 0) - (1 if "b" in name[1:] else 0)
    return 440 * 2 ** ((semis + 12 * (octave - 4) - 9) / 12)


# (note, beats); "-" is a rest. Slow: a beat is BEAT seconds.
TWINKLE = [("C5", 1), ("C5", 1), ("G5", 1), ("G5", 1), ("A5", 1), ("A5", 1), ("G5", 2),
           ("F5", 1), ("F5", 1), ("E5", 1), ("E5", 1), ("D5", 1), ("D5", 1), ("C5", 2),
           ("G5", 1), ("G5", 1), ("F5", 1), ("F5", 1), ("E5", 1), ("E5", 1), ("D5", 2),
           ("G5", 1), ("G5", 1), ("F5", 1), ("F5", 1), ("E5", 1), ("E5", 1), ("D5", 2),
           ("C5", 1), ("C5", 1), ("G5", 1), ("G5", 1), ("A5", 1), ("A5", 1), ("G5", 2),
           ("F5", 1), ("F5", 1), ("E5", 1), ("E5", 1), ("D5", 1), ("D5", 1), ("C5", 2), ("-", 2)]
TWINKLE_BASS = [(n + "3" if n != "C" else "C4", 2) for n in "C C F C F C G C C F C G C F C G C C F C F C G C C".split()]

BRAHMS = [("E5", .5), ("E5", .5), ("G5", 2), ("E5", .5), ("E5", .5), ("G5", 2),
          ("E5", .5), ("G5", .5), ("C6", 1), ("B5", 1.5), ("A5", .5), ("A5", 1), ("G5", 1),
          ("D5", .5), ("E5", .5), ("F5", 1), ("D5", 1), ("D5", .5), ("E5", .5), ("F5", 2),
          ("D5", .5), ("F5", .5), ("B5", .5), ("A5", .5), ("G5", 1), ("B5", 1), ("C6", 2),
          ("C5", .5), ("C5", .5), ("C6", 2), ("A5", .5), ("F5", .5), ("G5", 2),
          ("E5", .5), ("C5", .5), ("F5", 1), ("G5", 1), ("A5", 1), ("G5", 2),
          ("C5", .5), ("C5", .5), ("C6", 2), ("A5", .5), ("F5", .5), ("G5", 2),
          ("E5", .5), ("C5", .5), ("F5", 1), ("E5", .5), ("D5", .5), ("C5", 3), ("-", 1)]
BRAHMS_BASS = [("C4", 3), ("C4", 3), ("C4", 3), ("G3", 3), ("G3", 3), ("G3", 3), ("G3", 3), ("C4", 3),
               ("F3", 3), ("C4", 3), ("C4", 3), ("G3", 3), ("F3", 3), ("C4", 3), ("G3", 3), ("C4", 4)]

# Written here: a slow, rocking tune on the five notes C D E G A.
OWN = [("G5", 1), ("E5", 1), ("D5", 1), ("C5", 3), ("D5", 1), ("E5", 1), ("G5", 1), ("E5", 3),
       ("A5", 1), ("G5", 1), ("E5", 1), ("D5", 2), ("E5", 1), ("D5", 1), ("C5", 1), ("D5", 3), ("-", 3),
       ("G5", 1), ("A5", 1), ("G5", 1), ("E5", 3), ("D5", 1), ("E5", 1), ("G5", 1), ("A5", 3),
       ("G5", 1), ("E5", 1), ("D5", 1), ("E5", 2), ("D5", 1), ("C5", 6)]
OWN_BASS = [("C4", 6), ("C4", 6), ("F3", 6), ("G3", 8), ("C4", 6), ("A3", 6), ("F3", 6), ("C4", 6)]


def music_box_note(f, dur, r):
    t = np.arange(int(dur * SR)) / SR
    x = (np.sin(2 * np.pi * f * t) * np.exp(-t * 1.6)
         + 0.25 * np.sin(2 * np.pi * 2 * f * t + 0.3) * np.exp(-t * 3.5)
         + 0.08 * np.sin(2 * np.pi * 3.01 * f * t) * np.exp(-t * 7)
         + 0.05 * np.sin(2 * np.pi * 5.4 * f * t) * np.exp(-t * 14))
    x *= np.minimum(1, t / 0.004)
    return x * r.uniform(0.85, 1.0)


def tune(melody, bass, beat, voice, r, bass_level=0.35):
    """Melody (and a soft bass) into a seamless loop: notes ring on past the end at the start."""
    beats = sum(b for _, b in melody)
    n = int(beats * beat * SR)
    out = np.zeros(n)
    for line, level in ((melody, 1.0), (bass, bass_level)):
        at = 0.0
        for note, b in line:
            if note != "-":
                f = hz(note)
                x = voice(f, b * beat, r) * level
                s = int(at * beat * SR)
                idx = (s + np.arange(len(x))) % n
                np.add.at(out, idx, x)
            at += b
    return out


def mbox(f, d, r):
    return music_box_note(f, max(d, 1.0) + 2.2, r)


def hum_voice(f, d, r):
    """A soft 'mm…' hum: a few harmonics shaped like a closed mouth (strong first, a nasal bump near
    250 Hz), a slow swell, a little vibrato."""
    f = f / 2                                   # hummed an octave lower than the music box
    dur = d + 0.35
    t = np.arange(int(dur * SR)) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5 * t + r.uniform(0, 6))
    ph = 2 * np.pi * f * np.cumsum(vib) / SR
    x = np.zeros_like(t)
    for k in range(1, 9):
        fk = f * k
        amp = (1 / k ** 1.4) * (1 + 1.5 * np.exp(-((fk - 260) / 120) ** 2))
        x += amp * np.sin(k * ph)
    env = np.minimum(1, t / 0.18) * np.minimum(1, (dur - t) / 0.3)
    return x * np.clip(env, 0, 1) * 0.5


# ---------------------------------------------------------------- white noise and the like
def rain(name):
    r = rng(name)
    n = int(20 * SR)
    hiss = spectral(r.normal(0, 1, n), lo=900, hi=5000, tilt=-2)
    hiss /= np.abs(hiss).max()
    hiss *= 0.75 + 0.25 * smooth_noise(n, 0.3, r)
    drops = np.zeros(n)
    tt = np.arange(int(0.03 * SR)) / SR
    for _ in range(int(20 * 18)):
        at = r.integers(0, n)
        f = r.uniform(1800, 4200)
        d = np.sin(2 * np.pi * f * tt) * np.exp(-tt * 180) * r.uniform(.2, 1)
        drops[(at + np.arange(len(tt))) % n] += d
    low = spectral(r.normal(0, 1, n), lo=60, hi=400)
    low /= np.abs(low).max()
    return hiss * 0.6 + drops / np.abs(drops).max() * 0.25 + low * 0.25


def waves(name):
    r = rng(name)
    period = 8.0
    n = int(3 * period * SR)
    t = np.arange(n) / SR
    surf = spectral(r.normal(0, 1, n), lo=150, hi=2200, tilt=-3)
    surf /= np.abs(surf).max()
    ph = (t % period) / period
    swell = np.where(ph < 0.45, (ph / 0.45) ** 2, np.exp(-(ph - 0.45) * 5))
    swell = swell * (0.85 + 0.15 * smooth_noise(n, 0.2, r))
    rumble = spectral(r.normal(0, 1, n), lo=30, hi=180)
    rumble /= np.abs(rumble).max()
    return surf * (0.12 + 0.88 * swell) * 0.8 + rumble * 0.25


def fan(name):
    r = rng(name)
    n = int(20 * SR)
    t = np.arange(n) / SR
    air = spectral(r.normal(0, 1, n), lo=60, hi=1500, tilt=-4)
    air /= np.abs(air).max()
    hum = 0.06 * np.sin(2 * np.pi * 100 * t) + 0.03 * np.sin(2 * np.pi * 200 * t)
    beat = 1 + 0.06 * np.sin(2 * np.pi * 15 * t)
    return air * beat * 0.8 + hum


def heartbeat(name):
    r = rng(name)
    bpm = 60
    beats = 16
    n = int(beats * 60 / bpm * SR)
    out = np.zeros(n)
    tt = np.arange(int(0.25 * SR)) / SR
    for b in range(beats):
        for offset, f, lv in ((0.0, 52, 1.0), (0.28, 46, 0.65)):
            thump = np.sin(2 * np.pi * f * tt) * np.exp(-tt * 22) * np.minimum(1, tt / 0.008) * lv * r.uniform(.92, 1)
            s = int((b * 60 / bpm + offset) * SR)
            out[(s + np.arange(len(tt))) % n] += thump
    muff = spectral(r.normal(0, 1, n), lo=40, hi=220)
    muff /= np.abs(muff).max()
    return out + muff * 0.04


# ---------------------------------------------------------------- short sounds
def voiced(f0, formants, dur, r, breath=0.2, harmonics=24):
    """A voice-like sound: harmonics of the pitch curve f0 (Hz per sample) shaped by formants
    [(Hz, width, gain)], with breath noise."""
    n = len(f0)
    ph = 2 * np.pi * np.cumsum(f0) / SR
    x = np.zeros(n)
    for k in range(1, harmonics + 1):
        fk = f0 * k
        amp = sum(g * np.exp(-((fk - fc) / bw) ** 2) for fc, bw, g in formants) / k ** 0.6
        amp = np.where(fk < SR / 2 - 200, amp, 0)
        x += amp * np.sin(k * ph)
    noise = spectral(r.normal(0, 1, n), lo=300, hi=3500)
    noise /= np.abs(noise).max()
    return x / max(np.abs(x).max(), 1e-9) + noise * breath


def yawn(name, f_start, f_peak, f_end, dur, formants, breath=0.25, squeak=False):
    r = rng(name)
    n = int(dur * SR)
    t = np.arange(n) / n
    f0 = np.where(t < 0.25, f_start + (f_peak - f_start) * (t / 0.25), f_peak + (f_end - f_peak) * np.clip((t - 0.25) / 0.75, 0, 1) ** 0.8)
    f0 = f0 * (1 + 0.01 * np.sin(2 * np.pi * 5 * t * dur))
    x = voiced(f0, formants, dur, r, breath=breath)
    # an in-breath, then the voice opening and closing softly
    env = np.clip(np.minimum(t / 0.18, 1) * np.minimum((1 - t) / 0.35, 1), 0, 1) ** 1.5
    inhale = spectral(r.normal(0, 1, n), lo=600, hi=3000)
    inhale /= np.abs(inhale).max()
    inhale *= np.exp(-((t - 0.06) / 0.07) ** 2) * 0.3
    return fade(x * env + inhale, 0.005, 0.08)


AH = [(750, 200, 1.0), (1150, 250, 0.6), (2600, 400, 0.15)]
OH = [(450, 150, 1.0), (800, 200, 0.5)]
UU = [(330, 120, 1.0), (700, 200, 0.2)]


def puff(name, dur=0.4, level=1.0):
    r = rng(name)
    n = int(dur * SR)
    t = np.arange(n) / n
    x = spectral(r.normal(0, 1, n), lo=250, hi=2400)
    x /= np.abs(x).max()
    env = np.minimum(t / 0.08, 1) * np.exp(-t * 4)
    return fade(x * env * level, 0.003, 0.05)


def tap(name):
    t = t_of(0.12)
    x = np.sin(2 * np.pi * 880 * t) * np.exp(-t * 45) + 0.3 * np.sin(2 * np.pi * 1320 * t) * np.exp(-t * 70)
    return fade(x, 0.002, 0.02)


def hop(name):
    t = t_of(0.35)
    f = 110 * np.exp(-t * 3)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 14)
    r = rng(name)
    felt = spectral(r.normal(0, 1, len(t)), lo=100, hi=600)
    felt /= np.abs(felt).max()
    return fade(x + felt * np.exp(-t * 30) * 0.3, 0.003, 0.05)


def baa(name):
    r = rng(name)
    dur = 0.8
    n = int(dur * SR)
    t = np.arange(n) / SR
    f0 = 290 + 25 * np.sin(2 * np.pi * 6.5 * t) - 30 * t
    x = voiced(f0, [(700, 220, 1.0), (1100, 260, 0.5), (2400, 300, 0.12)], dur, r, breath=0.1)
    env = np.minimum(t / 0.06, 1) * np.minimum((dur - t) / 0.3, 1) * (0.8 + 0.2 * np.sin(2 * np.pi * 6.5 * t))
    return fade(x * env, 0.005, 0.06)


def page(name):
    r = rng(name)
    n = int(0.6 * SR)
    t = np.arange(n) / n
    x = spectral(r.normal(0, 1, n), lo=1500, hi=6500)
    x /= np.abs(x).max()
    env = np.exp(-((t - 0.35) / 0.18) ** 2) * (0.6 + 0.4 * smooth_noise(n, 40, r))
    return fade(x * env, 0.005, 0.05)


def breath(name, dur, rising):
    r = rng(name)
    n = int(dur * SR)
    t = np.arange(n) / n
    x = spectral(r.normal(0, 1, n), lo=200, hi=1800, tilt=-2)
    x /= np.abs(x).max()
    env = np.sin(np.pi * t) ** 1.2 * (t ** 0.5 if rising else (1 - t) ** 0.5 + 0.2)
    return fade(x * env, 0.2, 0.4)


def goodnight(name):
    r = rng(name)
    out = np.zeros(int(4.0 * SR))
    for i, note in enumerate(["G5", "E5", "C5"]):
        x = music_box_note(hz(note), 2.6, r) * (1 - i * 0.12)
        s = int(i * 0.7 * SR)
        out[s:s + len(x)] += x[: len(out) - s]
    return fade(out, 0.002, 0.6)


# name: (maker, peak)
SOUNDS = {
    "amb_dusk": (lambda: amb("amb_dusk", 30, 9, True), 0.5),
    "amb_quiet": (lambda: amb("amb_quiet", 30, 4, False), 0.45),
    "amb_wind": (lambda: amb("amb_wind", 30, 0, False), 0.4),
    "musicbox_1": (lambda: tune(TWINKLE, TWINKLE_BASS, 0.8, mbox, rng("musicbox_1")), 0.55),
    "musicbox_2": (lambda: tune(BRAHMS, BRAHMS_BASS, 0.62, mbox, rng("musicbox_2"), 0.25), 0.55),
    "musicbox_3": (lambda: tune(OWN, OWN_BASS, 0.62, mbox, rng("musicbox_3")), 0.55),
    "humming_1": (lambda: tune(BRAHMS, [], 0.75, hum_voice, rng("humming_1")), 0.38),
    "humming_2": (lambda: tune(OWN, [], 0.72, hum_voice, rng("humming_2")), 0.38),
    "rain": (lambda: rain("rain"), 0.45),
    "waves": (lambda: waves("waves"), 0.5),
    "fan": (lambda: fan("fan"), 0.4),
    "heartbeat": (lambda: heartbeat("heartbeat"), 0.6),
    "tap": (lambda: tap("tap"), 0.25),
    "puff": (lambda: puff("puff"), 0.45),
    "puff_soft": (lambda: puff("puff_soft", 0.25), 0.2),
    "yawn_small": (lambda: yawn("yawn_small", 380, 460, 320, 0.9, AH, 0.3), 0.35),
    "yawn_cat": (lambda: yawn("yawn_cat", 520, 680, 420, 1.0, [(900, 250, 1.0), (1500, 300, 0.5), (3000, 400, 0.2)], 0.25), 0.45),
    "yawn_rabbit": (lambda: yawn("yawn_rabbit", 700, 820, 600, 0.7, [(1000, 250, 1.0), (2200, 400, 0.4)], 0.45), 0.35),
    "yawn_bear": (lambda: yawn("yawn_bear", 140, 180, 100, 1.4, OH, 0.2), 0.55),
    "yawn_duck": (lambda: yawn("yawn_duck", 330, 380, 300, 0.9, [(1100, 200, 1.0), (1700, 300, 0.7)], 0.15), 0.4),
    "yawn_pig": (lambda: yawn("yawn_pig", 220, 260, 170, 1.1, [(500, 180, 1.0), (1000, 250, 0.5)], 0.35), 0.45),
    "yawn_owl": (lambda: yawn("yawn_owl", 360, 400, 330, 1.2, UU, 0.1), 0.45),
    "yawn_dog": (lambda: yawn("yawn_dog", 300, 420, 230, 1.1, AH, 0.3), 0.45),
    "yawn_sheep": (lambda: yawn("yawn_sheep", 280, 320, 240, 1.0, AH, 0.25), 0.4),
    "sheep_hop": (lambda: hop("sheep_hop"), 0.45),
    "baa": (lambda: baa("baa"), 0.3),
    "page": (lambda: page("page"), 0.25),
    "breath_in": (lambda: breath("breath_in", 4.0, True), 0.25),
    "breath_out": (lambda: breath("breath_out", 6.0, False), 0.25),
    "goodnight": (lambda: goodnight("goodnight"), 0.4),
}


def main(names):
    for name in names or SOUNDS:
        maker, peak = SOUNDS[name]
        write(name, maker(), peak)
    total = sum(p.stat().st_size for p in OUT.glob("*.wav"))
    print(f"{len(names or SOUNDS)} sounds written; app/assets/sounds is {total / 1e6:.1f} MB")


if __name__ == "__main__":
    main(sys.argv[1:])
