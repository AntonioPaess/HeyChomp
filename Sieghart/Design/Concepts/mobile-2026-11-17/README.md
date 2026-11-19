# HeyChomp para iPhone: conceito inicial (17/11/2026)

Apenas design. Nada aqui é funcionalidade nem integração real.

- `concept.html`: fonte dos quadros (`?board=app|widgets|lock&theme=light|dark`). Os personagens vêm de `Sieghart/Shared/Resources/ProviderAssets.xcassets` (`Peek-*`, `Companion-*`), sem cópias.
- `render.sh`: gera os PNGs (2x) com o Chrome headless.
- `app-*.png`: boas-vindas, equipe, início e conversa.
- `widgets-*.png`: widgets pequeno, médio e grande da tela de início, além da Live Activity na Dynamic Island.
- `chars-*.png`: widgets v2, em que o personagem é o próprio widget (rosto com brilho na cor do agente e linha de etapas), grade da equipe, sessão de voz na Dynamic Island e Live Activities na tela bloqueada.
- `mix-*.png`: **direção escolhida pelo usuário**, que mistura a v1 e a v2. Quem fala ou está trabalhando aparece de rosto, com brilho na própria cor (v2); em widget de conteúdo, o dono espia por cima (v1). O brilho fica como fundo de todos os widgets.
- `lock-*.png`: acessórios da tela bloqueada (em linha, circular e retangular), notificações e Live Activity do foco.

Referências de estrutura indicadas pelo usuário (sem copiar marca, ícones nem arte): Grok Bot (App Store id6794501026), com widget de rosto e status, grade da equipe e voz na Dynamic Island com microfone e encerrar; OpenBot.run (id6807024266), com quadro de agentes e tarefas em andamento; e Hermes Agent (id6775542529), que ainda não foi analisado. Os widgets da v2 seguem as duas primeiras.

Regras: a cor de cada agente aparece só em marcas (anel, ponto, barra), e a menta do Chomp só na ação principal. O personagem sempre espia apoiado numa borda interna, porque o widget corta o que passa da moldura. Saúde (Rita) e Apple Pay (Elinor) aparecem como "em breve". Na tela bloqueada não aparece dado financeiro.

Pendências conhecidas: no tema escuro, os corpos escuros dos personagens têm pouco contraste sobre os cartões escuros (no Mac acontece o mesmo); avaliar um contorno claro sutil. Os glifos são SVG desenhados à mão; na implementação, trocar por SF Symbols.
