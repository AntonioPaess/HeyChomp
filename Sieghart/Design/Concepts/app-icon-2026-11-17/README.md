# Ícone do HeyChomp: 5 ideias (17/11/2026)

A mesma arte serve para o iOS e o macOS:
- `icon-*.png`: 1024 px, quadrado sem margem. O iOS aplica a máscara.
- `mac-*.png`: 1024 px na grade do macOS, com squircle de 824 px centrado e sombra.

| # | Nome | Ideia |
|---|---|---|
| 1 | Rosto | O Chomp inteiro, de frente, saindo do escuro com brilho menta. |
| 2 | Espiando (recomendada) | O gesto assinatura do app: o Chomp com as mãos na borda de um cartão branco, sobre a menta. |
| 3 | Olhos | Marca mínima: cápsula menta com os olhos, a mesma da Dynamic Island. |
| 4 | Ilha | A pílula preta do notch com o Chomp dentro dela e os pontinhos de "trabalhando". |
| 5 | Balão | O corpo do Chomp vira um balão de fala com rabinho. |

- `generate.py`: gera todas as artes a partir dos assets existentes (`Companion-sig` e o Chomp espiando em alta resolução de `../peeking-team-2026-11-16/bots-sem-fundo/`). Precisa de Pillow.
- `board.html` + `render.sh`: montam a `prancha-icones.png`, com cada ideia no iOS, no macOS e em 52, 34 e 20 px, sobre fundo claro e escuro.

Nada foi aplicado aos apps. O `AppIcon` do protótipo iOS continua com a arte provisória, parecida com a ideia 1. Depois da escolha, falta:
1. Gerar a versão final, incluindo as variantes escura e tingida do iOS 18 e mais recentes.
2. Trocar o `AppIcon` do Mac e do iOS.
3. Avaliar uma versão simplificada para 16 e 32 px no Mac (a ideia 3 serve de base).
