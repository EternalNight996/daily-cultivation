
# -*- coding: utf-8 -*-
"""生成三段占位音效：木鱼、符成钟、结算罄。

目标是"像",不是"真"：全部用简单的衰减正弦 + 噪声脉冲合成，
素材到位后同名替换即可。输出 44.1kHz / 16bit / 单声道。
"""
import os
import numpy as np
import wave

SR = 44100
OUT = r"F:\MyApp\eternal\DailyCultivation\ios\DailyCultivation\Resources\Audio"
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def env_ad(n, attack, decay, sr=SR):
    t = np.arange(n) / sr
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    d = np.exp(-t / max(decay, 1e-4))
    return a * d


def tone(freq, dur, amp, decay, attack=0.004, detune=0.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    sig = np.sin(2 * np.pi * (freq + detune) * t)
    return amp * sig * env_ad(n, attack, decay)


def noise_burst(dur, amp, decay, lowpass=0.25):
    n = int(SR * dur)
    x = rng.normal(0, 1, n)
    # 一阶低通，压掉刺耳的高频
    y = np.zeros(n)
    acc = 0.0
    for i in range(n):
        acc += lowpass * (x[i] - acc)
        y[i] = acc
    return amp * y * env_ad(n, 0.001, decay)


def fade(x, ms=6):
    k = int(SR * ms / 1000)
    if len(x) <= 2 * k:
        return x
    w = np.linspace(0, 1, k)
    x[:k] *= w
    x[-k:] *= w[::-1]
    return x


def save(name, x, peak_db=-6.0):
    x = fade(np.asarray(x, dtype=np.float64))
    x -= np.mean(x)
    peak = np.max(np.abs(x)) or 1.0
    target = 10 ** (peak_db / 20.0)
    x = x * (target / peak)
    data = np.clip(x, -1.0, 1.0)
    pcm = (data * 32767).astype(np.int16)
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    print(f"{name}: {len(x)/SR:.2f}s  peak {peak_db}dB  {os.path.getsize(path)//1024}KB")


# 1) 落笔／判过一笔：木鱼"笃"一声
def make_tick():
    parts = []
    for freq, amp, decay in [(320, 0.9, 0.030), (540, 0.5, 0.022), (810, 0.25, 0.015)]:
        parts.append(tone(freq, 0.16, amp, decay, attack=0.001))
    body = np.sum(parts, axis=0)
    click = noise_burst(0.03, 0.18, 0.004, lowpass=0.35)
    out = np.zeros(len(body))
    out[:len(body)] += body
    out[:len(click)] += click
    return out


# 2) 符成：一口清钟，带起音的气声
def make_complete():
    parts = []
    for freq, amp, decay in [(523.25, 1.0, 0.85), (784.0, 0.45, 0.65),
                             (1046.5, 0.30, 0.50), (1568.0, 0.18, 0.35)]:
        parts.append(tone(freq, 1.8, amp, decay, attack=0.006))
    body = np.sum(parts, axis=0)
    chiff = noise_burst(0.12, 0.18, 0.05, lowpass=0.12)
    out = body.copy()
    out[:len(chiff)] += chiff
    return out


# 3) 结算：低一点的罄，余音长
def make_settle():
    parts = []
    for freq, amp, decay in [(196.0, 1.0, 1.3), (392.0, 0.4, 1.0),
                             (548.0, 0.22, 0.8), (1096.0, 0.10, 0.5)]:
        parts.append(tone(freq, 2.4, amp, decay, attack=0.008, detune=0.4))
    body = np.sum(parts, axis=0)
    wash = noise_burst(0.5, 0.10, 0.25, lowpass=0.08)
    out = body.copy()
    out[:len(wash)] += wash
    return out


save("tick.wav", make_tick(), peak_db=-9.0)
save("complete.wav", make_complete(), peak_db=-4.5)
save("settle.wav", make_settle(), peak_db=-6.0)
print("done ->", OUT)
