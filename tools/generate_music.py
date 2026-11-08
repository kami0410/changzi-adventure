"""Procedural score for Changzi Adventure (1.0). Outputs looping OGG tracks.

An original synthesized score, not a sample library. Version 2 composes in
bars instead of loose events:

- One leitmotif (the 名册 motif: a rising minor third, a fall and a
  question) runs through every track, recoloured per chapter by mode, tempo
  and instrument. The title states it bare, the ending resolves it in major.
- Each track has an A section (motif) and a B section (variation an octave
  up over a moving bass), so a loop no longer repeats every few seconds.
- Every chapter also gets a combat stem (``<track>_combat.ogg``): drums and
  an ostinato on the same tempo and length. AudioManager plays it in sync and
  fades it in while enemies are hunting the player.

Usage: python tools/generate_music.py   (needs numpy, scipy and ffmpeg)
"""
from __future__ import annotations

import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np
from scipy.signal import butter, fftconvolve, lfilter

SR = 44100
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "music"
OUT.mkdir(parents=True, exist_ok=True)

# The 名册 motif in scale degrees (0 = tonic), with durations in beats.
MOTIF = [(0, 1.0), (2, 1.0), (4, 1.5), (3, 0.5), (2, 1.0), (1, 1.0), (4, 2.0)]
MODES = {
    "aeolian": [0, 2, 3, 5, 7, 8, 10],
    "dorian": [0, 2, 3, 5, 7, 9, 10],
    "phrygian": [0, 1, 3, 5, 7, 8, 10],
    "harmonic": [0, 2, 3, 5, 7, 8, 11],
    "major": [0, 2, 4, 5, 7, 9, 11],
}


def hz(midi: float) -> float:
    return 440.0 * 2.0 ** ((midi - 69.0) / 12.0)


def degree(root: int, mode: str, d: int) -> int:
    scale = MODES[mode]
    octave, idx = divmod(d, len(scale))
    return root + scale[idx] + 12 * octave


def lowpass(x, cutoff, order=2):
    b, a = butter(order, min(cutoff / (SR / 2), 0.99), btype="low")
    return lfilter(b, a, x)


def highpass(x, cutoff, order=2):
    b, a = butter(order, min(cutoff / (SR / 2), 0.99), btype="high")
    return lfilter(b, a, x)


def t_axis(seconds):
    return np.arange(int(seconds * SR), dtype=np.float64) / SR


class Score:
    def __init__(self, seconds: float, seed: int, tail: float = 2.5):
        self.seconds = seconds
        self.tail = tail
        self.buf = np.zeros((2, int((seconds + tail) * SR)))
        self.rng = np.random.default_rng(seed)

    def add(self, sig, start, gain=1.0, pan=0.0):
        s = max(int(start * SR), 0)
        e = min(s + len(sig), self.buf.shape[1])
        if e <= s:
            return
        chunk = sig[: e - s] * gain
        self.buf[0, s:e] += chunk * np.sqrt(0.5 * (1.0 - pan))
        self.buf[1, s:e] += chunk * np.sqrt(0.5 * (1.0 + pan))

    # --- instruments -----------------------------------------------------

    def drone(self, freq, gain=0.16, cutoff=480):
        # Continuous voices must close the loop on themselves: whole cycles
        # over the loop length, rendered without a tail (nothing to fold).
        seconds = self.seconds
        freq = max(round(freq * seconds), 1) / seconds
        lfo_hz = max(round(0.05 * seconds), 1) / seconds
        t = t_axis(seconds)
        lfo = 0.8 + 0.2 * np.sin(2 * np.pi * lfo_hz * t)
        saw = 2.0 * ((freq * 2.0 * t) % 1.0) - 1.0
        # Filter the saw over three loops and keep the middle one, so the
        # filter state is periodic too.
        body = lowpass(np.tile(saw, 3), cutoff)[len(saw):2 * len(saw)]
        sig = (np.sin(2 * np.pi * freq * t) + body * 0.3) * lfo
        self.add(sig, 0, gain)

    def pad_chord(self, freqs, start, seconds, gain=0.09, cutoff=1100, detune=0.006):
        t = t_axis(seconds + 1.2)
        env = np.minimum(t / 0.9, 1.0) * np.clip((seconds + 1.2 - t) / 1.2, 0, 1)
        for i, f in enumerate(freqs):
            for off in (-detune, 0.0, detune):
                saw = 2.0 * ((f * (1 + off) * t) % 1.0) - 1.0
                self.add(lowpass(saw, cutoff) * env * 0.25, start, gain, pan=-0.4 + 0.4 * i)

    def bell(self, freq, start, gain=0.12, decay=2.8, pan=None):
        t = t_axis(3.5)
        mod = np.sin(2 * np.pi * freq * 2.76 * t) * 2.0 * np.exp(-t * 1.8)
        sig = np.sin(2 * np.pi * freq * t + mod) * np.exp(-t * decay)
        self.add(sig, start, gain, pan=self.rng.uniform(-0.4, 0.4) if pan is None else pan)

    def musicbox(self, freq, start, gain=0.08, pan=0.0):
        t = t_axis(1.6)
        sig = (np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-t * 9)) * np.exp(-t * 3.2)
        self.add(lowpass(sig, 5200), start, gain, pan)

    def pluck(self, freq, start, gain=0.07, pan=0.0, bright=2600):
        t = t_axis(0.9)
        saw = 2.0 * ((freq * t) % 1.0) - 1.0
        sig = lowpass(saw * np.exp(-t * 6.0), bright)
        self.add(sig, start, gain, pan)

    def strings(self, freq, start, seconds, gain=0.07, pan=0.0):
        t = t_axis(seconds + 0.6)
        env = np.minimum(t / 0.35, 1.0) * np.clip((seconds + 0.6 - t) / 0.6, 0, 1)
        vib = 1.0 + 0.004 * np.sin(2 * np.pi * 5.2 * t)
        phase = np.cumsum(freq * vib) / SR
        saw = 2.0 * (phase % 1.0) - 1.0
        self.add(lowpass(saw, 1800) * env, start, gain, pan)

    def choir(self, freq, start, seconds, gain=0.06):
        t = t_axis(seconds + 1.0)
        env = np.minimum(t / 0.8, 1.0) * np.clip((seconds + 1.0 - t) / 1.0, 0, 1)
        saw = 2.0 * ((freq * t) % 1.0) - 1.0
        # Two formant bands give a hollow "ah".
        sig = lowpass(highpass(saw, 600), 1100) + 0.6 * lowpass(highpass(saw, 1000), 1400)
        self.add(sig * env, start, gain, pan=self.rng.uniform(-0.3, 0.3))

    def bass(self, freq, start, seconds, gain=0.14, drive=2.5):
        t = t_axis(seconds)
        sig = np.tanh(drive * np.sin(2 * np.pi * freq * t)) * np.exp(-t * 2.5)
        self.add(lowpass(sig, 600), start, gain)

    def kick(self, start, gain=0.28):
        t = t_axis(0.45)
        self.add(np.sin(2 * np.pi * (55 - 40 * t) * t) * np.exp(-t * 11), start, gain)

    def snare(self, start, gain=0.09, pan=0.1):
        n = int(0.22 * SR)
        noise = self.rng.normal(0, 1, n) * np.exp(-np.linspace(0, 1, n) * 9)
        body = np.sin(2 * np.pi * 190 * t_axis(0.22)) * np.exp(-t_axis(0.22) * 18)
        self.add(highpass(lowpass(noise, 6000), 900) + body * 0.5, start, gain, pan)

    def taiko(self, start, gain=0.22):
        t = t_axis(0.7)
        self.add(lowpass(np.sin(2 * np.pi * (90 - 35 * t) * t) * np.exp(-t * 6), 900), start, gain)

    def metal(self, freq, start, gain=0.06):
        t = t_axis(0.9)
        sig = (np.sin(2 * np.pi * freq * t) + 0.5 * np.sin(2 * np.pi * freq * 1.73 * t)) * np.exp(-t * 5)
        self.add(lowpass(sig, 3200), start, gain, pan=self.rng.uniform(-0.3, 0.3))

    def wash(self, start, seconds, gain=0.05, cutoff=1200):
        n = int(seconds * SR)
        env = np.sin(np.linspace(0, np.pi, n))
        self.add(highpass(lowpass(self.rng.normal(0, 1, n), cutoff), 200) * env, start, gain,
                 pan=self.rng.uniform(-0.7, 0.7))

    # --- composition helpers ---------------------------------------------

    def motif_line(self, voice, root, mode, start, beat, shift=0, octave=0, gain=1.0, vary=0.0):
        """Plays the leitmotif; [vary] swaps a note for a neighbour now and then."""
        t = start
        for d, beats in MOTIF:
            step = d + shift
            if vary > 0 and self.rng.random() < vary:
                step += int(self.rng.choice([-1, 1]))
            voice(hz(degree(root + 12 * octave, mode, step)), t, beats * beat, gain)
            t += beats * beat
        return t


def render(name, score: Score):
    buf = score.buf
    # Fold note tails back onto the start, then treat the loop as circular for
    # the reverb and the high-pass so its end runs straight into its start.
    loop = int(score.seconds * SR)
    fold = buf.shape[1] - loop
    buf[:, :fold] += buf[:, loop:]
    buf = buf[:, :loop].copy()
    n = int(2.0 * SR)
    ir = score.rng.normal(0, 1, n) * np.exp(-t_axis(2.0) * 3.0)
    ir = highpass(lowpass(ir, 5000), 120)
    ir /= np.sqrt(np.sum(ir * ir)) + 1e-9
    for ch in range(2):
        x = buf[ch]
        wet = fftconvolve(np.tile(x, 2), ir, mode="full")[loop:2 * loop]
        mixed = x * 0.78 + wet * 0.22
        buf[ch] = highpass(np.tile(mixed, 3), 24)[loop:2 * loop]
    buf *= 0.89 / (np.max(np.abs(buf)) + 1e-9)
    pcm = np.clip(buf.T * 32767.0, -32768, 32767).astype(np.int16)
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / f"{name}.wav"
        with wave.open(str(wav), "wb") as h:
            h.setnchannels(2)
            h.setsampwidth(2)
            h.setframerate(SR)
            h.writeframes(pcm.tobytes())
        ogg = OUT / f"{name}.ogg"
        loud = "-20" if name.endswith("_combat") else "-16"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
                        "-af", f"loudnorm=I={loud}:TP=-1.5:LRA=11", "-ar", "44100",
                        "-c:a", "libvorbis", "-q:a", "3", str(ogg)], check=True)
    print(f"{name}.ogg  {ogg.stat().st_size / 1048576:.2f} MiB  {score.seconds:.1f}s")


def chord_freqs(root, mode, d, octave=-12):
    return [hz(degree(root + octave, mode, d + k)) for k in (0, 2, 4)]


def piece(name, root, mode, bpm, bars, progression, seed, build, beats_per_bar=4):
    beat = 60.0 / bpm
    bar = beat * beats_per_bar
    score = Score(bar * bars, seed)
    build(score, root, mode, beat, bar, bars, progression)
    render(name, score)
    return bar * bars


def combat_stem(name, root, mode, bpm, bars, seed, style, beats_per_bar=4):
    beat = 60.0 / bpm
    bar = beat * beats_per_bar
    score = Score(bar * bars, seed, tail=0.8)
    for b in range(bars):
        t0 = b * bar
        for k in range(beats_per_bar):
            t = t0 + k * beat
            if style == "waltz":
                if k == 0:
                    score.taiko(t, 0.26)
                else:
                    score.snare(t, 0.05, pan=(-0.3 if k == 1 else 0.3))
            else:
                if k % 2 == 0:
                    score.kick(t, 0.3)
                if k % 2 == 1:
                    score.snare(t, 0.08)
                score.snare(t + beat * 0.5, 0.025, pan=0.4)
        if style in ("drive", "breath"):
            for k in range(beats_per_bar * 2):
                note = degree(root - 24, mode, [0, 0, 4, 3][(b + k // 4) % 4])
                score.bass(hz(note), t0 + k * beat * 0.5, beat * 0.5, 0.12)
        if style == "deep":
            score.taiko(t0, 0.3)
            score.taiko(t0 + bar * 0.625, 0.2)
            score.bass(hz(degree(root - 24, mode, 0)), t0, bar, 0.14, drive=1.5)
        if style == "waltz":
            score.bass(hz(degree(root - 24, mode, [0, 3, 4, 0][b % 4])), t0, bar, 0.12)
        if b % 4 == 3:
            score.metal(hz(degree(root, mode, 4)), t0 + bar - beat, 0.05)
    render(name, score)


# --- tracks ------------------------------------------------------------------

def build_title(s, root, mode, beat, bar, bars, prog):
    s.drone(hz(root - 24), 0.15)
    for b in range(bars):
        s.pad_chord(chord_freqs(root, mode, prog[b % len(prog)]), b * bar, bar, 0.07)
    s.motif_line(lambda f, t, d, g: s.bell(f, t, 0.12, 2.2), root, mode, bar * 1, beat)
    s.motif_line(lambda f, t, d, g: s.bell(f, t, 0.1, 2.2), root, mode, bar * 5, beat, octave=1, vary=0.25)
    for b in range(0, bars, 2):
        s.wash(b * bar, bar * 1.5, 0.025, 1500)


def build_hub(s, root, mode, beat, bar, bars, prog):
    s.drone(hz(root - 24), 0.1, 380)
    for b in range(bars):
        d = prog[b % len(prog)]
        s.pad_chord(chord_freqs(root, mode, d), b * bar, bar, 0.06, 900)
        for k in range(8):
            arp = degree(root, mode, d + [0, 2, 4, 7, 4, 2, 0, 2][k])
            s.musicbox(hz(arp), b * bar + k * beat * 0.5, 0.045, pan=(-0.3 if k % 2 else 0.3))
    s.motif_line(lambda f, t, d, g: s.strings(f, t, d, 0.05), root, mode, bar * 4, beat, octave=0)
    s.motif_line(lambda f, t, d, g: s.musicbox(f, t, 0.07), root, mode, bar * 10, beat, octave=1, vary=0.3)


def build_archive(s, root, mode, beat, bar, bars, prog):
    s.drone(hz(root - 24), 0.16)
    for b in range(bars):
        d = prog[b % len(prog)]
        s.pad_chord(chord_freqs(root, mode, d), b * bar, bar, 0.07)
        for k in range(4):
            s.pluck(hz(degree(root - 12, mode, d + [0, 4, 2, 4][k])), b * bar + k * beat, 0.05, pan=-0.2)
        if b % 2 == 0:
            s.wash(b * bar, bar * 2, 0.03, 3000)  # ink rain
    for start, octv, vary in ((2, 0, 0.0), (8, 1, 0.3), (12, 0, 0.2)):
        s.motif_line(lambda f, t, d, g: s.bell(f, t, 0.09, 2.6), root, mode, bar * start, beat, octave=octv, vary=vary)
    for b in range(8, bars):
        s.bass(hz(degree(root - 24, mode, prog[b % len(prog)])), b * bar, bar, 0.09, 1.2)


def build_breathing(s, root, mode, beat, bar, bars, prog):
    s.drone(hz(root - 24), 0.15)
    for b in range(bars):
        d = prog[b % len(prog)]
        # The ruins breathe: a slow swell every bar.
        s.pad_chord(chord_freqs(root, mode, d), b * bar, bar, 0.09, 800)
        s.kick(b * bar, 0.14)
        s.kick(b * bar + beat * 1.5, 0.08)
        if b % 2 == 1:
            s.metal(hz(degree(root, mode, 4)), b * bar + beat * 2, 0.05)
        s.wash(b * bar + beat, beat * 2.5, 0.05, 900)
    s.motif_line(lambda f, t, d, g: s.strings(f, t, d, 0.06), root, mode, bar * 2, beat)
    s.motif_line(lambda f, t, d, g: s.choir(f, t, d, 0.05), root, mode, bar * 9, beat, octave=1, vary=0.25)


def build_sea(s, root, mode, beat, bar, bars, prog):
    s.drone(hz(root - 36), 0.22, 300)
    for b in range(bars):
        d = prog[b % len(prog)]
        s.pad_chord(chord_freqs(root, mode, d), b * bar, bar, 0.08, 700, 0.012)
        if b % 2 == 0:
            s.wash(b * bar, bar * 2.2, 0.06, 700)  # swell
        s.kick(b * bar, 0.05)
    for start, octv in ((3, 0), (11, 1)):
        s.motif_line(lambda f, t, d, g: s.bell(f, t, 0.1, 1.5), root, mode, bar * start, beat * 1.5, octave=octv, vary=0.2)
    s.motif_line(lambda f, t, d, g: s.choir(f, t, d, 0.05), root, mode, bar * 7, beat * 1.5, octave=-1)


def build_theater(s, root, mode, beat, bar, bars, prog):
    s.drone(hz(root - 24), 0.15)
    for b in range(bars):
        d = prog[b % len(prog)]
        s.pad_chord(chord_freqs(root, mode, d), b * bar, bar, 0.06, 900, 0.01)
        # A broken waltz: bass on one, music box on two and three.
        s.bass(hz(degree(root - 24, mode, d)), b * bar, beat, 0.1, 1.4)
        for k in (1, 2):
            s.musicbox(hz(degree(root, mode, d + 2 * k)), b * bar + k * beat, 0.05, pan=(-0.4 if k == 1 else 0.4))
        if b % 4 == 3:
            s.metal(hz(degree(root, mode, 5)), b * bar + beat * 2.5, 0.04)
    for start, octv, voice in ((2, 1, "box"), (10, 0, "str"), (14, 1, "box")):
        fn = (lambda f, t, d, g: s.musicbox(f, t, 0.07)) if voice == "box" else (lambda f, t, d, g: s.strings(f, t, d, 0.05))
        s.motif_line(fn, root, mode, bar * start, beat, octave=octv, vary=0.3)


def build_boss(s, root, mode, beat, bar, bars, prog):
    s.drone(hz(root - 36), 0.14)
    for b in range(bars):
        d = prog[b % len(prog)]
        s.pad_chord(chord_freqs(root, mode, d), b * bar, bar, 0.06, 700)
        for k in range(8):
            s.bass(hz(degree(root - 24, mode, d + (1 if k in (3, 7) else 0))), b * bar + k * beat * 0.5, beat * 0.5, 0.13, 3.0)
        for k in range(4):
            s.kick(b * bar + k * beat, 0.24)
            if k % 2:
                s.snare(b * bar + k * beat, 0.09)
    s.motif_line(lambda f, t, d, g: s.strings(f, t, d, 0.07), root, mode, bar * 2, beat * 0.5, octave=0)
    s.motif_line(lambda f, t, d, g: s.choir(f, t, d, 0.06), root, mode, bar * 6, beat, octave=1, vary=0.2)
    s.motif_line(lambda f, t, d, g: s.bell(f, t, 0.08, 2.0), root, mode, bar * 10, beat * 0.5, octave=1)


def build_ending(s, root, mode, beat, bar, bars, prog):
    s.drone(hz(root - 24), 0.1, 400)
    for b in range(bars):
        s.pad_chord(chord_freqs(root, mode, prog[b % len(prog)]), b * bar, bar, 0.08, 1300)
    s.motif_line(lambda f, t, d, g: s.strings(f, t, d, 0.06), root, mode, bar * 1, beat)
    s.motif_line(lambda f, t, d, g: s.bell(f, t, 0.1, 2.0), root, mode, bar * 5, beat, octave=1)
    s.motif_line(lambda f, t, d, g: s.choir(f, t, d, 0.05), root, mode, bar * 9, beat * 1.5, octave=0)


if __name__ == "__main__":
    piece("title", 57, "aeolian", 66, 12, [0, 5, 3, 4], 1, build_title)
    piece("hub", 62, "dorian", 76, 16, [0, 3, 5, 4], 2, build_hub)
    seconds = {}
    seconds["archive"] = piece("chapter_archive", 62, "aeolian", 84, 16, [0, 5, 3, 4, 0, 5, 6, 4], 3, build_archive)
    seconds["breathing"] = piece("chapter_breathing", 64, "phrygian", 72, 16, [0, 1, 0, 6], 4, build_breathing)
    seconds["sea"] = piece("chapter_sea", 60, "dorian", 60, 16, [0, 6, 5, 4], 5, build_sea)
    seconds["theater"] = piece("chapter_theater", 60, "harmonic", 96, 24, [0, 3, 4, 0, 5, 3, 4, 4], 6, build_theater, beats_per_bar=3)
    piece("boss", 62, "phrygian", 140, 16, [0, 1, 0, 6], 7, build_boss)
    piece("ending", 62, "major", 70, 12, [0, 5, 3, 4], 8, build_ending)
    combat_stem("chapter_archive_combat", 62, "aeolian", 84, 16, 13, "drive")
    combat_stem("chapter_breathing_combat", 64, "phrygian", 72, 16, 14, "breath")
    combat_stem("chapter_sea_combat", 60, "dorian", 60, 16, 15, "deep")
    combat_stem("chapter_theater_combat", 60, "harmonic", 96, 24, 16, "waltz", beats_per_bar=3)
