# Edição natural de diagramas e classes observadas — 29/10/2026

Build **112** universal instalado e aberto em `/Applications/Sieghart.app`, com a mesma identidade Apple Development do 110. A versão intermediária 111 foi substituída após a revisão do escopo dos comandos. Mudanças locais, sem commit/push. O projeto ESP32 permanece no outro chat e na pasta separada `SiegESP32`.

## Comportamento entregue

`Shared/Models/CanvasRevision.swift` aceita edições em português/inglês sem exigir aspas, usando os nomes do desenho atual. Exemplos de forma, não catálogo de assuntos: “Mova o bloco Entrada para a direita”, “Destaque a etapa Entrada” e “Troque a legenda Entrada por Validação”. Aceita apresentação educada do pedido e os nomes arbitrários fornecidos pelo documento.

O comando de renomear considera os separadores dentro do próprio título. “Troque o bloco Busca por nome por Consulta por usuário” encontra o título existente antes de decidir a substituição. Se dois títulos permitirem interpretações distintas, o app pede esclarecimento sem alterar o desenho. Aspas continuam disponíveis para desambiguar. Alvo duplicado/ausente, sobreposição ou conteúdo inválido não alteram o documento original. IDs, conexões, detalhes e blocos não solicitados são preservados.

A gramática natural só atua com desenho aberto e título reconhecido ou referência explícita a bloco/etapa/legenda. Pedidos de mover Safari, renomear uma variável/arquivo, mudar idioma/tema ou trocar texto selecionado não são desviados para edição. Os comandos antigos com aspas foram preservados. Referências vagas como “mova isso” sem alvo identificável não ganham uma seleção inventada.

`SpatialAssistantCoordinator.swift` usa essa resolução tanto na entrada digitada quanto na transcrição. Falhas de edição respeitam o idioma selecionado; a entrada digitada continua sem áudio/widget. Não são necessárias chamadas ao modelo para executar uma alteração de título/posição já determinada.

`Shared/Models/GeneratedCanvas.swift` e `Core/Services/AI/AppleSpatialContentService.swift` passam a aceitar **um** membro observado de uma classe, em vez de exigir dois. Classe + membro constituem dois nós válidos; a instrução ao gerador não incentiva inventar um segundo membro para preencher o diagrama. Esse ajuste não comprova que o modelo compreendeu qualquer classe real nem transforma ocorrência textual em prova semântica completa.

## Verificação

Seleção `interactions|voice-integration` do plano Complete: **214 funções / 694 invocações aprovadas**, sem seletores ausentes/inesperados ou alteração de fontes durante a execução; 195/195 fontes de produção instrumentadas. Não é uma execução integral do Complete. Regressões em `Tests/SwiftTesting/Presentation/ProductRecoveryTests.swift` cobrem nomes com separadores, ambiguidades, preservação do grafo, comandos de outros contextos, uma classe com um único membro e as duas entradas com transcrição injetada/áudio físico desativado.

O primeiro ensaio não executou testes: o ambiente restrito bloqueou o processo de macros do compilador (`GenerableMacro`, resposta malformada). R2 passou 212/673. A revisão posterior encontrou um conflito de escopo nos novos comandos; R3 passou 213/687 após a primeira restrição. R4 inclui a exigência de desenho aberto e a distinção entre nomes de blocos e nomes/textos de outros contextos, e é o resultado final acima. Essas repetições foram motivadas por alterações novas, não por ampliação arbitrária de cobertura.

Build 112 arm64/x86_64 compilado com sucesso. Verificados bundle, assinatura, identidade estável, instalação e processo canônico. O guard não encontrou sessão ativa de Keep Awake; o estado desativado e o fingerprint das preferências foram preservados. Nenhuma sessão foi iniciada ou reiniciada. Fontes atuais conferem **285/285** entradas do manifesto de testes. O instalador emitiu avisos -10814 ao desregistrar caminhos antigos de DerivedData; a instalação/registro da cópia canônica concluiu e esses arquivos antigos foram preservados.

Evidências portáteis: [resultados finais](evidence/sieg-canvas-revision-2026-10-29/verification.json), [manifesto das fontes](evidence/sieg-canvas-revision-2026-10-29/source-manifest.json), [estado instalado](evidence/sieg-canvas-revision-2026-10-29/deployment-state.json). R2/R3 e estado intermediário do 111 em `history/`. Logs completos/xcresult final no temporário `/tmp/sieg-canvas-revision-2026-10-29-r4`; compilação em `/tmp/sieg-build-product-112.log`.

## Limites e próximo passo

Não foram executados microfone, áudio, AirPods, atalho físico, captura autorizada ou geração pelo modelo real. A leitura de classe real e a qualidade factual/visual dos diagramas continuam pendentes; o usuário havia escolhido continuar no código/design sem retomar a permissão. Não repetir automaticamente a solicitação. A revisão visual das 16 abas e a avaliação completa de arquivos/especialistas continuam no [inventário de finalização](sieg-finalization-plan-2026-10-29.md).

Próximo aceite quando a leitura real puder ser retomada: classe conhecida visível → explicar/diagramar → renomear/destacar/mover um bloco → conferir fonte, relações, legibilidade e preservação do restante. Até lá, avançar nos demais fluxos independentes sem apresentar fixtures como aceite de visão/modelo.
