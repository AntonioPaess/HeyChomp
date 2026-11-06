# Acabamento nativo e ensaio real de tela — 28/10/2026

> Relato intermediário preservado. O 109 foi superado pelo 110 instalado em 28/10; identidade Sieg corrigida, retomada/assinatura verificadas e usuário optou por continuar no design/código sem retomar a permissão. Estado atual no [fechamento de 29/10](sieg-design-comparison-2026-10-29.md).

## Entrega e estado

Build **109** universal compilado e verificado, **ainda não instalado**. A cópia canônica continua no build **108**. As mudanças são locais na branch `feature/sieghart-product-continuation-2026-10-23`; não houve commit/push, agente adicional, worktree, teste físico de voz ou reprodução de áudio.

## Correções de apresentação

- `Shared/Components/UtilityControls.swift`: o rótulo acessível do alternador agora usa a mesma chave localizada do texto visível. O inglês observado no Keep Awake vinha de uma `String` dinâmica passada ao `Toggle`, enquanto o título visível usava `LocalizedStringKey`.
- `Shared/Components/AgentChatComposer.swift`: o campo AppKit usa a cor semântica `labelColor`, que acompanha o tema. O branco fixo prejudicava o tema claro. O rótulo acessível acompanha o placeholder localizado/personagem em cada atualização, preservando o rascunho e sem enviar uma mensagem.
- `Features/Workspace/Views/WorkspaceView.swift`: cartões de aparência anunciam o nome localizado e o estado selecionado como semântica nativa, em vez de “Light appearance”/“Dark appearance”. Esses rótulos ingleses foram observados no 108 em português antes da mudança.
- `Features/AgentRoom/Views/AgentRoomView.swift` e `Shared/Resources/pt-BR.lproj/Localizable.strings`: ajuda do modo do modelo passa pelo catálogo de localização. Incluídas as duas descrições de modo em português, preservando os limites informados no texto original.

Não foram alterados personagens, animações aprovadas, preferências do usuário ou permissões do sistema. O cabeçalho legado “Sig” ainda apareceu na aba Aparência e precisa de uma revisão de identidade em outro lote. Não mudar identificadores persistidos para corrigir apenas a apresentação.

## Teste nativo e compilação

Seleção do grupo `agent-room` no plano Complete: **42 funções / 44 invocações aprovadas**, sem seletores ausentes/inesperados nem alteração de fontes durante a execução. Instrumentação 195/195 fontes de produção. Essa seleção não corresponde a uma execução integral do plano Complete.

O teste novo `AgentComposerTests.presentationRefresh` monta o componente real em `NSHostingView`/`NSPanel` fora da tela. Confere rótulo/placeholder português → inglês, rascunho preservado, nenhuma submissão e contraste da cor nativa em Aqua e Dark Aqua. Os testes existentes do editor continuam aprovados. Nenhuma janela foi exibida pelo teste e nenhuma permissão de acessibilidade/gravação foi concedida.

Build 109 universal arm64/x86_64 aprovado pelo Xcode, assinatura e descrições de privacidade do bundle. SHA-256 do binário: `f2424f55774c5b0cd7662496ab76602f656e79673648b7395ef6a41c078b6c00`. Os 285 arquivos do manifesto Swift permaneceram iguais aos testados. O catálogo `.strings` passou no `plutil` e na compilação. Candidato local: `/tmp/sieg-product-2026-10-27-dd/Build/Products/Debug/Sieghart.app`. Não depender desse temporário como distribuição permanente; fontes e evidências estão no checkout.

## Ensaio no app real — bloqueado por permissão

Preparado um trecho **real do código do produto**, `NativePointerDwellScheduler` em `Shared/Services/Desktop/PointerFocus.swift`, numa página local exibida no navegador. Origem, trecho e SHA-256 ficam em `visible-source.json`. A página serve somente de alvo visual; não substitui OCR/inspector/modelo de produção e não foi implementada como resposta do app.

No build 108 instalado, foi digitado pelo chat: “Leia minha tela e transcreva o texto da classe visível.” O app encaminhou o assunto de código à Ada e retornou a falha real de permissão. A conversa anterior do Sieg foi preservada. Exibiu “Abrir permissão de tela”, “Localizar este app”, “Tentar novamente” e `/Applications/Sieghart.app`. O modelo não recebeu a classe, portanto não houve aceite de leitura, explicação ou diagrama real. Os dados do histórico privado anterior não foram exportados para a evidência.

O usuário foi solicitado a autorizar manualmente a cópia canônica em Gravação de Tela; a pergunta permanece pendente. Não foram acionados microfone, atalhos de voz nem permissões automáticas.

## Mac bloqueado e estado do Keep Awake

Durante a revisão posterior, a ferramenta de interface informou Mac bloqueado e pediu desbloqueio manual. A conferência das **16:42 em Recife** encontrou no app o pedido ativo por 120 min, com tela ligada e término em **28/10 às 18:02:44**, sem condições de alimentação/monitor/apps. A consulta nativa não encontrou asserção de energia pertencente ao processo do Sieghart. Isso é uma observação, **não prova da causa do bloqueio**. Não inferir que foi repouso ocioso, fechamento da tampa, bloqueio explícito, perda de notificação ou falha de aquisição sem evidência correspondente.

O controlador atual libera a asserção em `willSleep` e a retoma em `didWake`, mantendo o prazo original. O estado interno `suspended` não foi observado no processo; não afirmar se estava suspenso ou com erro. Segundo a [documentação da Apple](https://developer.apple.com/documentation/iokit/kiopmassertiontypepreventuseridledisplaysleep), a proteção de tela também impede repouso ocioso enquanto está efetivamente mantida; acrescentar uma segunda asserção sem diagnóstico não resolve a ausência observada. Repouso explícito/tampa pode ocorrer apesar das asserções, conforme a [descrição da proteção de sistema](https://developer.apple.com/documentation/iokit/kiopmassertiontypepreventuseridlesystemsleep).

O app 108 não foi encerrado, o guard não foi armado e nenhuma sessão foi criada/reiniciada para instalar o 109. O guard existente recusa a troca de uma sessão incondicional ativa sem proteção confirmada; não contornar essa condição. A instalação fica preparada até poder conferir o estado após o desbloqueio, armar a proteção e preservar o mesmo prazo. Foi solicitado o desbloqueio manual ao usuário, sem tentativa de alterar autenticação ou desbloquear por outro meio.

## Próximos passos

1. Depois do desbloqueio, conferir status/proteção real do Keep Awake e sua retomada; registrar erro ou motivo de espera se houver. Não reiniciar a sessão para “corrigir” o contador.
2. Preparar guard e instalar o 109 somente com estado compreendido/protegido. Reabrir pelo LaunchServices e conferir rótulos no app real.
3. Após o usuário autorizar a gravação de tela, repetir leitura e “Explique como essa classe funciona e faça um diagrama”; conferir fatos, métodos e layout. Seguir com tradução, recorte e monitores.
4. Continuar acabamento de mensagens dinâmicas, identidade “Sieg”, foco/rolagem e estados longos nas 16 abas. O produto/design não está declarado completo.

Evidências portáteis em `evidence/sieg-native-polish-2026-10-28`: resultado dirigido, manifesto, contratos, fonte visual, tentativa real de leitura, observação/condições do Keep Awake e metadados do build candidato. Logs/result bundle locais: `/tmp/sieg-native-design-2026-10-28`; compilação: `/tmp/sieg-build-product-109.log`.
