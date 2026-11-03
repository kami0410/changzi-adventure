"""Procedural score for Changzi Adventure. Outputs looping OGG tracks.

This is an original synthesized score, not a sample library. Every track is
built from a small motif and a drone so the three chapters share a musical
world while changing color.
"""
from pathlib import Path
import subprocess
import numpy as np
from scipy.signal import butter, lfilter, fftconvolve

SR = 44100
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "music"
OUT.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(20261101)


def t_axis(duration):
    return np.arange(int(duration * SR), dtype=np.float64) / SR


def env(n, attack=0.02, decay=0.3, sustain=0.6, release=1.2):
    a = max(int(attack * SR), 1)
    d = max(int(decay * SR), 1)
    r = max(int(release * SR), 1)
    s = max(n - a - d - r, 1)
    return np.concatenate([
        np.linspace(0, 1, a),
        np.linspace(1, sustain, d),
        np.full(s, sustain),
        np.linspace(sustain, 0, r),
    ])[:n]


def lowpass(signal, cutoff, order=2):
    b, a = butter(order, min(cutoff / (SR / 2), 0.99), btype="low")
    return lfilter(b, a, signal)


def highpass(signal, cutoff, order=2):
    b, a = butter(order, min(cutoff / (SR / 2), 0.99), btype="high")
    return lfilter(b, a, signal)


def sine(freq, duration, phase=0.0):
    return np.sin(2 * np.pi * freq * t_axis(duration) + phase)


def saw(freq, duration):
    phase = (freq * t_axis(duration)) % 1.0
    return 2.0 * phase - 1.0


def add(buffer, signal, start, gain=1.0, pan=0.0):
    if signal is None or len(signal) == 0:
        return
    start_i = max(int(start * SR), 0)
    end_i = min(start_i + len(signal), buffer.shape[1])
    if end_i <= start_i:
        return
    chunk = signal[: end_i - start_i] * gain
    left = np.sqrt(0.5 * (1.0 - pan))
    right = np.sqrt(0.5 * (1.0 + pan))
    buffer[0, start_i:end_i] += chunk * left
    buffer[1, start_i:end_i] += chunk * right


def drone(buffer, freq, duration, gain=0.2):
    n = int(duration * SR)
    t = np.arange(n) / SR
    lfo = 0.82 + 0.18 * np.sin(2 * np.pi * 0.055 * t)
    fundamental = np.sin(2 * np.pi * freq * t)
    body = lowpass(saw(freq * 2.0, duration), 520) * 0.35
    add(buffer, (fundamental + body) * lfo, 0, gain)


def pad(buffer, freqs, duration, gain=0.12, detune=0.006):
    n = int(duration * SR)
    t = np.arange(n) / SR
    swell = 0.55 + 0.45 * np.sin(2 * np.pi * 0.07 * t - 1.2)
    for i, freq in enumerate(freqs):
        for offset in (-detune, 0.0, detune):
            voice = lowpass(saw(freq * (1.0 + offset), duration), 900) * 0.22
            voice *= 0.7 + 0.3 * np.sin(2 * np.pi * (0.09 + i * 0.013) * t + i)
            add(buffer, voice * swell, 0, gain, pan=(-0.35 + i * 0.28))


def bell(buffer, freq, start, gain=0.18, decay=3.2, duration=3.0):
    t = np.arange(int(duration * SR)) / SR
    modulator = np.sin(2 * np.pi * freq * 2.76 * t) * 2.2 * np.exp(-t * 1.6)
    tone = np.sin(2 * np.pi * freq * t + modulator)
    tone *= np.exp(-t * decay)
    add(buffer, tone, start, gain, pan=RNG.uniform(-0.45, 0.45))


def thump(buffer, start, gain=0.3):
    t = np.arange(int(0.45 * SR)) / SR
    tone = np.sin(2 * np.pi * (52 - t * 40) * t) * np.exp(-t * 12)
    add(buffer, tone, start, gain)


def noise_burst(buffer, start, duration=0.25, gain=0.08, cutoff=2800, pan=0.0):
    n = int(duration * SR)
    noise = RNG.normal(0, 1, n) * np.exp(-np.linspace(0, 1, n) * 7)
    add(buffer, highpass(lowpass(noise, cutoff), 300), start, gain, pan=pan)


def metal_hit(buffer, start, freq=310, gain=0.1):
    t = np.arange(int(0.8 * SR)) / SR
    tone = (np.sin(2 * np.pi * freq * t) + 0.5 * np.sin(2 * np.pi * freq * 1.73 * t))
    tone *= np.exp(-t * 5.5)
    add(buffer, lowpass(tone, 3200), start, gain, pan=RNG.uniform(-0.2, 0.2))


def reverb(signal, mix=0.24, decay=2.0):
    n = int(decay * SR)
    t = np.arange(n) / SR
    ir = RNG.normal(0, 1, n) * np.exp(-t * 3.2)
    ir = highpass(lowpass(ir, 5200), 120)
    ir /= np.sqrt(np.sum(ir * ir)) + 1e-9
    wet = fftconvolve(signal, ir, mode="full")[: len(signal)]
    return signal * (1.0 - mix) + wet * mix


def write_track(name, duration, builder, tail=2.2):
    buffer = np.zeros((2, int((duration + tail) * SR)), dtype=np.float64)
    builder(buffer, duration)
    for channel in range(2):
        buffer[channel] = reverb(buffer[channel], 0.22, 1.8)
        buffer[channel] = highpass(buffer[channel], 24)
    fold = int(tail * SR)
    buffer[:, :fold] += buffer[:, int(duration * SR): int(duration * SR) + fold]
    buffer = buffer[:, : int(duration * SR)]
    peak = np.max(np.abs(buffer)) + 1e-9
    buffer *= 0.89 / peak
    pcm = np.clip(buffer.T * 32767.0, -32768, 32767).astype(np.int16)
    wav = Path("/tmp") / f"changzi_{name}.wav"
    import wave
    with wave.open(str(wav), "wb") as handle:
        handle.setnchannels(2)
        handle.setsampwidth(2)
        handle.setframerate(SR)
        handle.writeframes(pcm.tobytes())
    ogg = OUT / f"{name}.ogg"
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
        "-af", "loudnorm=I=-16:TP=-1.5:LRA=11",
        "-ar", "44100", "-c:a", "libvorbis", "-q:a", "4", str(ogg),
    ], check=True)
    wav.unlink(missing_ok=True)
    print(f"{name}.ogg  {ogg.stat().st_size / 1048576:.2f} MiB  {duration:.0f}s")


def title(buffer, duration):
    drone(buffer, 55.0, duration, 0.18)
    pad(buffer, [220.0, 261.63, 329.63], duration, 0.12)
    motif = [440.0, 523.25, 659.25, 783.99, 659.25, 523.25]
    for i, freq in enumerate(motif):
        bell(buffer, freq, i * 2.4, 0.12, 2.4, 4.0)
    for i in range(0, int(duration / 4), 1):
        noise_burst(buffer, i * 4.0, 0.7, 0.025, 1600, RNG.uniform(-0.6, 0.6))


def archive(buffer, duration):
    drone(buffer, 73.42, duration, 0.2)
    pad(buffer, [146.83, 174.61, 220.0], duration, 0.12)
    for i in range(0, int(duration / 3), 1):
        bell(buffer, [587.33, 698.46, 880.0][i % 3], i * 3.0 + 0.4, 0.08, 3.6, 4.0)
    for i in range(0, int(duration / 2), 1):
        noise_burst(buffer, i * 2.0 + RNG.uniform(0, 0.8), 0.12, 0.045, 3800, RNG.uniform(-0.7, 0.7))
    for i in range(0, int(duration / 8), 1):
        thump(buffer, i * 8.0, 0.12)


def breathing(buffer, duration):
    drone(buffer, 82.41, duration, 0.18)
    pad(buffer, [164.81, 196.0, 246.94], duration, 0.13)
    for i in range(int(duration / 1.2)):
        thump(buffer, i * 1.2, 0.16)
    for i in range(int(duration / 4)):
        noise_burst(buffer, i * 4.0, 1.8, 0.07, 1400, RNG.uniform(-0.5, 0.5))
        if i % 2 == 0:
            metal_hit(buffer, i * 4.0 + 1.0, 196.0, 0.07)
    for i in range(int(duration / 6)):
        bell(buffer, 392.0, i * 6.0 + 2.0, 0.07, 2.3, 4.0)


def sea(buffer, duration):
    drone(buffer, 32.7, duration, 0.24)
    pad(buffer, [130.81, 155.56, 196.0], duration, 0.14, 0.012)
    for i in range(int(duration / 8)):
        bell(buffer, [523.25, 466.16, 392.0][i % 3], i * 8.0 + 1.0, 0.1, 1.7, 6.0)
    for i in range(int(duration / 5)):
        noise_burst(buffer, i * 5.0, 2.8, 0.06, 900, RNG.uniform(-0.8, 0.8))
    for i in range(int(duration / 2)):
        thump(buffer, i * 2.0, 0.05)


def boss(buffer, duration):
    drone(buffer, 36.71, duration, 0.16)
    pad(buffer, [73.42, 77.78, 110.0], duration, 0.1)
    step = 60.0 / 140.0 / 2.0
    for i in range(int(duration / step)):
        note = 73.42 if i % 8 not in (3, 7) else 77.78
        t = np.arange(int(step * SR)) / SR
        bass = np.tanh(3.0 * np.sin(2 * np.pi * note * t)) * np.exp(-t * 8)
        add(buffer, lowpass(bass, 700), i * step, 0.16)
    for i in range(int(duration / (60.0 / 140.0))):
        thump(buffer, i * 60.0 / 140.0, 0.22)
        if i % 4 == 2:
            noise_burst(buffer, i * 60.0 / 140.0, 0.18, 0.11, 6000, 0.2)
    for i in range(int(duration / 4)):
        bell(buffer, 293.66, i * 4.0, 0.06, 2.0, 3.0)
        bell(buffer, 311.13, i * 4.0 + 0.5, 0.05, 2.2, 3.0)


def theater(buffer, duration):
    drone(buffer, 65.41, duration, 0.2)
    pad(buffer, [130.81, 155.56, 196.0], duration, 0.13, 0.01)
    # A slow, broken waltz: three beats per bar, music-box plucks.
    beat = 60.0 / 88.0
    for i in range(int(duration / beat)):
        note = [261.63, 311.13, 392.0, 466.16, 392.0, 311.13][i % 6]
        t = np.arange(int(0.55 * SR)) / SR
        pluck = np.sin(2 * np.pi * note * t) * np.exp(-t * 7.0)
        add(buffer, lowpass(pluck, 2400), i * beat, 0.055, pan=(-0.4 if i % 2 == 0 else 0.4))
        if i % 3 == 0:
            thump(buffer, i * beat, 0.12)
    for i in range(int(duration / 12)):
        noise_burst(buffer, i * 12.0 + 2.0, 3.0, 0.06, 1100, RNG.uniform(-0.8, 0.8))
        bell(buffer, 523.25, i * 12.0 + 4.0, 0.08, 1.4, 6.0)
    for i in range(int(duration / 4)):
        metal_hit(buffer, i * 4.0 + 1.0, 196.0, 0.04)


write_track("title", 24.0, title)
write_track("chapter_archive", 32.0, archive)
write_track("chapter_breathing", 32.0, breathing)
write_track("chapter_sea", 40.0, sea)
write_track("boss", 24.0, boss)
write_track("chapter_theater", 36.0, theater)
