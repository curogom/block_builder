#!/usr/bin/env python3
"""
Generate simple placeholder SFX as WAV files using procedural synthesis.
Outputs:
  assets/audio/drop.wav
  assets/audio/land.wav
  assets/audio/trim.wav
  assets/audio/warn.wav
  assets/audio/gameover.wav

These are clean, short, non-intrusive cues suitable for iteration until
final assets replace them. Requires only Python 3 + numpy.
"""
import os
import math
import wave
import random
from typing import List

SR = 44100

def ensure_dir(path: str):
    os.makedirs(path, exist_ok=True)

def write_wav(path: str, data: List[float]):
    # Clamp and convert to 16-bit PCM
    frames = bytearray()
    for x in data:
        if x > 1.0:
            x = 1.0
        elif x < -1.0:
            x = -1.0
        i = int(x * 32767.0)
        frames += i.to_bytes(2, byteorder='little', signed=True)
    with wave.open(path, 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(frames)

def env_ahdsr(n: int, a=0.005, h=0.0, d=0.05, s=0.2, r=0.05) -> List[float]:
    # Very simple AHDSR (times in seconds)
    aN = int(a * SR)
    hN = int(h * SR)
    dN = int(d * SR)
    rN = int(r * SR)
    sN = max(0, n - (aN + hN + dN + rN))
    def linspace(start, end, count, endpoint=False):
        if count <= 1:
            return [end] if endpoint else [start]
        step = (end - start) / (count if endpoint else count)
        arr = [start + i * ((end - start) / (count)) for i in range(count)]
        if endpoint:
            arr[-1] = end
        return arr
    atk = linspace(0.0, 1.0, max(1, aN), endpoint=False)
    hold = [1.0] * max(0, hN)
    dec = linspace(1.0, s, max(1, dN), endpoint=False)
    sus = [s] * max(0, sN)
    rel = linspace(s, 0.0, max(1, rN), endpoint=True)
    env = atk + hold + dec + sus + rel
    if len(env) < n:
        env += [0.0] * (n - len(env))
    else:
        env = env[:n]
    return env

def pink_noise(n: int) -> List[float]:
    # Simple filtered white noise approximation (low-pass)
    # White noise
    white = [random.gauss(0, 1) for _ in range(n)]
    # One-pole low-pass filter
    out = [0.0] * n
    alpha = 0.06
    for i in range(1, n):
        out[i] = out[i-1] + alpha * (white[i] - out[i-1])
    # Normalize
    mx = max(1e-6, max(abs(x) for x in out))
    out = [x / mx for x in out]
    return out

def sine(freq: float, n: int) -> List[float]:
    out = []
    for i in range(n):
        t = i / SR
        out.append(math.sin(2 * math.pi * freq * t))
    return out

def chirp(f0: float, f1: float, n: int) -> List[float]:
    out = []
    T = n / SR
    k = (f1 - f0) / T
    for i in range(n):
        t = i / SR
        phase = 2 * math.pi * (f0 * t + 0.5 * k * t * t)
        out.append(math.sin(phase))
    return out

def make_drop() -> List[float]:
    # Soft short whoosh: filtered noise + quick fade
    dur = 0.25
    n = int(SR * dur)
    noise = pink_noise(n)
    # Highpass-ish: subtract a slower moving average
    kernel = [1/200.0] * 200
    slow = [0.0] * n
    # simple convolution 'same'
    for i in range(n):
        acc = 0.0
        for k in range(len(kernel)):
            j = i - len(kernel)//2 + k
            if 0 <= j < n:
                acc += noise[j] * kernel[k]
        slow[i] = acc
    whoosh = [noise[i] - 0.6 * slow[i] for i in range(n)]
    env = env_ahdsr(n, a=0.01, d=0.03, s=0.2, r=0.08)
    out = [0.25 * whoosh[i] * env[i] for i in range(n)]
    return out

def make_land() -> List[float]:
    # Muted thump: low sine with fast decay + tiny noise transient
    dur = 0.2
    n = int(SR * dur)
    base_wave = sine(120, n)
    base_env = env_ahdsr(n, a=0.002, d=0.06, s=0.0, r=0.06)
    base = [base_wave[i] * base_env[i] for i in range(n)]
    click = [random.gauss(0,1) for _ in range(n)]
    click_env = env_ahdsr(n, a=0.0, d=0.015, s=0.0, r=0.03)
    out = [0.4 * base[i] + 0.05 * click[i] * click_env[i] for i in range(n)]
    return out

def make_trim() -> List[float]:
    # Slicing snap: short bright noise burst + high-mid ping
    dur = 0.2
    n = int(SR * dur)
    burst = [random.gauss(0,1) for _ in range(n)]
    # Brighten burst via high-pass (subtract moving average)
    kernel = [1/40.0] * 40
    avg = [0.0] * n
    for i in range(n):
        acc = 0.0
        for k in range(len(kernel)):
            j = i - len(kernel)//2 + k
            if 0 <= j < n:
                acc += burst[j] * kernel[k]
        avg[i] = acc
    hp = [burst[i] - avg[i] for i in range(n)]
    ping_wave = sine(2100, n)
    ping_env = env_ahdsr(n, a=0.001, d=0.03, s=0.0, r=0.05)
    ping = [ping_wave[i] * ping_env[i] for i in range(n)]
    burst_env = env_ahdsr(n, a=0.0, d=0.02, s=0.0, r=0.06)
    out = [0.22 * hp[i] * burst_env[i] + 0.12 * ping[i] for i in range(n)]
    return out

def make_warn() -> List[float]:
    # Two short beeps low->high
    beep_dur = 0.14
    gap = 0.04
    n_beep = int(SR * beep_dur)
    n_gap = int(SR * gap)
    b1_wave = sine(740, n_beep)
    b1_env = env_ahdsr(n_beep, a=0.001, d=0.05, s=0.0, r=0.06)
    b1 = [0.25 * b1_wave[i] * b1_env[i] for i in range(n_beep)]
    b2_wave = sine(1040, n_beep)
    b2_env = env_ahdsr(n_beep, a=0.001, d=0.05, s=0.0, r=0.06)
    b2 = [0.25 * b2_wave[i] * b2_env[i] for i in range(n_beep)]
    out = b1 + [0.0]*n_gap + b2
    return out

def make_gameover() -> List[float]:
    # Descending tone sweep, calm
    dur = 1.0
    n = int(SR * dur)
    sweep = chirp(800, 220, n)
    env = env_ahdsr(n, a=0.01, d=0.15, s=0.4, r=0.25)
    out = [0.2 * sweep[i] * env[i] for i in range(n)]
    return out

def main():
    out_dir = os.path.join('assets', 'audio')
    ensure_dir(out_dir)

    sounds = {
        'drop.wav': make_drop(),
        'land.wav': make_land(),
        'trim.wav': make_trim(),
        'warn.wav': make_warn(),
        'gameover.wav': make_gameover(),
    }

    for name, data in sounds.items():
        path = os.path.join(out_dir, name)
        write_wav(path, data)
        print(f"Wrote {path}")

if __name__ == '__main__':
    main()
