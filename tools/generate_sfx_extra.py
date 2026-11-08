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


if __name__ == "__main__":
    write("perfect_dodge", perfect_dodge())
    write("elevator_call", elevator_call())
