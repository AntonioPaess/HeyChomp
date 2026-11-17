"""Gera as 5 ideias de ícone do HeyChomp (iOS e macOS usam a mesma arte).

Uso: python3 generate.py   (na pasta deste arquivo; precisa de Pillow)
Saída: icon-<n>-<nome>.png (1024 px, sem máscara, como o iOS espera) e
       mac-<n>-<nome>.png (1024 px, squircle de 824 px com sombra, grade do macOS).
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageChops

HERE = Path(__file__).parent
ROOT = HERE.parents[2]  # Sieghart/
ASSETS = ROOT / "Sieghart/Shared/Resources/ProviderAssets.xcassets"
PEEK_HD = HERE.parent / "peeking-team-2026-11-16/bots-sem-fundo/Chomp.png"

S = 2048  # desenha em 2x e reduz para 1024
MINT = (0, 148, 95)
MINT_LIGHT = (62, 220, 154)
NIGHT = (12, 12, 13)
INK = (24, 22, 28)
EYE = (255, 246, 230)


def canvas(color=(0, 0, 0, 0)):
    return Image.new("RGBA", (S, S), color)


def vgradient(top, bottom):
    img = Image.new("RGBA", (1, 256))
    for y in range(256):
        t = y / 255
        img.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
    return img.resize((S, S), Image.BICUBIC)


def glow(color, box, blur, alpha=255):
    layer = canvas()
    ImageDraw.Draw(layer).ellipse(box, fill=color + (alpha,))
    return layer.filter(ImageFilter.GaussianBlur(blur))


def sparkle(cx, cy, r, color, img, soft=True):
    """Estrela de quatro pontas côncava (astroide arredondado), como o brilho do Chomp."""
    pts = []
    for i in range(720):
        t = 2 * math.pi * i / 720
        c, s = math.cos(t), math.sin(t)
        e = 2.7  # 2 = losango; 3 = astroide; entre os dois, pontas finas e corpo cheio
        x = math.copysign(abs(c) ** e, c)
        y = math.copysign(abs(s) ** e, s)
        pts.append((cx + x * r, cy + y * r))
    if soft:
        g = canvas()
        ImageDraw.Draw(g).polygon(pts, fill=color + (170,))
        img.alpha_composite(g.filter(ImageFilter.GaussianBlur(r * 0.35)))
    ImageDraw.Draw(img).polygon(pts, fill=color + (255,))


def eyes(img, cx, cy, w, h, gap, color=EYE):
    d = ImageDraw.Draw(img)
    for dx in (-gap / 2, gap / 2):
        d.ellipse((cx + dx - w / 2, cy - h / 2, cx + dx + w / 2, cy + h / 2), fill=color)


def hard_alpha(im, cut=150):
    """Remove o halo de brilho do PNG para assentar o personagem sobre fundos claros."""
    r, g, b, a = im.split()
    a = a.point(lambda v: 255 if v >= cut else 0).filter(ImageFilter.GaussianBlur(1.2))
    return Image.merge("RGBA", (r, g, b, a))


def save(img, n, name):
    icon = img.resize((1024, 1024), Image.LANCZOS)
    icon.convert("RGB").save(HERE / f"icon-{n}-{name}.png")
    mac_icon(icon).save(HERE / f"mac-{n}-{name}.png")


def squircle_mask(size, n=5.0):
    big = size * 2
    m = Image.new("L", (big, big), 0)
    pts = []
    for i in range(1440):
        t = 2 * math.pi * i / 1440
        c, s = math.cos(t), math.sin(t)
        pts.append((big / 2 + math.copysign(abs(c) ** (2 / n), c) * big / 2,
                    big / 2 + math.copysign(abs(s) ** (2 / n), s) * big / 2))
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def mac_icon(icon):
    """Grade do macOS: corpo de 824 px centrado em 1024, com sombra suave."""
    body = icon.resize((824, 824), Image.LANCZOS)
    mask = squircle_mask(824)
    out = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 90), (100, 112), mask)
    out.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14)))
    out.paste(body, (100, 100), mask)
    return out


# 1 · Rosto: o Chomp inteiro, de frente, saindo do escuro com brilho menta.
def concept_face():
    img = canvas(NIGHT + (255,))
    img.alpha_composite(glow(MINT_LIGHT, (S * .05, S * .55, S * .95, S * 1.35), S * .14, 170))
    chomp = Image.open(ASSETS / "Companion-sig.imageset/portrait@2x.png").convert("RGBA").resize((int(S * .8), int(S * .8)), Image.LANCZOS)
    img.alpha_composite(chomp, (int(S * .08), int(S * .07)))
    return img


# 2 · Espiando: o gesto assinatura. O Chomp apoia as mãos na borda de um cartão.
def concept_peek():
    img = vgradient((92, 232, 170), MINT)
    img.alpha_composite(glow((255, 255, 255), (S * .1, -S * .3, S * .9, S * .45), S * .16, 90))
    edge = int(S * .70)
    peek = hard_alpha(Image.open(PEEK_HD).convert("RGBA"))
    w = int(S * 1.18)
    peek = peek.resize((w, int(w * peek.height / peek.width)), Image.LANCZOS)
    # linha das mãos no PNG HD fica em ~80% da altura
    img.alpha_composite(peek, (int((S - w) / 2), edge - int(peek.height * .80)))
    card = canvas()
    ImageDraw.Draw(card).rounded_rectangle((-40, edge, S + 40, S + 200), radius=90, fill=(255, 255, 255, 255))
    shadow = canvas()
    ImageDraw.Draw(shadow).rounded_rectangle((-40, edge - 10, S + 40, S + 200), radius=90, fill=(0, 60, 40, 80))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(30)))
    # o cartão fica atrás das mãos: recompõe só a faixa das mãos por cima
    hands = canvas()
    hands.alpha_composite(peek, (int((S - w) / 2), edge - int(peek.height * .80)))
    band = Image.new("L", (S, S), 0)
    ImageDraw.Draw(band).rectangle((0, edge - 40, S, edge + int(S * .09)), fill=255)
    img.alpha_composite(card)
    img.alpha_composite(Image.composite(hands, canvas(), band))
    return img


# 3 · Olhos: a marca mínima (cápsula menta + olhos), a mesma da Dynamic Island.
def concept_eyes():
    img = canvas(NIGHT + (255,))
    img.alpha_composite(glow(MINT, (S * .15, S * .3, S * .85, S * .8), S * .16, 120))
    cap = canvas()
    w, h = S * .64, S * .36
    ImageDraw.Draw(cap).rounded_rectangle(((S - w) / 2, (S - h) / 2 + S * .03, (S + w) / 2, (S + h) / 2 + S * .03), radius=h / 2, fill=MINT_LIGHT + (255,))
    img.alpha_composite(cap)
    eyes(img, S / 2, S / 2 + S * .03, S * .075, S * .135, S * .17)
    sparkle(S * .79, S * .24, S * .10, MINT_LIGHT, img)
    return img


# 4 · Ilha: a pílula preta do notch com o Chomp morando dentro dela.
def concept_island():
    img = vgradient((246, 246, 244), (226, 240, 233))
    img.alpha_composite(glow(MINT_LIGHT, (S * .1, S * .6, S * .9, S * 1.3), S * .15, 110))
    w, h = S * .78, S * .30
    x0, y0 = (S - w) / 2, S * .35
    sh = canvas()
    ImageDraw.Draw(sh).rounded_rectangle((x0, y0 + 30, x0 + w, y0 + h + 30), radius=h / 2, fill=(0, 0, 0, 110))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(36)))
    ImageDraw.Draw(img).rounded_rectangle((x0, y0, x0 + w, y0 + h), radius=h / 2, fill=(0, 0, 0, 255))
    # rosto do Chomp à esquerda dentro da ilha, como na atividade ao vivo
    cw, chh = h * .92, h * .62
    cx = x0 + h * .62
    ImageDraw.Draw(img).rounded_rectangle((cx - cw / 2, y0 + (h - chh) / 2, cx + cw / 2, y0 + (h + chh) / 2), radius=chh / 2, fill=MINT_LIGHT + (255,))
    eyes(img, cx, y0 + h / 2, h * .1, h * .2, h * .2)
    # três pontinhos de "trabalhando" à direita
    d = ImageDraw.Draw(img)
    for i in range(3):
        px = x0 + w * .62 + i * h * .26
        d.ellipse((px - h * .07, y0 + h / 2 - h * .07, px + h * .07, y0 + h / 2 + h * .07), fill=(255, 255, 255, 235 - i * 70))
    sparkle(S * .80, S * .22, S * .10, MINT, img, soft=False)
    return img


# 5 · Balão: o corpo do Chomp vira um balão de fala, com rabinho e brilho.
def concept_bubble():
    img = vgradient((72, 226, 160), (0, 120, 78))
    blob = canvas()
    d = ImageDraw.Draw(blob)
    d.ellipse((S * .14, S * .22, S * .86, S * .80), fill=INK + (255,))
    d.polygon([(S * .26, S * .66), (S * .44, S * .74), (S * .18, S * .88)], fill=INK + (255,))
    shadow = blob.copy()
    shadow.putalpha(blob.split()[3].point(lambda v: v * 0.45))
    tinted = Image.new("RGBA", (S, S), (0, 50, 30, 0))
    tinted.putalpha(shadow.split()[3])
    img.alpha_composite(ImageChops.offset(tinted, 0, 40).filter(ImageFilter.GaussianBlur(40)))
    img.alpha_composite(blob)
    hl = canvas()
    ImageDraw.Draw(hl).ellipse((S * .24, S * .25, S * .60, S * .40), fill=(255, 255, 255, 18))
    img.alpha_composite(hl.filter(ImageFilter.GaussianBlur(80)))
    eyes(img, S * .52, S * .50, S * .085, S * .15, S * .17)
    sparkle(S * .80, S * .19, S * .11, (220, 255, 236), img)
    return img


CONCEPTS = [
    (1, "rosto", concept_face),
    (2, "espiando", concept_peek),
    (3, "olhos", concept_eyes),
    (4, "ilha", concept_island),
    (5, "balao", concept_bubble),
]

if __name__ == "__main__":
    for n, name, make in CONCEPTS:
        save(make(), n, name)
        print("ok", n, name)
