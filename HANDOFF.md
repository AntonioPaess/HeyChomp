# Comece aqui — HeyChomp: continuidade do redesign

> **Checkpoint de 11/11/2026, horário de Recife.** Leia este bloco antes dos relatos históricos abaixo. O usuário pediu uma documentação suficiente para outra IA continuar sem o histórico do chat. Este bloco prevalece sobre datas, versões e pendências mais antigas neste arquivo.

## Onde está o trabalho e cuidados imediatos

- Checkout dedicado com os arquivos em trabalho: `/Users/antoniopaesdeandrade/.codex/worktrees/heychomp-design/heychomp-pr11.7y6x55`. Não trabalhar no checkout compartilhado nem sobrescrever alterações de outros chats.
- **Git resolvido em 12/11:** o vínculo antigo com `/private/tmp` (metadados incompletos) foi substituído por um repositório próprio nesta pasta, com `origin` = `https://github.com/AntonioPaess/HeyChomp.git` (apenas fetch). Branch local `design/heychomp-redesign-2026-11-11`, criada sobre `fd97538` (merge do PR #11, presente na `main`), com todo o trabalho de design no commit `bd218da`. Conferido que os arquivos de trabalho ficaram idênticos ao backup anterior. A cópia de trabalho está em CRLF e o repositório em LF; manter o `core.autocrlf=true` global (desligá-lo grava CRLF nos commits). Branch **não publicada**: push só com pedido do usuário. O repositório principal em `~/Documents/ChatGPT/MyDude` está no iCloud com arquivos `dataless` e Git trava ali; não foi alterado.
- App principal observado em `/Applications/HeyChomp.app`: **build 124**, com seis personagens e clima aprovados. O redesign e a correção do onboarding descritos abaixo são candidatos no checkout, **não estão instalados no 124**. Build anterior 123 foi guardado em `/private/tmp/heychomp-previous-app.sESL5C/HeyChomp.app`, caminho temporário sujeito a limpeza.
- O usuário proibiu áudio e microfone nesta etapa; não acionar testes de voz. Um único agente ativo; sem Astra. Seguir integralmente `AGENTS.md`, preservar o snapshot para Claude e não permitir duas IAs escrevendo no mesmo checkout.
- Leia também [CURRENT_WORK.md](CURRENT_WORK.md), [KNOWN_ISSUES.md](KNOWN_ISSUES.md) e [RESEARCH_INDEX.md](RESEARCH_INDEX.md). Atualize o primeiro após cada lote e o segundo quando bugs forem reproduzidos, corrigidos ou validados.

## Direção e decisões do usuário

O usuário rejeitou repetidamente a mistura dos bonecos antigos com novos retratos, olhos, acessórios, luz e animações inconsistentes. A referência aceita é a pintura nova do Chomp aplicada aos seis, com acessórios integrados e gestos adaptados. Também pediu reações do Chomp e do card por clima e temperatura: chuva, tempestade, calor, neve e congelamento, entre outros. Em 10/11 declarou: “tudo validado ta massa pode continuar com tudo que tem que ser feito”. Esse aceite cobre a revisão visual dos bots e do clima apresentada até então; não comprova FPS, hardware físico ou serviço climático real. Preservar esses resultados enquanto o design do app é trabalhado.

Depois, o usuário autorizou seguir com o redesign e lembrou que a animação antiga de onboarding tinha sido retirada. O objetivo atual é terminar a recuperação dessa apresentação **com os modelos novos**, verificar a prévia e continuar o redesign. O usuário quer ver comparações em claro e escuro e testar no app. Não afirmar que o redesign completo ou o onboarding restaurado foram aceitos.

## Feito: bots e clima

- Os seis novos retratos e animações foram integrados ao build 124 instalado. A janela real mostrou os novos personagens e o histórico existente. Os detalhes e tentativas estão em `CURRENT_WORK.md`; código principal em `Sieghart/Sieghart/Shared/Components/Companion/` e `Features/DynamicIsland/Views/`.
- Correções finais de clima: retirado o braço que parecia outra mão; sombra de contato no corpo; gotas com novo movimento e transparência; neve contínua sobre o contorno; congelamento progressivo da pintura com dois olhos. `Sieghart/Tools/WeatherSurfaceQA.swift` e `render-weather-surface.sh` usam recursos reais.
- Evidência anterior: build passou; 30 testes em 14 suítes passaram; checagem no catálogo real constatou pixels azulados 250→4648 e olhos creme 197→191 entre 0 e 10 s em −16°C. Houve exportação de 9×288 quadros e dos dois temas. A pasta de visualizações deste chat contém `clima-superficie-corrigida` com vídeo silencioso, comparações e manifesto. São fixtures; não são medições de desempenho, clima real ou notch físico.
- **Keep Awake:** ao instalar o 124 a reabertura desativou uma sessão anteriormente sem limite com tela ligada. A sessão foi restaurada na UI e então confirmada ativa. Esse é um registro histórico, não garantia do estado atual em 11/11. Antes de qualquer nova instalação, verificar e preservar o estado real e o fluxo de retomada; não assumir que `guard finish` sozinho preserva a sessão.

## Em andamento: redesign do app

A primeira fatia, ainda sem aceite do usuário, foi implementada nestes arquivos:

1. `Sieghart/Sieghart/Features/Workspace/Views/WorkspaceView.swift`: navegação nativa `NavigationSplitView`/lista lateral, título e ações na barra; fallback para renderização de catálogo. A navegação e as ações existentes devem continuar funcionando.
2. `Sieghart/Sieghart/Features/Workspace/Views/CompanionWorkspaceHome.swift`: boas-vindas, Chomp em destaque, ação de conversa, equipe com retratos maiores e sem cartões decorativos permanentes, histórico pesquisável em linhas, rotinas e estados vazios. Preserva fluxo de conversas, ações e armazenamento existentes.
3. `Sieghart/Sieghart/Shared/Components/DesignSystem.swift`: superfícies mais planas e hierarquia comum das telas. O comportamento de superfície fora do workspace, incluindo widget/clima, foi preservado. A mudança afeta componentes compartilhados: revisar todas as abas, não só o Início.

Build candidato **125 arm64 ad hoc** passou em 10/11. Não é o build universal instalado nem uma autorização para substituir o app principal. Foram gerados catálogos com 16 abas × dois temas, antes e depois, com dados de teste. Há limitações do `ImageRenderer`: a barra lateral é fallback e alguns controles AppKit aparecem como barras amarelas; só a janela nativa permite revisar esses controles. Capturas do Início em claro e escuro foram copiadas para a pasta de visualizações `handoff-design-2026-11-11`; não incluem conversas pessoais.

Prévia isolada compilada: `/private/tmp/heychomp-workspace-redesign/HeyChomp Inicio.app`, com dados fictícios, sem modelo real e com voz indisponível. **Ainda não foi aberta nem testada interativamente**. `/private/tmp` pode ser limpo. As fontes e script usados para montá-la foram copiados para [handoff-design-2026-11-11](Sieghart/Design/Workflow/handoff-design-2026-11-11/); são evidência de continuidade, não um pacote portátil pronto: o script contém caminhos absolutos temporários e depende dos recursos de um build. Revise esses caminhos antes de reutilizar. Não lançar o executável principal diretamente; usar o bundle e a ferramenta de interface apropriada.

## Em andamento: animação antiga do onboarding

O problema foi confirmado no código: para ilustrações novas, `CompanionGreetingRig` pulava a coreografia original, ocultando queda, anel e luz e usando outra saudação. Alterações no candidato:

- `Shared/Components/Companion/CompanionGreetingRig.swift`: recupera a linha do tempo original de queda, aceno, partículas e halo sobre a pintura nova; usa mãos pintadas do Chomp.
- `Shared/Components/Companion/CompanionTeamArrival.swift`: mantém a formação da equipe e evita rotação de profundidade indevida para ilustrações; atualiza cenas estáticas de prévia.
- `Features/Onboarding/Views/CompanionOnboardingView.swift`: passa idioma escolhido, oferece “Repetir apresentação” e reinicia ao voltar à primeira etapa ou reabilitar movimento.
- `Sieghart/Tools/OnboardingSurfaceQA.swift`: verificação com recursos de produção. Em 10/11 passou para seis ilustrações, mãos pintadas, queda/anel/aceno, replay, Reduzir Movimento e exportação de 373 quadros em 31 s. A taxa de exportação de 12 quadros/s não mede FPS ao vivo. Pranchas `sequencia-claro.png` e `sequencia-escuro.png` foram copiadas para as visualizações do handoff. Inspecionar também a apresentação com texto e movimento na janela real; as pranchas são cenas isoladas, não demonstram a UI inteira.
- Build 125 passou após a alteração. Seleção dirigida passou **19 testes em 9 suítes**, incluindo onboarding, formação, conversas e apresentação da equipe: `/private/tmp/heychomp-workspace-redesign/contracts.log` e `contracts.xcresult`. Os testes hostless usam fallback sem o catálogo real; por isso a verificação adicional de recursos é necessária.

## Próximos passos, em ordem

1. Resolver com segurança a indisponibilidade dos metadados Git, preservando todo o trabalho local. Não tocar no checkout compartilhado nem na branch/snapshot de outra IA. Conferir novamente status e HEAD só depois do diagnóstico.
2. Conferir a existência da prévia; se necessário recompilá-la a partir das fontes preservadas e dos recursos do build, ajustando os caminhos temporários. Abrir **a prévia isolada**, não substituir o app principal sem validar a alteração, e inspecionar onboarding desde o início, replay, voltar, idioma e Reduzir Movimento. Não usar voz/microfone. A prévia ainda não foi apresentada ao usuário.
3. Verificar Início e navegação ao vivo em claro/escuro, larguras e busca/abertura de conversa fictícia; revisar controles ausentes no catálogo e efeitos da mudança de componentes nas 16 abas. A tentativa de renderizar estados adicionais foi interrompida por limite da revisão automática de aprovação; não houve decisão de segurança sobre o código. Repetir somente quando disponível, sem contornar o bloqueio.
4. Corrigir problemas encontrados, rodar build e testes pertinentes novamente e atualizar `CURRENT_WORK.md`/`KNOWN_ISSUES.md`. Oferecer comparações em claro e escuro e abrir a prévia para avaliação. Não declarar o redesign inteiro pronto por esta primeira fatia.
5. Somente após validação adequada, tratar a integração no app principal com assinatura, histórico e Keep Awake preservados; o 124 não contém a correção de onboarding. Sem commit/push sem pedido.

## Skills usadas neste trabalho

As seguintes skills foram registradas como aplicadas na etapa de personagens/movimento e na continuação do redesign. Releia a `SKILL.md` correspondente antes de aplicar; caminhos locais podem variar em outro ambiente:

- `imagegen` — `/Users/antoniopaesdeandrade/.codex/skills/.system/imagegen/SKILL.md`: criação/edição das ilustrações e recursos visuais dos personagens/clima.
- `ios-motion-and-animation` — `/Users/antoniopaesdeandrade/.agents/skills/ios-motion-and-animation/SKILL.md`: coreografia, transições e alternativa de movimento reduzido para SwiftUI.
- `macos-golden-gate-design` — `/Users/antoniopaesdeandrade/.agents/skills/macos-golden-gate-design/SKILL.md`: revisão/implementação da navegação e das superfícies nativas do Mac; também consultadas as referências de padrões, implementação SwiftUI e fontes da skill.
- `swiftui-ui-patterns` — `/Users/antoniopaesdeandrade/.agents/skills/swiftui-ui-patterns/SKILL.md`: estrutura de telas, fluxo de estado e verificação incremental do redesign.

Esta lista reflete as skills registradas na continuidade disponível, sem presumir outras usadas em conversas antigas. A skill não substitui o pedido do usuário nem o `AGENTS.md`.

---

# Histórico anterior — HeyChomp

Estado de continuidade em **05/11/2026**, horário de Recife. Este repositório é a fonte principal; não é necessário ter o histórico do chat ou o Obsidian para retomar.

**Estado histórico em 05/11.** Build **123** universal instalado como `/Applications/HeyChomp.app`. Projeto, targets e esquemas HeyChomp. Chomp é o nome público do antigo Sieg. O ID de desenvolvimento `com.sieghart.app` e a assinatura foram preservados. Histórico e biblioteca conferidos. O usuário rejeitou `com.chompindev.chomp` para distribuição, e o ID definitivo permanece em aberto. O Private Cloud Compute está preparado no código e ausente na assinatura instalada. O 119 passou em Keep Awake, clima (Recife → Lisboa) e OCR de imagem importada. CarPlay e MVVM geraram diagramas reais por texto no 123. Janela correta, recorte físico, consistência semântica dos diagramas e voz física ainda aguardam aceite. [Relatório da rodada 119](Sieghart/Design/Workflow/chomp-rename-acceptance-2026-11-05.md).

**Snapshot publicado no GitHub:** [feature/sieghart-claude-handoff-2026-10-23](https://github.com/AntonioPaess/Sieghart/tree/feature/sieghart-claude-handoff-2026-10-23). O commit de código e pesquisa `cf9a118e97fe63d52340f9c9c76266da69e725dc` foi confirmado no remoto em 24/10/2026; este checkpoint documental complementa a entrega. O bloqueio anterior de disco/iCloud está registrado como histórico em `CURRENT_WORK.md`.

## Ordem de leitura

1. [Trabalho atual](CURRENT_WORK.md): checkpoint vivo, tarefa em andamento e próximo passo.
2. [Bugs e validações pendentes](KNOWN_ISSUES.md): distingue corrigido em teste, comprovado no Mac e ainda não validado.
3. [Índice de pesquisa e REA](RESEARCH_INDEX.md): dossiês de aplicativos, evidências preservadas e limites das análises.
4. [Fluxo de desenvolvimento](Sieghart/Design/Workflow/README.md), [direção do produto](Sieghart/Design/product-direction-2026-10-11.md) e [auditoria do roadmap](Sieghart/Design/Workflow/sprint-roadmap-audit-2026-10-18.md).

Os relatórios datados são históricos. Um teste aprovado num relatório antigo não supera um bug posterior relatado pelo usuário. `CURRENT_WORK.md` e `KNOWN_ISSUES.md` indicam a situação mais recente.

## Produto e decisões do usuário

HeyChomp é um app macOS nativo, com widget/notch, Home, conversas e ferramentas locais. O objetivo é uma experiência contínua de assistência semelhante ao HeyClicky, com identidade visual própria. Ainda **não há paridade 1:1 comprovada**, nem produto/design declarados completos.

- Chomp, antes chamado Sieg, é o coordenador e atende clima, informações e funções do app. Ada recebe código e matemática. Rita cuida de foco/pausas; Gantt, agenda; Elinor, recursos; Toni, arquivos/escrita. O personagem existir não significa que todas as integrações estejam prontas.
- **Mensagem digitada → resposta visual no chat. Pedido por voz → resultado visual e áudio no widget.** Não tocar áudio para respostas digitadas.
- Segurar o atalho inicia a captura; soltar finaliza e interpreta. Cursor/seleção pertencem ao mesmo turno; interrupções descartam respostas antigas.
- Resposta deve respeitar o idioma selecionado. A voz é parte da identidade de cada personagem; não recolocar uma lista enorme de vozes.
- Leitura da tela, ferramentas e diagramas precisam de evidência real. Não fabricar execução, texto OCR, temperatura ou explicações de demonstração quando o modelo estiver indisponível.
- Design premium consistente nas 16 abas, acessibilidade, transparência limpa, movimentos breves/canceláveis e Reduzir Movimento. Preservar personagens/coreografia aprovados.
- Clima usa nove estados do personagem 2.5D, efeitos no painel todo e recolhimento automático. Não colocar o avatar em um quadrado de fundo nem recolocar o X climático.
- A preparação para o Swift Student Challenge foi adiada por decisão do usuário: agora o foco é o produto.

## Continuação local posterior ao snapshot

Na branch `feature/sieghart-product-continuation-2026-10-23`, a apresentação dos READMEs foi atualizada e foram corrigidos desenho + explicação digitada, contexto de tela da Ada, prioridade do canvas e cancelamento por evento antigo do atalho. Build **107** universal compilado/verificado, instalado e aberto em `/Applications/Sieghart.app` após autorização; plano rápido completo **380 funções / 1156 invocações** aprovado. A cópia de outra worktree foi encerrada normalmente. Keep Awake passou a desativado antes do encerramento; esse estado e o prazo salvo foram preservados, sem timer novo. Sem commit/push dessas mudanças. [Relatório de 27/10](Sieghart/Design/Workflow/sieg-screen-and-drawing-2026-10-27.md) e `CURRENT_WORK.md` conservam o estado e a próxima ação.

Em 28/10, build **108** instalado e aberto com referências naturais à tela, pedidos explicação → diagrama e filtro AX do próprio chat. Seleção dirigida passou **224 funções/684 invocações**. A sessão de Keep Awake ativada pelo usuário foi preservada com proteção real de tela e o mesmo término, 28/10 às 11:43:43 em Recife. [Relatório e limites de 28/10](Sieghart/Design/Workflow/sieg-natural-screen-2026-10-28.md). A tentativa de preparar fonte externa no TextEdit falhou na ferramenta de interface; qualidade do modelo/diagrama real continua pendente. Sem commit/push.

Fechamento posterior: build **110** universal instalado e aberto em 28/10, superando o 109 intermediário. Seleção dirigida passou **193 funções/594 invocações**, incluindo confirmação/recuperação de asserções nativas, retomada, cancelamento de leitura e apresentação. Assinatura pessoal Apple Development, time JZ8TU3BZ38; o instalador impede retorno acidental a ad hoc/outro time. Guard confirmou proteção e preservou o término **28/10 às 23:55:47**, sem timer novo. Esse prazo é histórico. [Fechamento, evidências e comparação visual](Sieghart/Design/Workflow/sieg-design-comparison-2026-10-29.md).

Teste real de leitura no 108 alcançou a recuperação de permissão, sem validar classe/modelo/diagrama. O usuário orientou continuar no design/código, portanto não repetir automaticamente pedidos de desbloqueio/permissão. Catálogo atual com **32 renders das 16 abas**, em dois temas, dados isolados. Home/Aparência antes/depois foram conferidas; isso não conclui auditoria HIG ou aceite de todos os estados. Sem áudio físico, commit/push ou agentes/worktrees adicionais.

Lote anterior em 29/10: build **112** instalado/aberto, mesma assinatura, **214 funções/694 invocações** na seleção dirigida. Edição natural dos blocos do desenho, resolução de nomes com separadores, recusa de ambiguidades e preservação de comandos de janela/código/configurações. Classe com um único membro observado não exige preenchimento inventado. Keep Awake estava desativado e assim foi preservado, sem sessão nova. [Relatório, evidências e limites](Sieghart/Design/Workflow/sieg-canvas-revision-2026-10-29.md). O ESP32 está no chat separado `01a187f4-9692-7332-b2f1-1d0a87e44a66`, restrito à pasta irmã SiegESP32.

## Estado entregue no snapshot de 24/10

Build **106**, universal arm64/x86_64, instalado em `/Applications/Sieghart.app`, bundle `com.sieghart.app`. Verificação final: **371 funções / 1141 invocações**, 195/195 fontes instrumentadas, sem alteração de fontes durante os testes. Oito testes Python do guard de atualização passaram. Não confundir esses contratos com validação acústica ou de todas as telas reais.

Nesta etapa foram corrigidos: interpretação de Keep Awake com duração/tela ligada; preservação da proteção durante atualização; clima herdando indevidamente um pedido de explicação; contexto de desenho + explicação; lentidão/falha de OCR; resposta pronta de pi e relatos fabricados do fallback.

Relatórios essenciais recentes:

- [Recuperação de intenção, OCR e Keep Awake](Sieghart/Design/Workflow/sieg-intent-and-awake-recovery-2026-10-23.md).
- [Abertura, transições e navegação](Sieghart/Design/Workflow/sieg-opening-polish-2026-10-22.md).
- [Padrão visual das 16 abas](Sieghart/Design/Workflow/sieg-premium-design-2026-10-22.md).
- [Finalização das animações climáticas](Sieghart/Design/Workflow/sieg-weather-finish-2026-10-22.md).
- [Crash de voz e regra de lançamento](Sieghart/Design/Workflow/sieg-voice-launch-crash-2026-10-22.md).
- [Produto integrado e limites dos especialistas](Sieghart/Design/Workflow/sieg-product-completion-2026-10-21.md).
- [Mapa de comportamento HeyClicky](Sieghart/Design/Workflow/heyclicky-behavior-gap-2026-10-20.md), histórico, com atualizações posteriores indicadas no próprio arquivo.

## Mapa de código

Os caminhos abaixo são relativos a `Sieghart/Sieghart/`:

| Assunto | Entrada principal |
| --- | --- |
| Turnos, contexto, visão, clima e canvas | `Features/SpatialOverlay/ViewModels/SpatialAssistantCoordinator.swift` |
| Reconhecimento de comandos nativos | `Core/Helpers/VoiceCommands.swift`, `Core/Services/Voice/VoiceAppTools.swift` |
| Modelo Apple, streaming e indisponibilidade | `Core/Services/AI/AppleLocalChatEngine.swift` |
| Ferramentas do modelo e autorização pelo pedido original | `Core/Services/AI/SiegDesktopTool.swift` |
| Captura, Accessibility, OCR e regiões | `Core/Services/Capture/ScreenSemanticInspector.swift` |
| Clima e identidade geográfica | `Core/Services/Voice/VoiceWeatherService.swift`, `WeatherLocationResolver.swift` no mesmo diretório |
| Formas geométricas procedurais | `Features/SpatialOverlay/Views/VectorDrawingInterpreter.swift` |
| Conteúdo gerado do canvas | `Shared/Models/GeneratedCanvas.swift` e serviços de conteúdo espacial em `Core/Services/AI/` |
| Sessão/atalho de voz | `Shared/Services/Activation/ActivationController.swift` e serviços em `Core/Services/Voice/` |
| Keep Awake e persistência | `Features/KeepAwake/ViewModels/KeepAwakeViewModel.swift` |
| Home, navegação e foco | `Features/Workspace/Views/WorkspaceView.swift` |
| Widget e ciclo dos resultados | `Features/DynamicIsland/Views/NotchWidgetView.swift`, `ViewModels/NotchWidgetViewModel.swift` |
| Desenho visual compartilhado | `Shared/Components/DesignSystem.swift`, `Shared/Components/Island/IslandChrome.swift` |
| Animações climáticas aprovadas | `Features/DynamicIsland/Views/CompanionWeatherScene.swift`, `Shared/Components/Companion/CompanionWeatherCharacter.swift` |
| Chat persistente e encaminhamento | `Features/AgentRoom/ViewModels/LocalChatViewModel.swift` |

Testes: `Sieghart/Tests/SwiftTesting/`, fixtures em `Tests/Support/`, testes do guard em `Tests/Python/test_update_awake_guard.py`.

## Compilar, testar e abrir

Requer o SDK e o macOS compatíveis com as APIs Apple utilizadas; o modelo AFM 3 depende de macOS 27 e Apple Intelligence elegível/pronto. Não substituir silenciosamente esse motor por respostas fixas.

Na pasta `Sieghart/`:

```sh
python3 Tools/run-swift-tests.py --plan fast --output /tmp/sieg-validation-unique --derived-data /tmp/sieg-validation-dd
python3 -m unittest discover -s Tests/Python -p test_update_awake_guard.py
xcodebuild -project HeyChomp.xcodeproj -scheme HeyChomp -configuration Debug -destination 'generic/platform=macOS' -derivedDataPath /tmp/sieg-build-dd build
```

Use um diretório de evidência novo para cada execução. Os scripts de teste guardam seleção, resultados individuais, cobertura e alterações de fonte. Não atualizar contagens manualmente sem uma execução correspondente.

O destino único de instalação é `/Applications/HeyChomp.app`. **Nunca abrir diretamente `Contents/MacOS/HeyChomp`**: isso já causou crash por atribuição de privacidade ao processo pai.

Antes de encerrar uma versão com Keep Awake ativo:

```sh
python3 Tools/hold-awake-during-update.py prepare
# Encerrar o app normalmente somente depois de confirmar a proteção temporária.
bash Tools/install-current-app.sh /tmp/sieg-build-dd/Build/Products/Debug/Sieghart.app
bash Tools/launch-current-app.sh --resume-keep-awake-session
```

Não reiniciar timer do usuário para teste, não mudar senha/bloqueio do macOS e não conceder permissões automaticamente. Usar os botões do app que levam aos Ajustes quando necessário.

## Trabalho entre Claude e Codex

O snapshot para Claude deve permanecer estável. A continuação do produto usa outra branch, sem novas worktrees. Cada IA precisa de sua própria pasta já existente ou de alternância exclusiva no mesmo checkout: duas branches não isolam duas IAs escrevendo na mesma pasta simultaneamente.

Não executar `reset --hard`, `clean`, checkout que descarte arquivos, rebase de histórico publicado, merge em main ou push forçado. Preservar mudanças dos outros chats. Um agente por vez; Astra proibido no Codex. Commit/push somente com autorização correspondente do usuário.

## Registro obrigatório de continuidade

Antes de alterar uma área, registrar em `CURRENT_WORK.md` a intenção, arquivos afetados e critério de aceite. Ao concluir um lote, registrar o resultado, evidência, falhas e próximo passo, mesmo que não haja commit. Atualizar `KNOWN_ISSUES.md` quando houver reprodução/correção; adicionar relatório datado quando houver mudança significativa.

Não depender de prever o fim dos tokens ou da cota. Esses checkpoints são parte da entrega. No fim do trabalho, qualquer outra IA deve conseguir responder: o que mudou, por quê, como foi verificado, o que ainda não funciona e qual é o primeiro próximo passo.

Conferência de PCC em 03/11: build 115 sem entitlement gerenciado nas duas arquiteturas assinadas. Código preparado, acesso cloud indisponível; conta/App ID/perfis não verificados. [Estado e ativação](Sieghart/Design/Workflow/apple-private-cloud-setup-2026-11-03.md). Os READMEs distinguem modo local e nuvem.
