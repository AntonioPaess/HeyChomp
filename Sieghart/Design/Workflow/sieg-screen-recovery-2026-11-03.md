# Recuperação de leitura e entrega do build 114 — 03/11/2026

Build **114** universal instalado e processo conferido em `/Applications/Sieghart.app`. Incorpora o lote 113, interrompido antes da instalação, e a recuperação de leitura concluída nesta retomada. Mesma assinatura pessoal Apple Development do time JZ8TU3BZ38. Sem commit/push, agentes/worktrees adicionais ou alterações no ESP32.

## Contexto e resultados atrasados — lote 113 integrado

- A ferramenta `draw` usa `prepareCanvas`, preserva a pergunta original e recebe o texto observado e o recorte já escolhido. Falta de permissão ou texto legível impede a geração; a consulta sugerida pelo modelo não substitui o pedido do usuário.
- Efeitos assíncronos conferem o turno antes de publicar. Isso inclui desenho, leitura, clima, resultado de especialista e início de orientação. O idioma do desenho fica vinculado ao pedido.
- `SpatialOverlayViewModel` invalida uma inspeção pendente quando recebe outro conteúdo ou é fechado. Uma captura antiga não repõe a anotação nem reaparece depois de dispensada.
- Orientação usa `readableText`, incluindo a seleção/área de texto acessível prioritária, em vez de ruído de menus no OCR bruto.

O lote original reproduziu seis funções/nove casos reprovados antes da correção. A seleção final de outubro passou 247 funções/752 invocações; as evidências continuam em `evidence/sieg-screen-tool-2026-10-29`. O candidato temporário 113 desapareceu após a interrupção e não foi tratado como instalado.

## Recuperação de leitura — trabalho de 03/11

O retry digitado usava uma Task independente, sem o prazo do chat, e consultava a conversa ativa depois da leitura. A reprodução confirmou resposta entregue no chat errado. No botão do chat, o código também substituía o rascunho pela pergunta antiga e podia enviar seus anexos junto.

Agora a recuperação passa pelo pipeline de `LocalChatViewModel`, com prazo, cancelamento e identidade de execução:

- Vincula a resposta à conversa original e mantém o chat selecionado. Repetir o pedido não redistribui o trabalho a outro personagem.
- Substitui a resposta de permissão, preservando a pergunta e o limite de 60 mensagens. Falha, expiração ou cancelamento restaura a resposta anterior.
- Preserva rascunho e anexos. Os anexos de uma mensagem nova não entram na repetição de leitura. Cliques repetidos não abrem gerações concorrentes.
- Guarda o recorte transitório por conversa e força leitura fresca. O retry de voz conserva o recorte e usa o watchdog existente.
- Mostra estado ocupado no controle de recuperação. As rotas digitadas continuam sem TTS ou resultado no widget.
- Expiração/cancelamento pausa imediatamente a tarefa espacial correspondente. A propriedade via `LocalChatExecutionContext` (`@TaskLocal`: conversa + geração), combinada ao identificador do turno, impede fechar um desenho novo ao encerrar uma leitura antiga. Não se infere propriedade só pelo chat selecionado.

Arquivos principais: `SpatialAssistantCoordinator.swift`, `SpatialOverlayViewModel.swift`, `LocalChatViewModel.swift`, `LocalChatItems.swift`; apresentação em `LocalChatPrompt.swift`, `ScreenAccessRecovery.swift`, `CompanionResponseCard.swift` e `NotchWidgetView.swift`. Regressões em `GeneratedCanvasTests.swift` e `ProductPolishTests.swift`.

## Verificação e instalação

Seleção final do plano Complete, grupos `voice-integration|local-chat|agent-room|interactions`: **294 funções / 803 invocações aprovadas**, 195/195 fontes de produção instrumentadas, nenhum seletor ausente/inesperado e fontes estáveis. Não representa execução integral do Complete. O catálogo português passou no `plutil`.

Histórico preservado em `evidence/sieg-screen-retry-2026-11-03`:

- `before`: 108 funções/151 invocações; uma função/caso reprovado confirmou o desvio de conversa.
- `intermediate`: 293/801 aprovados após a recuperação pelo chat.
- `ownership-failure`: 294/803 selecionados; um caso detectou que inferir propriedade pelo chat podia cancelar desenho novo.
- `ownership-fixed` e resultado final na raiz: 294/803 aprovados após vincular a execução à Task e conferir localização.

[Resultado final](evidence/sieg-screen-retry-2026-11-03/verification.json), [manifesto de fontes](evidence/sieg-screen-retry-2026-11-03/source-manifest.json) e [estado instalado](evidence/sieg-screen-retry-2026-11-03/deployment-state.json). Os 285 hashes Swift conferiram na entrega do 114; lotes posteriores têm seus próprios manifestos. Logs/xcresult completos locais: `/tmp/sieg-screen-retry-2026-11-03-verified`; compilação: `/tmp/sieg-build-product-114.log`.

Build arm64/x86_64 compilado, assinatura/identidade verificadas e cópia canônica reaberta por LaunchServices. Keep Awake estava desativado antes/depois, com fingerprint preservado; nenhuma sessão foi criada ou reiniciada e não restou guard temporário. A cópia 112 anterior foi preservada em `/private/tmp/sieghart-previous-app.07mQf9/Sieghart.app`. Avisos -10814 na desinscrição de caminhos antigos de DerivedData não impediram o registro canônico; os arquivos antigos foram preservados.

## Limites e próximo aceite

Captura e geração foram injetadas nos contratos: não houve áudio/microfone/AirPods/atalho físico, modelo real, nova permissão ou aceite de leitura da tela real. Nenhuma classe, temperatura ou explicação de demonstração foi adicionada ao produto. O timeout libera o estado da interface e descarta retorno tardio; não prova que um backend nativo não cooperativo liberou todos os seus recursos.

O recorte é transitório, sem imagem persistida. Depois de reiniciar o app, não prometer restauração daquela seleção; o ensaio de permissão/reinício deve incluir nova seleção quando necessário. Qualidade factual/visual dos diagramas, páginas longas, todos os estados das 16 abas e fluidez acústica continuam pendentes.

Próximo aceite real: autorizar manualmente a cópia canônica quando o usuário retomar esse ensaio; ler classe conhecida, repetir após permissão, trocar de chat, traduzir/explicar e gerar/editar diagrama. Até lá, avançar em fluxos independentes da captura e no acabamento sem repetir automaticamente o pedido de permissão. O inventário de finalização permanece em `sieg-finalization-plan-2026-10-29.md` e `KNOWN_ISSUES.md`.
