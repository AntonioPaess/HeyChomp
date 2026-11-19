# Ícone final: "Espiando" (17/11/2026)

Ideia escolhida pelo usuário: a 2. O personagem apoia as mãos na borda de um cartão.

- **Dois estilos** (o usuário pediu os dois para comparar):
  - `icones-mesa.png` (**escolhido pelo usuário e aplicado**). Claro invertido: fundo verde-claro com a luz e o contorno de cada personagem iguais aos do escuro, mesa cinza média (#B2B5BD → #80838D) e sombra suave do personagem (a estrela do Chomp não some no verde). Escuro: fundo grafite, contorno de luz e mesa verde fechada (#127450 → #073E2B). A linha das mãos é medida em cada PNG (`hands_line`); antes, a Ada parecia flutuar.
  - `icones-borda.png`: sem mesa. O personagem apoia as mãos na borda de baixo do próprio ícone.
  - Para trocar o estilo aplicado: `python3 Tools/app-icon/generate_app_icons.py borda` (ou `mesa`) e recompilar.
- **Claro:** fundo quase branco. A estrela menta do Chomp e os acessórios de cada agente ficam visíveis; na ideia original, a estrela se perdia no fundo menta.
- **Escuro:** fundo grafite, brilho na cor do agente e um contorno de luz em volta do personagem, para o corpo escuro não sumir.
- **Tingido** (iOS 18 ou mais recente): tons de cinza; o sistema aplica a cor.
- **macOS: só a versão escura** (pedido do usuário), na grade de 824 px com sombra.

Cada agente tem a própria versão. O Chomp é o ícone padrão (iOS e Mac); os outros cinco são ícones alternativos do iPhone, escolhidos em Ajustes → Ícone do app.

`icones-mesa.png` e `icones-borda.png` são as pranchas de conferência. A fonte de tudo é `Sieghart/Tools/app-icon/generate_app_icons.py`.

Pendências:
- No estilo "borda", o selo `</>` da Ada fica meio cortado pela borda do ícone.
- No macOS 26, um ícone fora do Icon Composer ganha o acabamento padrão do sistema. Uma versão `.icon` com camadas (fundo, cartão, personagem, estrela) daria as variantes escura e de vidro no Mac.
- Nos tamanhos de 16 e 32 px do Mac, as mãos quase somem; vale testar uma versão simplificada.
