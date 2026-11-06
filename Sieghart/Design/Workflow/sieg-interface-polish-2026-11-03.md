# Avisos, recuperação e composição do chat — 03/11/2026

Build **115** universal instalado e aberto em `/Applications/Sieghart.app`, com assinatura pessoal Apple Development do time JZ8TU3BZ38. Incorpora as correções de leitura do 114 documentadas em [recuperação de tela](sieg-screen-recovery-2026-11-03.md).

## Problemas confirmados e mudanças

O catálogo histórico das views de produção mostrou inglês misturado com português na aba Áudio: ausência de dispositivo, volume fixo, instrução de permissão e gravação/status de atalhos. Esses valores eram strings dinâmicas, portanto não passavam pela tradução já existente de rótulos estáticos. Agora usam chaves localizadas; nomes reais de dispositivos, arquivos e combinações de teclas continuam como dados.

No chat, avisos dinâmicos também ignoravam o idioma da interface. Avisos longos eram limitados a três linhas e a altura fixa não acomodava permissão, indisponibilidade e anexos juntos. O lote faz o seguinte:

- Localiza os avisos conhecidos do chat e os motivos de indisponibilidade no idioma da interface; acrescenta 42 traduções ao catálogo português. Não altera o idioma de documentos, histórico ou respostas já geradas.
- Separa a mensagem de falha do detalhe técnico para leitura, documento e salvamento; o detalhe fica em um controle expansível. Substituir/dispensar o aviso limpa o detalhe anterior. O aviso principal não é truncado em três linhas.
- Troca a altura fixa da conversa principal por altura mínima. No widget, avisos e recuperação ficam dentro da rolagem do transcript, mantendo cabeçalho, anexos e compositor acessíveis no espaço limitado.
- Nomes longos dos anexos usam truncamento central, nome completo na ajuda, faixa rolável e controle de remoção identificado para acessibilidade. A remoção fica desativada durante a resposta.
- O indicador de estado do personagem representa preparação, disponibilidade e indisponibilidade, com valor para acessibilidade. Um modelo indisponível não aparece como pronto.
- Ações de recuperação seguem o estilo compartilhado e se reorganizam quando não cabem na mesma linha. Mantidos os botões que abrem a permissão e localizam a cópia em execução.

Arquivos: LocalChatPrompt.swift, LocalChatViewModel.swift, AudioControlsView.swift, ShortcutRecorder.swift, WorkspaceView.swift e pt-BR/Localizable.strings. Não foram alterados os serviços de microfone/mixer/atalho para este acabamento.

## Verificação

Seleção dirigida do Complete, grupos `local-chat|interactions`: **140 funções / 602 invocações aprovadas**, fontes estáveis, sem seletores ausentes/inesperados, 195/195 fontes de produção instrumentadas. [Resultado](evidence/sieg-interface-polish-2026-11-03/verification.json) e [manifesto](evidence/sieg-interface-polish-2026-11-03/source-manifest.json). Esse conjunto complementa o 294/803 do lote de leitura, não representa o plano Complete inteiro.

O português passou no plutil, sem chaves duplicadas. O build universal foi recompilado após a revisão do viewport. Catálogo isolado concluído e preservado em [catalog](evidence/sieg-interface-polish-2026-11-03/catalog/catalog.json): 16 composições do chat (PT/EN, claro/escuro, duas larguras, avisos e recuperação) e duas da aba Áudio. Sem modelo, contas, captura ou hardware. A largura estreita usa um viewport limitado a 300 pontos, em vez de apenas altura natural.

O primeiro catálogo e teste foram preservados em `evidence/sieg-interface-polish-2026-11-03/intermediate`. Sua revisão motivou a correção do modo compacto: o widget tem altura total fixa de 404 pontos, portanto permitir crescimento natural da composição sozinha não resolve o fluxo real. O exportador também representa a faixa de anexos sem depender da renderização offscreen de ScrollView; isso é prévia de composição, não prova do gesto físico.

Foram inspecionados exemplos PT/EN, claro/escuro, recuperação e aviso, no viewport limitado e na conversa principal; o Áudio claro foi comparado com a versão histórica. Não é aceite individual de todos os 18 renders. O exportador isolado mostra uma borda/fundo amarelo fora da superfície arredondada; a origem não foi confirmada em janela real. Uma reexportação com o estilo do host demorou sem concluir e foi interrompida, com log preservado. A alteração experimental do exportador foi revertida; não houve alteração adicional no produto nem nova instalação por esse ensaio. Conferir a moldura na janela real antes de declarar o acabamento completo.

## Instalação

Cópia canônica atualizada e reaberta por LaunchServices; processo, versão, hash e arquiteturas conferidos às 12:10 de 03/11. Keep Awake estava desativado antes/depois, fingerprint preservado, sem sessão criada ou proteção temporária residual. 285 arquivos continuam iguais ao manifesto dos testes finais. [Estado instalado](evidence/sieg-interface-polish-2026-11-03/deployment-state.json). Build 114 preservado em `/private/tmp/sieghart-previous-app.kDfMWx/Sieghart.app`. Avisos -10814 ao desregistrar caminhos antigos não impediram o registro canônico.

## Limites e continuação

Não houve áudio/microfone/AirPods/atalho físico, modelo real, captura real, nova permissão ou sessão Keep Awake criada para teste. Catálogos usam dados isolados e mostram o nome WorkspaceCatalog.app na ajuda de permissão; a cópia real continua sendo /Applications/Sieghart.app. As imagens não são capturas do produto em uso.

O aceite de leitura/diagramas reais continua adiado por orientação do usuário. A revisão deste lote não conclui auditoria HIG, teclado/VoiceOver físico, todos os estados das 16 abas ou paridade HeyClicky. Próximo passo independente: biblioteca/resultados e estados preenchidos das demais abas, preservando personagens e animações aprovados. Sem commit/push, novo agente/worktree ou alteração no ESP32.
