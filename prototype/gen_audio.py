
import math, struct, wave, os

SR = 44100
OUT = r"F:\MyApp\eternal\DailyCultivation\ios\DailyCultivation\Resources\Audio"
os.makedirs(OUT, exist_ok=True)

def write(name, samples):
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        w.writeframes(frames)
    print(name, len(samples), "samples")

def env(i, n, attack=0.004, decay=6.0):
    t = i / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    return a * math.exp(-decay * t)

def tick():
    n = int(0.075 * SR)
    out = []
    for i in range(n):
        t = i / SR
        s = math.sin(2*math.pi*1760*t) * 0.35 + math.sin(2*math.pi*3520*t) * 0.12
        s *= math.exp(-55*t)
        out.append(s * 0.5)
    return out

def complete():
    n = int(1.0 * SR)
    out = []
    partials = [(440, 1.0), (660, 0.55), (880, 0.35), (1320, 0.18)]
    for i in range(n):
        t = i / SR
        s = 0.0
        for f, amp in partials:
            s += math.sin(2*math.pi*f*t + 0.3*math.sin(2*math.pi*5*t)) * amp
        s *= env(i, n, 0.006, 4.2)
        out.append(s * 0.22)
    return out

def settle():
    n = int(1.5 * SR)
    out = []
    partials = [(220, 1.0), (330, 0.5), (554, 0.28), (880, 0.12)]
    for i in range(n):
        t = i / SR
        s = 0.0
        for f, amp in partials:
            s += math.sin(2*math.pi*f*t) * amp
        s *= env(i, n, 0.01, 2.4)
        # 一点点尾音
        s += 0.18 * math.sin(2*math.pi*110*t) * math.exp(-1.6*t)
        out.append(s * 0.20)
    return out

write("tick.wav", tick())
write("complete.wav", complete())
write("settle.wav", settle())
