"""Porteira de sucata do fim de fase (scenes/goal.tscn). Gera assets/goal/goal_porteira.png.

Uso, da raiz do projeto: python3 art/_gerado/goal_porteira/gerar_porteira.py  (precisa do Pillow)

Folha 16 x 56x48 em duas linhas: linha 0 = fundo (mourão da lâmpada + folha), linha 1 = frente (mourão da tramela).
Quadros: fechada 0-3 (4 fps, loop, lâmpada âmbar pisca), abrindo 4-11 (14 fps, uma vez: tramela pula, lâmpada fica
verde, folha gira e quica), aberta 12-15 (5 fps, loop). Origem da cena = chão no meio do quadro (28, 48).
A porteira fica na diagonal: o Timby passa na frente do primeiro mourão, atravessa e some atrás do segundo.
"""
import math
from pathlib import Path

from PIL import Image

W, H = 56, 48
FRAMES = 16


def rgb(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


OUT = rgb("#322c43")
WOOD_D = rgb("#502418")
WOOD_M = rgb("#833019")
WOOD = rgb("#ab4921")
WOOD_L = rgb("#c9713a")
WOOD_HL = rgb("#de9a60")
ZINC_D = rgb("#5d6670")
ZINC = rgb("#7f8f98")
ZINC_L = rgb("#9badb7")
ZINC_HL = rgb("#cfdbe0")
RUST = rgb("#9f5b45")
SOLAR_D = rgb("#2e3f7a")
SOLAR = rgb("#4a67b1")
SOLAR_L = rgb("#5876bd")
SOLAR_HL = rgb("#9badb7")
IRON = rgb("#2f2f2f")
LED_OFF = rgb("#5a3a2a")
AMBER = rgb("#ffb03a")
AMBER_GLOW = rgb("#ffb03a", 70)
GREEN = rgb("#8cf06a")
GREEN_HL = rgb("#e6ffd2")
GREEN_GLOW = rgb("#8cf06a", 70)
FLASH = rgb("#fffbd1")
DUST = rgb("#de9a60", 170)
DUST_L = rgb("#e9c39a", 110)

# geometria (em px do quadro)
GROUND = 47                 # última linha: pé no chão
HINGE_X = 11                # borda esquerda da folha (dobradiça)
PANEL_W = 35                # folha fechada vai de 11 a 45
PANEL_TOP, PANEL_BOT = 24, 42
L_POST = (6, 10)            # mourão mestre (com caixa, lâmpada e placa solar)
L_POST_TOP = 13
R_POST = (46, 50)           # mourão da tramela
R_POST_TOP = 21


def blank(w=W, h=H):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def rect(im, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(im, x, y, c)


def outline(layer, color=OUT):
    """Contorno de 1 px (4-vizinhos) em volta do que for opaco na camada."""
    out = layer.copy()
    px = layer.load()
    for y in range(layer.height):
        for x in range(layer.width):
            if px[x, y][3] > 200:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < layer.width and 0 <= ny < layer.height and px[nx, ny][3] > 200:
                    out.putpixel((x, y), color)
                    break
    return out


def shade(c, k):
    return (round(c[0] * k), round(c[1] * k), round(c[2] * k), c[3])


# ---------- folha da porteira (plana, sem contorno) ----------

def panel_flat():
    """Folha vista de frente: 3 tábuas, mão-francesa, montantes, chapa de zinco num vão."""
    pw, ph = PANEL_W, PANEL_BOT - PANEL_TOP + 1
    im = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
    # chapa de zinco ondulado tampando um pedaço do vão de baixo (sucata)
    for y in range(10, 17):
        for x in range(17, 30):
            col = (ZINC_L, ZINC, ZINC_D, ZINC)[(x - 17) % 4]
            if y == 10:
                col = ZINC_HL if (x - 17) % 4 == 0 else ZINC_L
            put(im, x, y, col)
    for x, y in ((24, 15), (25, 16), (19, 14)):          # ferrugem
        put(im, x, y, RUST)
    # tábuas horizontais (3 px: luz, meio, sombra), com veio
    for ry in (0, 8, 16):
        for x in range(pw):
            put(im, x, ry, WOOD_HL if (x * 7 + ry) % 13 == 0 else WOOD_L)
            put(im, x, ry + 1, WOOD_M if (x * 5 + ry) % 11 == 0 else WOOD)
            put(im, x, ry + 2, WOOD_M)
    for x, y in ((18, 9), (28, 9), (18, 16), (28, 16)):   # pregos da chapa
        put(im, x, y, IRON)
    # mão-francesa: do pé da dobradiça ao alto da ponta (3 px de espessura)
    x0, y0, x1, y1 = 3, ph - 4, pw - 4, 1
    steps = max(abs(x1 - x0), abs(y1 - y0))
    for i in range(steps + 1):
        t = i / steps
        x = round(x0 + (x1 - x0) * t)
        y = round(y0 + (y1 - y0) * t)
        put(im, x, y - 1, WOOD_HL)
        put(im, x, y, WOOD_L)
        put(im, x, y + 1, WOOD_M)
    # montantes (dobradiça e ponta), 3 px
    for x0_ in (0, pw - 3):
        for y in range(ph):
            put(im, x0_, y, WOOD_L)
            put(im, x0_ + 1, y, WOOD)
            put(im, x0_ + 2, y, WOOD_M)
    # ferragens da dobradiça (tiras de ferro)
    for hy in (1, ph - 3):
        rect(im, 0, hy, 4, hy + 1, ZINC_D)
        put(im, 1, hy, ZINC_L)
        put(im, 3, hy, IRON)
    return im


PANEL = panel_flat()


def panel_at(angle_deg):
    """Projeta a folha girada em torno da dobradiça, abrindo para o fundo."""
    a = math.radians(angle_deg)
    ca, sa = math.cos(a), math.sin(a)
    pw, ph = PANEL.size
    layer = blank()
    cy = (PANEL_TOP + PANEL_BOT) / 2
    vis_w = max(2, round(pw * ca))
    src = PANEL.load()
    for dx in range(vis_w):
        u = min(pw - 1, int((dx + 0.5) / ca)) if ca > 1e-3 else pw - 1
        s = 1.0 - 0.22 * (u / pw) * sa          # abre para o fundo: a ponta solta encolhe
        k = 1.0 - 0.35 * (u / pw) * sa          # e escurece
        for dy in range(-ph, ph + 1):
            v = dy / s + (ph - 1) / 2
            vi = round(v)
            if 0 <= vi < ph:
                c = src[u, vi]
                if c[3]:
                    put(layer, HINGE_X + dx, round(cy + dy), shade(c, k))
    # quando a folha está quase de lado, aparece a espessura do montante da ponta
    if angle_deg > 30:
        ex = HINGE_X + vis_w
        top = round(cy - (ph / 2) * (1.0 - 0.22 * sa))
        bot = round(cy + (ph / 2) * (1.0 - 0.22 * sa)) - 1
        for y in range(top, bot + 1):
            put(layer, ex, y, shade(WOOD_M, 0.85))
    return layer


# ---------- mourões, tramela, caixa solar ----------

def left_post(led):
    """led: 'off' | 'amber' | 'flash' | 'green' | 'green_hi'"""
    layer = blank()
    x0, x1 = L_POST
    for y in range(L_POST_TOP, GROUND + 1):
        for x in range(x0, x1 + 1):
            c = (WOOD_L, WOOD, WOOD, WOOD_M, WOOD_D)[x - x0]
            if (y * 3 + x) % 13 == 0:
                c = WOOD_M
            put(layer, x, y, c)
    # anel de arame
    for x in range(x0, x1 + 1):
        put(layer, x, 30, ZINC_D)
        put(layer, x, 31, ZINC_L if x == x0 + 1 else ZINC)
    # caixa de zinco (bateria) em cima do mourão
    rect(layer, 4, 9, 12, 13, ZINC)
    rect(layer, 4, 9, 12, 9, ZINC_HL)
    rect(layer, 4, 13, 12, 13, ZINC_D)
    put(layer, 11, 11, RUST)
    # lâmpada (LED) na frente da caixa, virada para o caminho
    led_c = {"off": LED_OFF, "amber": AMBER, "flash": FLASH, "green": GREEN, "green_hi": GREEN_HL}[led]
    rect(layer, 6, 10, 10, 12, IRON)
    rect(layer, 7, 11, 9, 11, led_c if led != "off" else LED_OFF)
    if led != "off":
        put(layer, 8, 11, FLASH if led in ("flash", "green_hi") else led_c)
    # haste e placa solar inclinada
    put(layer, 6, 8, IRON)
    put(layer, 6, 7, IRON)
    for i, y in enumerate(range(3, 7)):
        xa = 1 + i
        xb = 12 + i
        for x in range(xa, xb + 1):
            c = SOLAR if (x + y) % 4 else SOLAR_L
            if x in (xa, xb):
                c = SOLAR_D
            put(layer, x, y, c)
    for x in range(1, 13):
        put(layer, x, 2, SOLAR_HL if x % 3 else SOLAR_L)
    return layer


def right_post():
    layer = blank()
    x0, x1 = R_POST
    for y in range(R_POST_TOP, GROUND + 1):
        for x in range(x0, x1 + 1):
            c = (WOOD_L, WOOD, WOOD, WOOD_M, WOOD_D)[x - x0]
            if (y * 5 + x) % 11 == 0:
                c = WOOD_M
            put(layer, x, y, c)
    # topo cortado em bisel
    put(layer, x1, R_POST_TOP, (0, 0, 0, 0))
    put(layer, x1 - 1, R_POST_TOP, (0, 0, 0, 0))
    put(layer, x1, R_POST_TOP + 1, (0, 0, 0, 0))
    # pino da tramela
    put(layer, x0, 30, IRON)
    return layer


def latch(up):
    """Tramela: taramela de madeira presa no mourão da direita."""
    layer = blank()
    if up:
        rect(layer, 45, 23, 46, 30, WOOD_L)
        rect(layer, 46, 23, 46, 30, WOOD_M)
    else:
        rect(layer, 40, 29, 47, 30, WOOD_L)
        rect(layer, 40, 30, 47, 30, WOOD_M)
    put(layer, 46, 30, IRON)
    return layer


def glow(im, cx, cy, color, r):
    """Halo da lâmpada: mistura por cima de tudo, menos no próprio LED."""
    over = blank()
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if d2 <= r * r + 1 and not (cy == y and abs(x - cx) <= 1):
                put(over, x, y, color[:3] + (color[3] if d2 > 2 else min(255, color[3] * 2),))
    im.alpha_composite(over)


def dust(im, x, y, step):
    pts = {0: [(0, 0), (2, -1), (-2, -1)], 1: [(-1, -1), (2, -2), (4, -1), (-3, -2)], 2: [(-2, -3), (4, -3), (6, -2)]}[step]
    for dx, dy in pts:
        put(im, x + dx, y + dy, DUST if step < 2 else DUST_L)
        put(im, x + dx + 1, y + dy, DUST_L)


def frame_layers(angle, led, latch_up, dust_step=None, led_glow=False, glint=None, shake=0, latch_pop=False):
    """Duas peças: fundo (mourão da lâmpada + folha), atrás do Timby; frente (mourão da tramela), na frente dele.
    A porteira fica na diagonal: o Timby passa na frente do primeiro mourão, atravessa e some atrás do segundo."""
    back = blank()
    back.alpha_composite(outline(panel_at(angle)), (shake, 0))
    back.alpha_composite(outline(left_post(led)))
    if glint is not None:              # brilho correndo na placa solar
        for i in range(2):
            put(back, glint + i, 3 + i, SOLAR_HL)
    if led_glow:
        glow(back, 8, 11, GREEN_GLOW if led.startswith("green") else (AMBER_GLOW if led == "amber" else rgb("#fffbd1", 110)), 4)
    if dust_step is not None:
        dust(back, HINGE_X + max(2, round(PANEL_W * math.cos(math.radians(angle)))) + 1, GROUND, dust_step)
    front = blank()
    front.alpha_composite(outline(right_post()))
    front.alpha_composite(outline(latch(latch_up)))
    if latch_pop:
        for x, y in ((49, 21), (51, 23), (43, 21), (52, 26)):
            put(front, x, y, FLASH)
    return back, front


# fechada 0-3 · abrindo 4-11 · aberta 12-15
SEQ = [
    dict(angle=0, led="amber", latch_up=False, led_glow=True),
    dict(angle=0, led="amber", latch_up=False),
    dict(angle=0, led="off", latch_up=False),
    dict(angle=0, led="off", latch_up=False),
    dict(angle=0, led="flash", latch_up=True, led_glow=True, shake=1, latch_pop=True),
    dict(angle=14, led="green_hi", latch_up=True, led_glow=True),
    dict(angle=34, led="green", latch_up=True, led_glow=True),
    dict(angle=52, led="green", latch_up=True, led_glow=True, dust_step=0),
    dict(angle=68, led="green", latch_up=True, led_glow=True, dust_step=1),
    dict(angle=78, led="green", latch_up=True, led_glow=True, dust_step=2),
    dict(angle=68, led="green", latch_up=True, led_glow=True),
    dict(angle=72, led="green", latch_up=True, led_glow=True),
    dict(angle=72, led="green_hi", latch_up=True, led_glow=True, glint=2),
    dict(angle=72, led="green", latch_up=True, led_glow=True, glint=5),
    dict(angle=72, led="green", latch_up=True, glint=8),
    dict(angle=72, led="green", latch_up=True, led_glow=True),
]


def sheet():
    """Linha 0 = fundo, linha 1 = frente; 16 colunas de 56x48."""
    out = Image.new("RGBA", (W * FRAMES, H * 2), (0, 0, 0, 0))
    for i, kw in enumerate(SEQ):
        back, front = frame_layers(**kw)
        out.alpha_composite(back, (i * W, 0))
        out.alpha_composite(front, (i * W, H))
    return out


if __name__ == "__main__":
    out = Path(__file__).resolve().parents[3] / "assets" / "goal" / "goal_porteira.png"
    sheet().save(out)
    print(out)
