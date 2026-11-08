"""Synthesises the small SFX added in 0.13: perfect dodge and elevator chime.

Writes 16-bit mono 44.1 kHz WAVs into assets/audio/. Standard library
only, deterministic. Usage: python tools/generate_sfx_extra.py
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100


def write(name: str, samples: list[float]) -> None:
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = 0.8 / peak
    out = ROOT / "assets" / "audio" / f"{name}.wav"
    with wave.open(str(out), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in samples))
    print("wrote", out.relative_to(ROOT))


def perfect_dodge() -> list[float]:
    # A bright bell partial stack with a quick upward sweep and airy tail.
    rng = random.Random(7)
    n = int(RATE * 0.55)
    out = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-t * 7.0)
        sweep = 1.0 + 0.25 * min(t / 0.06, 1.0)
        s = 0.0
        for ratio, amp in ((1.0, 1.0), (2.76, 0.5), (5.4, 0.25), (8.93, 0.12)):
            s += amp * math.sin(2 * math.pi * 1320 * ratio * sweep * t)
        air = (rng.random() * 2 - 1) * math.exp(-t * 18.0) * 0.25
        out.append(s * env + air)
    return out


def elevator_call() -> list[float]:
    # Two-note mechanical chime over a short relay click.
    rng = random.Random(3)
    n = int(RATE * 0.7)
    out = []
    for i in range(n):
        t = i / RATE
        click = (rng.random() * 2 - 1) * math.exp(-t * 120.0) * 0.6
        s = 0.0
        for start, freq in ((0.0, 659.25), (0.16, 880.0)):
            if t >= start:
                lt = t - start
                env = math.exp(-lt * 5.5)
                s += env * (math.sin(2 * math.pi * freq * lt) + 0.3 * math.sin(2 * math.pi * freq * 3.01 * lt))
        out.append(s * 0.7 + click)
    return out


def noise_burst(seconds, decay, lowpass, seed):
    rng = random.Random(seed)
    n = int(RATE * seconds)
    out, prev = [], 0.0
    for i in range(n):
        t = i / RATE
        prev += (rng.random() * 2 - 1 - prev) * lowpass
        out.append(prev * math.exp(-t * decay))
    return out


def enemy_die():
    # Wet ink splat: low-passed noise + a falling blip.
    out = noise_burst(0.45, 9.0, 0.18, 11)
    for i in range(len(out)):
        t = i / RATE
        out[i] += 0.5 * math.sin(2 * math.pi * (220 - 160 * t) * t) * math.exp(-t * 12.0)
    return out


def elite_die():
    # Cracked bell: inharmonic partials with a long tail over a thump.
    n = int(RATE * 1.4)
    out = []
    for i in range(n):
        t = i / RATE
        s = sum(a * math.sin(2 * math.pi * 196 * r * t) for r, a in ((1, 1), (2.41, 0.6), (3.77, 0.35), (5.9, 0.2)))
        out.append(s * math.exp(-t * 2.6) + 0.8 * math.sin(2 * math.pi * 55 * t) * math.exp(-t * 14))
    return out


def wisp_blast():
    out = noise_burst(0.6, 6.0, 0.35, 23)
    for i in range(len(out)):
        t = i / RATE
        out[i] += 0.6 * math.sin(2 * math.pi * (90 - 40 * t) * t) * math.exp(-t * 8.0)
    return out


def jelly_pulse():
    rng = random.Random(5)
    n = int(RATE * 0.7)
    out = []
    for i in range(n):
        t = i / RATE
        buzz = math.sin(2 * math.pi * 120 * t) * (1 if math.sin(2 * math.pi * 31 * t) > 0 else -0.3)
        crackle = (rng.random() * 2 - 1) * (0.6 if rng.random() < 0.08 else 0.05)
        out.append((buzz * 0.6 + crackle) * math.exp(-t * 5.0) * min(1.0, t * 40))
    return out


def bell_toll():
    # Rusted bell struck once: detuned low partials, a metallic clank, long hum.
    n = int(RATE * 1.6)
    rng = random.Random(41)
    out = []
    for i in range(n):
        t = i / RATE
        s = sum(a * math.sin(2 * math.pi * 147 * r * t + r) for r, a in ((1, 1), (1.98, 0.5), (2.63, 0.45), (4.11, 0.25), (5.47, 0.12)))
        clank = (rng.random() * 2 - 1) * math.exp(-t * 60.0) * 0.9
        out.append(s * math.exp(-t * 1.9) * (1 + 0.15 * math.sin(2 * math.pi * 4.5 * t)) + clank)
    return out


def page_fan():
    # Wet paper flung: three soggy flaps.
    out = [0.0] * int(RATE * 0.5)
    for k, start in enumerate((0.0, 0.07, 0.14)):
        burst = noise_burst(0.18, 28.0, 0.22, 60 + k)
        off = int(start * RATE)
        for i, v in enumerate(burst):
            if off + i < len(out):
                out[off + i] += v * (1.0 - k * 0.2)
    return out


def puppet_slam():
    # Wooden joints clatter, then a hollow stage-floor thud.
    rng = random.Random(77)
    n = int(RATE * 0.8)
    out = []
    for i in range(n):
        t = i / RATE
        thud = math.sin(2 * math.pi * (70 - 30 * t) * t) * math.exp(-t * 9.0)
        clatter = 0.0
        for c in (0.0, 0.035, 0.08, 0.12):
            if t >= c:
                lt = t - c
                clatter += math.sin(2 * math.pi * (900 + c * 4000) * lt) * math.exp(-lt * 90.0) * 0.35
        out.append(thud + clatter + (rng.random() * 2 - 1) * math.exp(-t * 30.0) * 0.2)
    return out


if __name__ == "__main__":
    write("perfect_dodge", perfect_dodge())
    write("elevator_call", elevator_call())
    write("enemy_die", enemy_die())
    write("elite_die", elite_die())
    write("wisp_blast", wisp_blast())
    write("jelly_pulse", jelly_pulse())
    write("bell_toll", bell_toll())
    write("page_fan", page_fan())
    write("puppet_slam", puppet_slam())
