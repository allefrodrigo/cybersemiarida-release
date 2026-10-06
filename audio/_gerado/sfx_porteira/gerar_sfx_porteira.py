"""Som da porteira do fim de fase (scenes/goal.tscn). Gera audio/sfx_porteira.ogg.

Uso, da raiz do projeto: python3 audio/_gerado/sfx_porteira/gerar_sfx_porteira.py  (precisa do ffmpeg no PATH)

0,00 s tramela (estalo de madeira) · 0,04 s bip duplo da lâmpada ficando verde · 0,12-0,56 s rangido da dobradiça
· 0,58 s baque da folha no batente, com o quique. Volume médio perto do bell-goal.ogg, que ele substitui.
Sem dependências além da biblioteca padrão; a semente fixa deixa o arquivo reprodutível.
"""
import math
import random
import subprocess
import tempfile
import wave
from pathlib import Path

RATE = 44100
LENGTH = 0.95
TARGET_PEAK = 10 ** (-1.0 / 20)        # -1 dBFS
DRIVE = 3.0                            # compressão: aproxima o volume médio do bell-goal.ogg

rng = random.Random(7)
buf = [0.0] * int(RATE * LENGTH)


def add(t0, samples):
    i0 = int(t0 * RATE)
    for i, v in enumerate(samples):
        if 0 <= i0 + i < len(buf):
            buf[i0 + i] += v


def resonator(signal, freq, q):
    """Filtro passa-banda de dois polos (ressonância de madeira/metal)."""
    w = 2 * math.pi * freq / RATE
    r = 1 - w / (2 * q)
    a1, a2 = 2 * r * math.cos(w), -r * r
    y1 = y2 = 0.0
    out = []
    for x in signal:
        y = x * (1 - r) + a1 * y1 + a2 * y2
        out.append(y)
        y2, y1 = y1, y
    return out


def env(n, attack, decay):
    a = max(1, int(attack * RATE))
    return [(i / a) if i < a else math.exp(-(i - a) / (decay * RATE)) for i in range(n)]


def knock(gain, f1, f2, decay):
    """Estalo curto: ruído excitando duas ressonâncias."""
    n = int(0.12 * RATE)
    e = env(n, 0.001, decay)
    noise = [rng.uniform(-1, 1) * e[i] for i in range(n)]
    a = resonator(noise, f1, 9)
    b = resonator(noise, f2, 14)
    return [gain * (a[i] * 6 + b[i] * 4 + noise[i] * 0.25) for i in range(n)]


def beep(freq, dur, gain):
    """Bip eletrônico suave (quadrada arredondada) da lâmpada."""
    n = int(dur * RATE)
    e = env(n, 0.004, dur / 3)
    return [gain * e[i] * math.tanh(3 * math.sin(2 * math.pi * freq * i / RATE)) for i in range(n)]


def creak(dur, gain):
    """Rangido: trem de pulsos de atrito com frequência que sobe e desce, filtrado como madeira."""
    n = int(dur * RATE)
    pulses = [0.0] * n
    t = 0.0
    while t < dur:
        x = t / dur
        rate = 95 + 170 * math.sin(math.pi * x) ** 1.5 + rng.uniform(-18, 18)
        i = int(t * RATE)
        if i < n:
            pulses[i] = rng.uniform(0.7, 1.0)
        t += 1 / rate
    a = resonator(pulses, 780, 16)
    b = resonator(pulses, 1650, 20)
    c = resonator(pulses, 2900, 24)
    out = []
    for i in range(n):
        x = i / n
        shape = math.sin(math.pi * min(1.0, x * 1.15)) ** 0.7
        out.append(gain * shape * (a[i] * 10 + b[i] * 6 + c[i] * 3))
    return out


def thump(gain):
    """Baque grave da folha batendo, com um pouco de ruído (longo o bastante para não cortar com estalo)."""
    n = int(0.37 * RATE)
    e = env(n, 0.002, 0.07)
    e_noise = env(n, 0.001, 0.012)
    out = []
    phase = 0.0
    for i in range(n):
        f = 60 + 50 * math.exp(-i / (0.03 * RATE))
        phase += 2 * math.pi * f / RATE
        out.append(gain * (e[i] * math.sin(phase) + 0.3 * e_noise[i] * rng.uniform(-1, 1)))
    return out


add(0.00, knock(1.0, 950, 1900, 0.025))           # tramela
add(0.04, beep(1318.5, 0.06, 0.20))                # mi
add(0.11, beep(1760.0, 0.09, 0.20))                # lá
add(0.12, creak(0.44, 0.55))                       # dobradiça
add(0.58, thump(0.9))                              # batente
add(0.58, knock(0.45, 520, 1200, 0.02))
add(0.66, knock(0.22, 600, 1300, 0.015))           # quique
add(0.71, knock(0.12, 640, 1350, 0.012))

# fade de saída, compressão suave (o estalo domina o pico) e normalização
tail = int(0.12 * RATE)
for i in range(tail):
    buf[-tail + i] *= 1 - i / tail
peak = max(abs(v) for v in buf)
buf = [math.tanh(DRIVE * v / peak) for v in buf]
peak = max(abs(v) for v in buf)
buf = [v / peak * TARGET_PEAK for v in buf]

root = Path(__file__).resolve().parents[3]
out = root / "audio" / "sfx_porteira.ogg"
with tempfile.TemporaryDirectory() as tmp:
    wav = Path(tmp) / "sfx_porteira.wav"
    with wave.open(str(wav), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(int(max(-1, min(1, v)) * 32767).to_bytes(2, "little", signed=True) for v in buf))
    # o codificador vorbis nativo do ffmpeg só aceita estéreo
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-ac", "2", "-c:a", "vorbis", "-strict", "-2",
                    "-q:a", "6", str(out)], check=True)
print(out)
