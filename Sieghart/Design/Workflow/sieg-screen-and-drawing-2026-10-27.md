# Desenho, leitura para a Ada e eventos atrasados do atalho

27/10/2026, horário de Recife. Continuação local em `feature/sieghart-product-continuation-2026-10-23`; snapshot remoto do Claude preservado. Sem commit/push, microfone, atalho físico ou reprodução de áudio nesta entrega. Instalação e abertura do 107 concluídas após autorização do usuário.

## Problemas e comportamento resultante

- **Desenhar e explicar por texto:** o coordenador desenhava a forma vetorial e retornava uma confirmação, descartando a explicação solicitada. Agora envia o pedido completo e o efeito confirmado ao modelo e devolve a explicação no chat. O desenho permanece durante a geração e recebe um prazo de saída depois dela. Indisponibilidade é informada sem substituir a explicação por texto pronto. Respostas canceladas/atrasadas não alteram o próximo desenho.
- **Ada e tela no chat:** chamar a especialista pelo nome podia entrar na consulta antes de ler a tela. Agora o pedido de leitura entrega o texto observado, priorizando seleção/valor acessível sobre OCR de menus. Falha de permissão ou ausência de texto interrompe a consulta; o modelo não recebe uma tela fictícia.
- **Ada e diagrama:** a chamada explícita à especialista não absorve mais o pedido de canvas. O fluxo preserva a geração do diagrama e a preparação do contexto de tela tanto no chat quanto nos eventos de voz injetados. Isso corrige roteamento; qualidade factual/visual do diagrama gerado pelo modelo real continua pendente.
- **Evento antigo do atalho:** `pressVoiceShortcut` cancelava a resposta antes de perguntar ao gesto se o timestamp era válido. Um press atrasado, anterior ao último release, podia desligar uma resposta legítima. A validação agora ocorre numa cópia do gesto, antes de interromper; um novo press válido conserva seu estado mesmo quando cancela o turno anterior.

Texto continua sem áudio e sem cartão de resposta no widget. Voz mantém seu canal próprio. As explicações de desenhos compartilham a construção do contexto; no motor Apple, esse passo usa geração sem ferramentas para não desenhar de novo.

## Arquivos

- `Sieghart/Features/SpatialOverlay/ViewModels/SpatialAssistantCoordinator.swift`: pedido composto, confirmação localizada, contexto de tela para especialista, prioridade de canvas e descarte de leitura/consulta obsoleta.
- `Sieghart/Shared/Services/Activation/ActivationController.swift`: validar timestamp antes de interromper e preservar o novo gesto aceito.
- `Tests/SwiftTesting/Presentation/ProductPolishTests.swift`: regressões de pedidos digitados, modelos indisponíveis, tela negada/vazia, especialista nomeada e contexto substituído.
- `Tests/SwiftTesting/Presentation/VoiceExperienceTests.swift`: exige resposta concluída após evento antigo, informa estado em falha e verifica interrupção por press válido.

## Evidências

Plano rápido completo: **380 funções / 1156 invocações aprovadas**, exit 0, 195/195 fontes instrumentadas, nenhuma fonte alterada durante a execução, sem testes ausentes ou inesperados.

[Verificação](evidence/sieg-screen-and-drawing-2026-10-27/verification.json) · [Hashes das fontes](evidence/sieg-screen-and-drawing-2026-10-27/source-manifest.json) · [Contratos de regressão](evidence/sieg-screen-and-drawing-2026-10-27/contract-results.json).

Comando, a partir da pasta `Sieghart/`:

```sh
python3 Tools/run-swift-tests.py --plan fast --output /tmp/sieg-product-2026-10-27-final-r2 --derived-data /tmp/sieg-product-2026-10-27-dd
```

A execução inicial dos grupos voice-integration/local-chat passou 112 funções/161 invocações para o primeiro lote. Os testes adicionais revelaram a interrupção pelo evento antigo; o teste anterior verificava somente a chamada ao modelo, permitindo uma resposta cancelada parecer bem-sucedida. O ensaio isolado registrou zero chamadas, `busy=false` e `Voice is off`, levando à correção da ordem de validação. Também foram corrigidos um estímulo de teste que não acionava o detector de leitura e uma referência a estado privado no teste novo; o teste final observa comportamento público. Uma tentativa de execução expirou na revisão automática de permissão antes de começar; uma repetição funcionou. O teste de recolhimento climático falhou uma vez, passou na repetição e no plano integral final; o componente de clima não foi alterado e seu aceite em uso real permanece pendente.

Os ensaios usam dependências injetadas e áudio de hardware desativado. OCR real em telas do usuário, qualidade do modelo Apple, AirPods, gesto físico, CPU/RAM e aceite visual dos diagramas continuam pendentes. A revisão dos READMEs e os GIFs preparados em 24/10 foram preservados.

## Build e instalação

Build **107** compilado para arm64 e x86_64, com `CURRENT_PROJECT_VERSION=107`, `ONLY_ACTIVE_ARCH=NO` e assinatura ad hoc. Xcode retornou `BUILD SUCCEEDED`; `Tests/verify-built-app.sh` aprovou assinatura, metadados e descrições de privacidade. SHA-256 do executável: `ccc02b104096e6f85bbe0180b19c87c898e6e700bd493b52a06e88d58e82ca0d`. [Verificação do bundle](evidence/sieg-screen-and-drawing-2026-10-27/build-107.json).

A cópia canônica foi atualizada de 106 para **107** após autorização. A preparação inicial encontrou uma instância build 1 de Xcode DerivedData para `sieghart-validation-worktree`, com sessão salva até 27/10/2026 às 12:20:45 em Recife, e recusou trocar sem uma proteção confirmada da origem.

O usuário autorizou a troca e pediu deixar o novo app aberto. Identidade, assinatura e proteção de tela da origem foram verificadas antes de armar o guard. Para essa preparação pontual, o executável verificado da origem substituiu a constante de origem somente na instância importada do guard; nenhuma fonte/verificação do guard foi alterada, e a confirmação final continuou mirando `/Applications`.

Antes do quit, `awake.active` mudou para false e a operação parou sem encerrar o app. A reconferência preservou esse estado desativado e o pedido/prazo original, liberou o bridge e encerrou normalmente a cópia do Xcode. O 107 foi instalado e aberto via LaunchServices (pai 1), e hash, identidade, encerramento da cópia antiga e liberação do guard foram confirmados. Nenhum timer foi reiniciado/estendido. A cópia 106 anterior foi preservada em `/private/tmp/sieghart-previous-app.1IkaEo/Sieghart.app`. [Estado final da instalação](evidence/sieg-screen-and-drawing-2026-10-27/deployment-state.json). Não reutilizar PIDs antigos nem depender de `/tmp` como distribuição permanente. Keep Awake estava desativado no estado final observado; app aberto não é evidência de proteção ativa.

## Aceite manual após instalar

1. No chat, consultar clima e depois pedir “Desenha um círculo na minha tela e me explica sobre circunferência”. Conferir figura + explicação, sem áudio ou pedido de cidade.
2. Com uma classe conhecida aberta e legível, digitar “Ada, explica o código na minha tela”. Comparar nome, propriedades e métodos citados com o conteúdo visível. Falta de permissão deve ser informada.
3. Na mesma tela, pedir “Ada, faça um diagrama dessa classe na minha tela e explique”. Conferir o canvas, a fidelidade das relações e a leitura das legendas. O teste injetado prova roteamento/contexto, não a qualidade visual/factual do modelo real.

Ensaios físicos do atalho e fala ficam para autorização atual de áudio/hardware. O código mantém o prazo máximo de resposta do chat e o tratamento de cancelamento; nenhuma resposta fixa de conteúdo foi acrescentada.
