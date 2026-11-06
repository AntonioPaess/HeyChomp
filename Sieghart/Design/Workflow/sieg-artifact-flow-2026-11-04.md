# Chat, biblioteca e arquivos — 04/11/2026

O fluxo local agora permite guardar uma resposta ou um bloco de código, encontrá-lo na biblioteca e voltar à mensagem de origem. O build 117 universal foi instalado em `/Applications/Sieghart.app` em 05/11/2026. A verificação deste lote abrange contratos automatizados, prévias isoladas e a instalação.

## Comportamento

- Cada resposta concluída oferece Salvar → resposta inteira ou bloco de código. O registro mantém a conversa e a mensagem de origem; salvar outra vez não duplica o resultado. Blocos `think`, inclusive incompletos ou sem resposta final, não são exportados.
- O salvamento é explícito, local e independente da inferência. Não altera o chat selecionado, rascunhos ou anexos, nem executa código. Respostas em streaming e mensagens que não pertencem mais à conversa são recusadas.
- Biblioteca na Home e em Arquivos: filtros por tipo, busca no título/conteúdo, contagem, estado vazio, nenhum resultado, recuperação de erros e prévias. Abrir resposta original seleciona o chat correto, revela a mensagem e preserva o resultado se a conversa foi removida.
- A representação para exportação/arraste recebe nome legível e extensão coerente. Código mantém seu conteúdo e linguagem conhecida; linguagem desconhecida usa `.txt`.
- PDF importado conserva os bytes originais. Original ausente ou substituído por symlink é recusado; a interface oferece separadamente o texto extraído em `.txt`. Nunca preencher um arquivo `.pdf` com texto puro.
- Resultados gerados são reconstruídos a partir do índice persistido, mesmo se sua representação descartável tiver sumido. Índices antigos continuam legíveis: as duas referências ao chat são opcionais.

## Verificação

Seleção **local-chat | interactions | voice-integration** do plano Complete: **257 funções / 764 invocações aprovadas**, 195/195 fontes esperadas instrumentadas; nenhuma fonte mudou durante execução, nenhum seletor faltou ou sobrou. É uma seleção dirigida, não o plano Complete inteiro. Todos os geradores e dispositivos desses contratos são fixtures; não houve reprodução de som, abertura de microfone, captura ou pedido ao modelo real.

Regressões novas: persistência e identidade após reabrir; exclusão de pensamentos; extensões/bytes de código; origem independente da seleção; recusa de streaming; compatibilidade do índice antigo; PDF exato; original ausente/symlink; texto extraído explícito; regeneração de arquivo; falha de escrita sem falso sucesso. A primeira descoberta compilou, mas o índice recusou novos testes sem IDs de contrato. Descrições corrigidas para G30.04, nova descoberta e execução aprovadas. Após corrigir a representação estática dos controles no catálogo, a seleção final foi repetida com o mesmo resultado 257/764 e fontes estáveis.

Evidências: [verificação](evidence/sieg-artifact-flow-2026-11-04/verification.json), [manifesto de fontes](evidence/sieg-artifact-flow-2026-11-04/source-manifest.json), [contratos](evidence/sieg-artifact-flow-2026-11-04/contract-results.json), [observações e limites](evidence/sieg-artifact-flow-2026-11-04/observations.json). Logs completos/xcresult temporários: `/tmp/sieg-artifact-flow-2026-11-04-r3`.

## Prévia visual

O catálogo final gerou 12 imagens em português e inglês, nos temas claro e escuro. Na inspeção, a biblioteca mostrou a busca em largura integral e a faixa de filtros. A prévia em inglês apresentou Import. O chat mostrou a ação Salvar abaixo da resposta. O render isolado do chat ainda apresenta uma borda amarela externa, sem confirmação na janela real. [Biblioteca no tema escuro](evidence/sieg-artifact-flow-2026-11-04/catalog/pt-BR-dark-filled.png) · [Índice das prévias](evidence/sieg-artifact-flow-2026-11-04/catalog/catalog.json).

## Arquivos principais

- `Core/Services/AI/CompanionArtifactLibrary.swift`: persistência de respostas/origem e representações por bytes; exportação e arraste.
- `Features/AgentRoom/ViewModels/LocalChatViewModel.swift`: admissão do salvamento e revelação da origem.
- `Features/AgentRoom/Views/LocalChatPrompt.swift`: menu de salvamento e foco no transcript.
- `Features/Workspace/Views/CompanionArtifactShelf.swift`: biblioteca, busca, filtros e prévia.
- `WorkspaceView.swift`, `CompanionWorkspaceHome.swift`, `NotchWidgetViewModel.swift`: conexão com a biblioteca persistente e navegação.
- `Tests/WorkspaceCatalog.swift`: catálogo visual isolado `artifacts`.
- `ProductRecoveryTests.swift`, `LocalChatTests.swift`: regressões G30.04.

## Pendências e limites

O build 117 preserva a identidade de assinatura. A verificação conferiu o hash instalado e o processo da cópia canônica. Keep Awake estava desligado e manteve o estado persistido. O aceite do arraste entre apps e da navegação na janela real continua pendente. A biblioteca comporta 100 registros e ainda precisa de gestão recuperável de espaço. [Verificação da instalação](evidence/sieg-artifact-flow-2026-11-04/deployment-state.json).

Áudio físico suspenso pelo usuário em 04/11. Visão/diagramas com conteúdo real, permissões/monitores, sessões longas de energia, especialistas e auditoria completa de todas as telas continuam separados. A configuração PCC permanece opt-in e não aplicada; usuário ainda escolhe nome e recusou registrar o identificador atual. Sem agente/worktree extra, rebrand, alteração de conta Apple, commit ou push.
