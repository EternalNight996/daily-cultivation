
import wave, os
import numpy as np
base = r"F:\MyApp\eternal\DailyCultivation\ios\DailyCultivation\Resources\Audio"
for name in ["tick.wav","complete.wav","settle.wav"]:
    with wave.open(os.path.join(base,name)) as f:
        n = f.getnframes(); sr = f.getframerate(); ch = f.getnchannels()
        x = np.frombuffer(f.readframes(n), dtype=np.int16).astype(np.float64)/32768
    rms = np.sqrt(np.mean(x**2))
    spec = np.abs(np.fft.rfft(x))
    freqs = np.fft.rfftfreq(len(x), 1/sr)
    centroid = float((spec*freqs).sum()/max(spec.sum(),1e-9))
    top = freqs[np.argsort(spec)[-3:]]
    print(f"{name}: {n/sr:.2f}s {sr}Hz ch={ch} peak={20*np.log10(np.max(np.abs(x))+1e-9):.1f}dB "
          f"rms={20*np.log10(rms+1e-9):.1f}dB centroid={centroid:.0f}Hz top={sorted([int(t) for t in top])}")
