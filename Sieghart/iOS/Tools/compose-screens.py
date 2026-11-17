"""Junta as capturas do simulador em duas pranchas (tema claro e escuro).

Uso: python3 compose-screens.py <pasta-das-capturas> <pasta-de-saída>
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SCREENS = [
    ("onboarding", "Primeiro uso"), ("home", "Início"), ("chat", "Conversa"),
    ("conversations", "Conversas"), ("voice", "Voz"), ("team", "Equipe"),
    ("chomp", "Chomp"), ("rita", "Rita · Foco"), ("gantt", "Gantt · Agenda"),
    ("elinor", "Elinor · Finanças"), ("ada", "Ada · Código"), ("toni", "Toni · Ferramentas"),
    ("settings", "Ajustes"), ("pair", "Parear com o Mac"), ("widgets", "Galeria de widgets"),
]


def main(source: Path, target: Path) -> None:
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 28)
    except OSError:
        font = ImageFont.load_default()
    for theme, name, bg, fg in [("light", "claro", (237, 237, 240), (30, 30, 30)),
                                ("dark", "escuro", (14, 14, 16), (230, 230, 230))]:
        shots = [(Image.open(source / f"{key}-{theme}.png"), title)
                 for key, title in SCREENS if (source / f"{key}-{theme}.png").exists()]
        width, height = shots[0][0].size
        scale, cols, gap = 0.28, 5, 36
        tw, th = int(width * scale), int(height * scale)
        rows = (len(shots) + cols - 1) // cols
        sheet = Image.new("RGB", (cols * tw + (cols + 1) * gap, rows * (th + 70) + gap), bg)
        draw = ImageDraw.Draw(sheet)
        for index, (shot, title) in enumerate(shots):
            row, col = divmod(index, cols)
            x, y = gap + col * (tw + gap), gap + row * (th + 70)
            sheet.paste(shot.resize((tw, th)), (x, y))
            draw.text((x, y + th + 14), title, fill=fg, font=font)
        sheet.save(target / f"telas-{name}.png", optimize=True)


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]))
