"""Gera o ícone do HeyChomp ("Espiando") para iOS e macOS, em claro, escuro e tingido.

O personagem apoia as mãos na borda de um cartão. Cada agente tem a própria
versão: o Chomp é o ícone padrão e os outros cinco são ícones alternativos que
a pessoa escolhe no app (Ajustes → Ícone do app).

Uso (na pasta Sieghart/):  python3 Tools/app-icon/generate_app_icons.py [mesa|borda]
  mesa  (padrão): o personagem apoia as mãos numa mesa verde;
  borda: sem mesa, as mãos ficam na borda de baixo do próprio ícone.
Precisa de Pillow. Escreve:
- Sieghart/Shared/Resources/ProviderAssets.xcassets/AppIcon.appiconset
  ícone principal (Chomp), compartilhado: iOS 1024 claro/escuro/tingido + todos os tamanhos do macOS
  (no Mac, só a versão escura);
- iOS/HeyChompMobile/Resources/Assets.xcassets/AppIcon-<Agente>.appiconset
  ícones alternativos do iPhone (claro/escuro/tingido);
- iOS/HeyChompMobile/Resources/Assets.xcassets/IconPreview-<agente>.imageset
  miniaturas para a tela de escolha (o app não consegue carregar um appiconset como imagem);
- Design/Concepts/app-icon-2026-11-17/final/icones-mesa.png e icones-borda.png  pranchas dos dois estilos.
"""
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parents[2]  # Sieghart/
HD = ROOT / "Design/Concepts/peeking-team-2026-11-16/bots-sem-fundo"
SHARED = ROOT / "Sieghart/Shared/Resources/ProviderAssets.xcassets"
IOS = ROOT / "iOS/HeyChompMobile/Resources/Assets.xcassets"
BOARD = ROOT / "Design/Concepts/app-icon-2026-11-17/final"

S = 2048                     # desenha em 2x e reduz para 1024
EDGE = 0.70                  # altura da borda do cartão
HANDS = 0.80                 # linha das mãos padrão; cada PNG é medido em hands_line()
SCALE = 1.12                 # largura do PNG em relação ao ícone

# (nome do arquivo HD, chave do agente no app, cor clara, cor escura) — mesmas cores do Agent+Style.
AGENTS = [
    ("Chomp", "chomp", (0, 148, 95), (62, 220, 154)),
    ("Rita", "rita", (97, 33, 109), (219, 156, 246)),
    ("Ada", "ada", (11, 106, 135), (20, 151, 165)),
    ("Gantt", "gantt", (119, 81, 19), (243, 227, 52)),
    ("Elinor", "elinor", (204, 95, 1), (207, 123, 3)),
    ("Toni", "toni", (40, 6, 191), (169, 110, 252)),
]


def canvas(color=(0, 0, 0, 0)):
    return Image.new("RGBA", (S, S), color)


def vgradient(top, bottom):
    strip = Image.new("RGBA", (1, 256))
    for y in range(256):
        t = y / 255
        strip.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
    return strip.resize((S, S), Image.BICUBIC)


def glow(color, box, blur, alpha):
    layer = canvas()
    ImageDraw.Draw(layer).ellipse(box, fill=color + (alpha,))
    return layer.filter(ImageFilter.GaussianBlur(blur))


def hard_alpha(im, cut=150):
    """Tira o halo do PNG: no fundo claro ele vira uma mancha arroxeada."""
    r, g, b, a = im.split()
    a = a.point(lambda v: 255 if v >= cut else 0).filter(ImageFilter.GaussianBlur(1.2))
    return Image.merge("RGBA", (r, g, b, a))


def hands_line(im):
    """Mede, no PNG original, a altura do meio das mãos (fração da altura).

    Os PNGs não têm as mãos na mesma altura: a Ada tem o selo </> embaixo e as
    mãos mais altas. Com uma linha fixa, ela parecia flutuar acima da mesa.
    Procura o pixel escuro e opaco mais baixo nas laterais (onde ficam as mãos)
    e sobe meia mão (~7,6% da altura).
    """
    px, (w, h) = im.load(), im.size
    for y in range(h - 1, 0, -1):
        for x in list(range(int(w * .10), int(w * .31), 3)) + list(range(int(w * .68), int(w * .91), 3)):
            r, g, b, a = px[x, y]
            if a > 200 and r + g + b < 260:
                return y / h - 0.076
    return HANDS


def character(name, dark, edge=EDGE, scale=SCALE):
    im = Image.open(HD / f"{name}.png").convert("RGBA")
    hands = hands_line(im)
    if not dark:
        im = hard_alpha(im)
    w = int(S * scale)
    im = im.resize((w, int(w * im.height / im.width)), Image.LANCZOS)
    pos = (int((S - w) / 2), int(S * edge) - int(im.height * hands))
    layer = canvas()
    layer.alpha_composite(im, pos)
    return layer


def rim(char, color, size, alpha):
    """Contorno de luz em volta do personagem: separa o corpo escuro do fundo."""
    a = char.split()[3].filter(ImageFilter.MaxFilter(size)).filter(ImageFilter.GaussianBlur(size * 0.9))
    layer = Image.new("RGBA", (S, S), color + (0,))
    layer.putalpha(a.point(lambda v: int(v * alpha / 255)))
    return layer


def table(dark):
    """A mesa menta: contraste forte com as mãos escuras e com o fundo."""
    edge = int(S * EDGE)
    # Escuro: verde fechado (o selo menta da Ada continua legível).
    # Claro: invertido, mesa cinza-clara sobre o fundo verde.
    top, bottom = ((18, 116, 80), (7, 62, 43)) if dark else ((178, 181, 189), (128, 131, 141))
    grad = vgradient(top, bottom).crop((0, 0, S, S - edge)).resize((S, S - edge))
    layer = canvas()
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((-60, edge, S + 60, S + 240), radius=96, fill=255)
    layer.paste(grad, (0, edge))
    layer.putalpha(mask)
    # brilho fino na borda de cima, como a quina de uma mesa
    ImageDraw.Draw(layer).line((40, edge + 4, S - 40, edge + 4), fill=(255, 255, 255, 110 if not dark else 70), width=6)
    return layer


def compose(name, tint_light, tint_dark, dark):
    edge = int(S * EDGE)
    if dark:
        # Fundo grafite com brilho na cor do agente; o personagem ganha contorno de luz.
        img = vgradient((34, 33, 40), (16, 16, 19))
        img.alpha_composite(glow(tint_dark, (S * .10, S * .0, S * .90, S * .80), S * .16, 120))
        shadow_color = (0, 0, 0, 170)
    else:
        # Claro invertido: fundo verde-claro com a luz do personagem igual à do escuro
        # (mesma posição e força), e mesa cinza.
        img = vgradient((224, 244, 234), (196, 232, 214))
        img.alpha_composite(glow(tint_dark, (S * .10, S * .0, S * .90, S * .80), S * .16, 150))
        shadow_color = (20, 40, 35, 90)

    char = character(name, dark)
    img.alpha_composite(rim(char, tint_dark, 33, 150))  # contorno de luz nos dois temas
    if not dark:
        # Sombra suave do personagem inteiro: destaca a estrela menta do Chomp no fundo verde.
        drop = Image.new("RGBA", (S, S), (10, 50, 34, 0))
        drop.putalpha(char.split()[3].point(lambda v: int(v * .35)))
        img.alpha_composite(drop.filter(ImageFilter.GaussianBlur(18)).transform((S, S), Image.AFFINE, (1, 0, 0, 0, 1, -12)))
    img.alpha_composite(char)

    shadow = canvas()
    ImageDraw.Draw(shadow).rounded_rectangle((-60, edge - 10, S + 60, S + 240), radius=96, fill=shadow_color)
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(30)))
    img.alpha_composite(table(dark))

    # As mãos (e o selo da Ada) ficam na frente da borda da mesa, com sombra de contato.
    band = Image.new("L", (S, S), 0)
    ImageDraw.Draw(band).rectangle((0, edge - 60, S, edge + int(S * .14)), fill=255)
    front = Image.composite(char, canvas(), band)
    contact = Image.new("RGBA", (S, S), (0, 40, 25, 0) if dark else (30, 32, 40, 0))
    contact.putalpha(front.split()[3].point(lambda v: int(v * (.55 if dark else .45))))
    img.alpha_composite(contact.filter(ImageFilter.GaussianBlur(14)).transform((S, S), Image.AFFINE, (1, 0, 0, 0, 1, -14)))
    img.alpha_composite(front)
    return img.resize((1024, 1024), Image.LANCZOS).convert("RGB")


# Estilo "borda": sem mesa. O personagem apoia as mãos na borda de baixo do próprio ícone.
EDGE_BORDER = 0.925   # linha das mãos, quase na borda inferior
SCALE_BORDER = 1.16


def compose_border(name, tint_light, tint_dark, dark):
    if dark:
        img = vgradient((34, 33, 40), (16, 16, 19))
        img.alpha_composite(glow(tint_dark, (S * .08, S * .18, S * .92, S * 1.05), S * .16, 125))
    else:
        img = vgradient((250, 251, 250), (222, 238, 230))
        img.alpha_composite(glow(tint_light, (S * .10, S * .25, S * .90, S * 1.05), S * .2, 38))
    char = character(name, dark, EDGE_BORDER, SCALE_BORDER)
    if dark:
        img.alpha_composite(rim(char, tint_dark, 33, 150))
    # sombra de contato na borda de baixo, onde as mãos encostam
    ledge = canvas()
    ImageDraw.Draw(ledge).rectangle((0, S * .965, S, S), fill=(0, 0, 0, 90 if dark else 40))
    img.alpha_composite(ledge.filter(ImageFilter.GaussianBlur(24)))
    img.alpha_composite(char)
    return img.resize((1024, 1024), Image.LANCZOS).convert("RGB")


STYLES = {"mesa": compose, "borda": compose_border}


def tinted(dark_icon):
    """Variante tingida do iOS: tons de cinza; o sistema aplica a cor."""
    gray = ImageOps.grayscale(dark_icon)
    return ImageOps.autocontrast(gray, cutoff=1).convert("RGB")


def squircle_mask(size, n=5.0):
    big = size * 2
    pts = []
    for i in range(1440):
        t = 2 * math.pi * i / 1440
        c, s = math.cos(t), math.sin(t)
        pts.append((big / 2 + math.copysign(abs(c) ** (2 / n), c) * big / 2,
                    big / 2 + math.copysign(abs(s) ** (2 / n), s) * big / 2))
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def mac_icon(icon):
    """Grade do macOS: corpo de 824 px centrado em 1024, com sombra."""
    body = icon.resize((824, 824), Image.LANCZOS)
    mask = squircle_mask(824)
    out = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 80), (100, 110), mask)
    out.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14)))
    out.paste(body, (100, 100), mask)
    return out


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n")


def ios_iconset(folder, light, dark):
    folder.mkdir(parents=True, exist_ok=True)
    light.save(folder / "icon-light.png")
    dark.save(folder / "icon-dark.png")
    tinted(dark).save(folder / "icon-tinted.png")
    return [
        {"filename": "icon-light.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        {"appearances": [{"appearance": "luminosity", "value": "dark"}],
         "filename": "icon-dark.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        {"appearances": [{"appearance": "luminosity", "value": "tinted"}],
         "filename": "icon-tinted.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
    ]


def render_all(style):
    make = STYLES[style]
    return {key: (make(name, tl, td, dark=False), make(name, tl, td, dark=True)) for name, key, tl, td in AGENTS}


def board(rendered, path):
    """Prancha de conferência: claro, escuro, tingido e macOS (escuro) para cada agente."""
    tile, gap = 220, 40
    cols = ["Claro", "Escuro", "Tingido", "macOS"]
    sheet = Image.new("RGB", (gap + len(cols) * (tile + gap) + 140, gap + 50 + len(AGENTS) * (tile + gap)), (236, 236, 240))
    d = ImageDraw.Draw(sheet)
    try:
        from PIL import ImageFont
        font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 26)
    except OSError:
        font = None
    for c, title in enumerate(cols):
        d.text((140 + gap + c * (tile + gap), gap), title, fill=(60, 60, 60), font=font)
    rmask = Image.new("L", (tile * 4, tile * 4), 0)
    ImageDraw.Draw(rmask).rounded_rectangle((0, 0, tile * 4, tile * 4), radius=int(tile * 4 * .2237), fill=255)
    rmask = rmask.resize((tile, tile), Image.LANCZOS)
    for r, (name, key, _, _) in enumerate(AGENTS):
        light, dark = rendered[key]
        y = gap + 50 + r * (tile + gap)
        d.text((gap, y + tile / 2 - 14), name, fill=(30, 30, 30), font=font)
        for c, im in enumerate([light, dark, tinted(dark)]):
            sheet.paste(im.resize((tile, tile), Image.LANCZOS), (140 + gap + c * (tile + gap), y), rmask)
        m = mac_icon(dark).resize((tile, tile), Image.LANCZOS)
        sheet.paste(m, (140 + gap + 3 * (tile + gap), y), m)
    sheet.save(path, optimize=True)


def main(style="mesa"):
    """`style` decide o que vai para os catálogos; as pranchas saem nos dois estilos."""
    BOARD.mkdir(parents=True, exist_ok=True)
    all_styles = {name: render_all(name) for name in STYLES}
    for name, rendered_style in all_styles.items():
        board(rendered_style, BOARD / f"icones-{name}.png")
        print("prancha", name)
    rendered = all_styles[style]

    # Ícone principal compartilhado (Chomp): iOS + macOS.
    light, dark = rendered["chomp"]
    folder = SHARED / "AppIcon.appiconset"
    images = ios_iconset(folder, light, dark)
    mac = mac_icon(dark)  # no Mac o ícone é só a versão escura (pedido do usuário)
    for pt in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            px = pt * scale
            fname = f"mac-{pt}@{scale}x.png"
            mac.resize((px, px), Image.LANCZOS).save(folder / fname)
            images.append({"filename": fname, "idiom": "mac", "scale": f"{scale}x", "size": f"{pt}x{pt}"})
    write_json(folder / "Contents.json", {"images": images, "info": {"author": "xcode", "version": 1}})

    # Alternativos do iPhone e miniaturas para a tela de escolha.
    for name, key, _, _ in AGENTS:
        light, dark = rendered[key]
        if key != "chomp":
            imgs = ios_iconset(IOS / f"AppIcon-{name}.appiconset", light, dark)
            write_json(IOS / f"AppIcon-{name}.appiconset/Contents.json", {"images": imgs, "info": {"author": "xcode", "version": 1}})
        prev = IOS / f"IconPreview-{key}.imageset"
        prev.mkdir(parents=True, exist_ok=True)
        light.resize((240, 240), Image.LANCZOS).save(prev / "light.png")
        dark.resize((240, 240), Image.LANCZOS).save(prev / "dark.png")
        write_json(prev / "Contents.json", {"images": [
            {"filename": "light.png", "idiom": "universal"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}], "filename": "dark.png", "idiom": "universal"},
        ], "info": {"author": "xcode", "version": 1}})

if __name__ == "__main__":
    import sys
    main(sys.argv[1] if len(sys.argv) > 1 else "mesa")
