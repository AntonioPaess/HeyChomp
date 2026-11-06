# Pedidos compostos e referências à tela — 28/10/2026

## Resultado

Build **108** universal instalado e aberto na cópia canônica `/Applications/Sieghart.app`. Pedidos que começam com explicação e incluem uma segunda instrução de desenho preservam o canvas; referências naturais à fonte visível chegam à leitura de tela e ao gerador. A consulta de Accessibility sob o cursor exclui elementos do próprio processo, assim como a captura já excluía as janelas do app. Não houve teste físico de voz, microfone, AirPods ou atalho, nem reprodução de áudio.

As mudanças deste lote são locais na branch `feature/sieghart-product-continuation-2026-10-23`, sem commit/push. O snapshot para Claude permanece inalterado.

## Falhas e mudanças

1. `CanvasRequest.parse` rejeitava de forma geral frases iniciadas com “explique como”/“explain how”, mesmo com “e faça um diagrama”/“and draw a diagram”. Agora reconhece uma segunda instrução explícita. Perguntas sobre como desenhar, pesquisa e negação continuam sem criar canvas nos casos exercitados. O pedido original não é reescrito nem trocado por um assunto pronto. A chamada nominal da Ada preserva a mesma decisão.
2. As expressões de referência à classe, código, função, método, documento ou texto visível agora são compartilhadas por `CanvasRequest.needsScreenContext` e pelo detector de leitura. Exemplos: “Ada, explica essa classe”, “Explain the selected class”, “Faça um diagrama do código da tela”. “Leia o texto anterior da tela” passa a alcançar a leitura/contexto anterior. Isso não amplia a captura para um monitor ausente nem substitui permissão.
3. A leitura AX sob o cursor não verificava o processo dono do elemento. Um campo do próprio chat poderia ter prioridade sobre o OCR da tela externa. O filtro agora descarta esse elemento antes de ler seus atributos. A aceitação física desse cenário continua pendente; o contrato valida o filtro de dono e os demais contratos preservam a prioridade do texto selecionado/editor externo.

Arquivos de produção: `Sieghart/Shared/Models/GeneratedCanvas.swift` e `Sieghart/Core/Services/Capture/ScreenSemanticInspector.swift`. Testes ampliados em `Tests/SwiftTesting/Presentation/GeneratedCanvasTests.swift` e `ProductPolishTests.swift`.

## Verificação

Seleção dirigida dos grupos `interactions`, `voice-integration` e `local-chat` no plano Fast: **224 funções / 684 invocações aprovadas**, 195/195 fontes de produção instrumentadas, nenhum seletor ausente/inesperado e nenhuma fonte alterada durante a execução. Os testes de entrada de voz injetam transcrições e sintetizadores silenciosos; não validam o hardware. Fonte observada e saída do gerador são fixtures de teste, não respostas de produção.

A primeira execução teve 223 funções aprovadas e uma falha por timeout no teste de cancelamento do canvas. A nova regra inglesa confundia “write code on my screen” (destino) com fonte da tela. O padrão foi restringido a referências explícitas à fonte, incluídos negativos com e sem artigo e limitado o laço do teste a 3 s. A repetição passou, sem ignorar o teste que falhou. Evidências de ambas as execuções preservadas.

Build 108 passou Xcode, assinatura e descrições de privacidade do bundle. Binário universal arm64/x86_64, SHA-256 `d8fe99ef4861fec110756eccef484beeb77bb79cf51c486a3a2540a47e8b090b`. Os 285 arquivos do manifesto de teste permaneceram iguais após a compilação. O último plano Fast **completo** continua sendo o de 27/10 (380 funções/1156 invocações); o lote atual teve seleção dirigida, não uma nova execução integral.

## Keep Awake e instalação

O usuário abriu/ativou sua sessão; não a reiniciamos para teste. Antes da troca, a interface informou Mac e tela acordados e a asserção nativa `PreventUserIdleDisplaySleep` foi confirmada. Prazo salvo: **28/10/2026, 11:43:43 em Recife**. O guard existente criou a proteção temporária antes do encerramento normal. Build 108 foi instalado e lançado pelo LaunchServices com retomada; asserção nativa, preferência ativa e fingerprint do pedido original foram conferidos. O guard temporário foi liberado somente depois da confirmação, mantendo o mesmo prazo. O 107 anterior foi preservado em `/private/tmp/sieghart-previous-app.3WYh4u/Sieghart.app`.

É uma observação datada, não uma afirmação de que a sessão permanece ativa quando este arquivo for lido. Não executar o binário interno diretamente. Nenhuma fonte do guard ou de outra worktree foi modificada.

## Limites e próximo aceite

A Home e a página Keep Awake do app instalado foram observadas pela ferramenta de interface. A tentativa de abrir o TextEdit como fonte externa controlada falhou duas vezes na ferramenta, com ScreenCaptureKit `-3811`, antes de preparar/ler a classe. Isso não é evidência de falha do inspector do Sieghart nem de qualidade do modelo. Não houve leitura real de classe, geração real de diagrama ou concessão de permissões nessa tentativa.

Próximo ensaio: deixar uma classe conhecida visível, selecionar a área e pedir pelo chat “Explique como essa classe funciona e faça um diagrama”. Conferir os métodos e relações do resultado, ausência de áudio, layout e cancelamento. Repetir em inglês e sem chamada nominal. O aceite de CarPlay, documentos longos e múltiplos monitores continua em `KNOWN_ISSUES.md`.

A revisão visual das 16 abas também continua: na página Keep Awake em português, a descrição acessível do alternador ainda apareceu como “Keep display awake too”. Não foi alterada neste lote. Revisar traduções dinâmicas, estados longos/erro, foco e movimento sem misturar esse acabamento com o aceite funcional.

## Evidências portáteis

Pasta `evidence/sieg-natural-screen-2026-10-28/`: `verification.json`, `first-run-verification.json`, `source-manifest.json`, `contract-results.json`, `build-108.json`, `before-update.json` e `deployment-state.json`. Logs integrais/result bundles locais em `/tmp/sieg-natural-screen-2026-10-28[-r2]`; não depender dos temporários para conhecer o resultado.
