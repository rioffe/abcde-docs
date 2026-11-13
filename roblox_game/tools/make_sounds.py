#!/usr/bin/env python3
"""Render the web game's sound effects to WAV files for Roblox.

The web version (game/index.html) builds every sound from short Web Audio
tones: tone(freq, duration, wave, volume, delay, slide). This script plays
the same recipes into 16-bit mono WAV files in assets/sounds/, ready to
upload to Roblox (Studio: View > Asset Manager > Bulk Import, or the
Creator Hub). Paste the resulting asset ids into Sfx.IDS in
src/client/Sfx.luau.

No dependencies beyond the Python standard library:
    python3 tools/make_sounds.py
"""

import math
import os
import struct
import wave

RATE = 44100
PEAK = 0.8  # every effect is normalised to this peak...
TALK_PEAK = 0.45  # ...except the talk blip, which repeats while Spike speaks

# Each effect is a list of tones: (freq Hz, duration s, wave, volume, delay s, slide or None).
# Copied from SFX in game/index.html. "talk" is one blip at the middle of its
# random pitch range; Roblox varies its playback speed instead.
EFFECTS = {
    "talk": [(580, 0.05, "triangle", 0.05, 0, None)],
    "open": [(523, 0.08, "triangle", 0.09, 0, None), (784, 0.1, "triangle", 0.09, 0.06, None)],
    "right": [(f, 0.15, "triangle", 0.11, i * 0.07, None) for i, f in enumerate([523, 659, 784, 1046])],
    "near": [(523, 0.1, "triangle", 0.09, 0, None), (659, 0.15, "triangle", 0.09, 0.08, None)],
    "close": [(523, 0.1, "triangle", 0.09, 0, None), (659, 0.15, "triangle", 0.09, 0.08, None)],
    "miss": [(330, 0.15, "triangle", 0.08, 0, 0.8), (262, 0.2, "triangle", 0.07, 0.12, 0.8)],
    "wrong": [(220, 0.18, "sawtooth", 0.05, 0, 0.7), (180, 0.24, "sawtooth", 0.045, 0.13, 0.7)],
    "add": [
        (660, 0.08, "square", 0.05, 0, None),
        (990, 0.12, "square", 0.05, 0.07, None),
        (1320, 0.14, "square", 0.04, 0.14, None),
    ],
    "hint": [
        (1046, 0.1, "sine", 0.07, 0, None),
        (1318, 0.12, "sine", 0.07, 0.08, None),
        (1568, 0.16, "sine", 0.07, 0.16, None),
    ],
    "fanfare": [
        tone
        for i, f in enumerate([523, 659, 784, 1046, 784, 1046, 1318])
        for tone in ((f, 0.22, "triangle", 0.12, i * 0.12, None), (f / 2, 0.22, "sine", 0.07, i * 0.12, None))
    ],
}


def oscillator(wave_type, phase):
    """One sample of a waveform at `phase` (in cycles)."""
    p = phase % 1.0
    if wave_type == "sine":
        return math.sin(2 * math.pi * p)
    if wave_type == "triangle":
        return 4 * abs(p - 0.5) - 1
    if wave_type == "square":
        return 1.0 if p < 0.5 else -1.0
    if wave_type == "sawtooth":
        return 2 * p - 1
    raise ValueError(wave_type)


def exp_ramp(start, end, t, length):
    """Web Audio exponentialRampToValueAtTime between two points."""
    if length <= 0:
        return end
    return start * (end / start) ** min(1.0, max(0.0, t / length))


def render(tones):
    end = max(delay + dur + 0.03 for _, dur, _, _, delay, _ in tones)
    out = [0.0] * int(end * RATE + 1)
    for freq, dur, wave_type, vol, delay, slide in tones:
        start = int(delay * RATE)
        stop = int((delay + dur + 0.03) * RATE)
        target = max(40, freq * slide) if slide else freq
        phase = 0.0
        for i in range(start, min(stop, len(out))):
            t = (i - start) / RATE
            f = exp_ramp(freq, target, t, dur) if slide else freq
            phase += f / RATE
            # gain: 0.0001 -> vol over 12 ms, then -> 0.0001 at the end of the note
            if t < 0.012:
                g = exp_ramp(0.0001, vol, t, 0.012)
            else:
                g = exp_ramp(vol, 0.0001, t - 0.012, dur - 0.012)
            out[i] += oscillator(wave_type, phase) * g
    return out


def write_wav(path, samples, peak):
    loudest = max(abs(s) for s in samples) or 1.0
    gain = peak / loudest
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767)) for s in samples
        )
        w.writeframes(frames)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    folder = os.path.join(root, "assets", "sounds")
    os.makedirs(folder, exist_ok=True)
    for name, tones in EFFECTS.items():
        samples = render(tones)
        path = os.path.join(folder, f"nutri_{name}.wav")
        peak = TALK_PEAK if name == "talk" else PEAK
        write_wav(path, samples, peak)
        print(f"{os.path.relpath(path, root):34} {len(samples) / RATE:5.2f} s  peak {peak:.2f}")


if __name__ == "__main__":
    main()
