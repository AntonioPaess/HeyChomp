# HeyChomp — desenvolvimento do app macOS

Para conhecer o produto e os personagens atuais, veja o [README principal](../README.md). Para continuar uma tarefa, comece por [HANDOFF.md](../HANDOFF.md), [CURRENT_WORK.md](../CURRENT_WORK.md) e [KNOWN_ISSUES.md](../KNOWN_ISSUES.md).

## Identidade atual

**Chomp é o companheiro principal fixo.** Rita, Ada, Gantt, Elinor e Toni são especialistas, com responsabilidades próprias. A equipe não é um seletor de avatares alternativos para substituir o Chomp.

![Apresentação da equipe integrada](Design/Readme/sieg-greeting.gif)

*Recorte do runtime integrado; [origem, conversão e limites das prévias](Design/Readme/README.md). Os conceitos de animação antigos permanecem como histórico, não como referência automática para implementação.*

Mensagem digitada recebe resposta visual no chat. Pedido pelo microfone recebe resultado visual e áudio no widget. Captura de tela, ferramentas e desenhos precisam retornar resultados reais; indisponibilidade do modelo não deve produzir respostas de demonstração.

## Requisitos e disponibilidade

- Swift 6 e Xcode com SDK compatível com as APIs usadas pelo projeto.
- Deployment target macOS 14.6. Recursos recentes têm verificações próprias de disponibilidade.
- O motor local AFM 3 exige macOS 27, hardware elegível e Apple Intelligence instalado/pronto. O deployment target não garante acesso ao motor em versões anteriores.
- Microfone, reconhecimento de fala, captura de tela e Accessibility dependem das permissões solicitadas pelo app. O mixer de áudio e outros controles dependem das APIs e dispositivos compatíveis.
- Clima e integrações em rede exigem conectividade. Utilitários locais não dependem de uma resposta do modelo para executar seus controles nativos.

## Compilar

Execute os comandos abaixo nesta pasta, que contém `HeyChomp.xcodeproj`:

```sh
xcodebuild -project HeyChomp.xcodeproj -scheme HeyChomp -configuration Debug -destination 'generic/platform=macOS' -derivedDataPath /tmp/sieg-build-dd build
```

A organização é **Features / Core / Shared**. Consulte [ARCHITECTURE.md](ARCHITECTURE.md) e o [mapa de código do handoff](../HANDOFF.md#mapa-de-código) antes de alterar responsabilidades entre áreas.

## Instalar e abrir

A cópia canônica é `/Applications/HeyChomp.app`, bundle `com.sieghart.app`. Antes de encerrar uma versão com Keep Awake ativo, prepare a proteção temporária; só prossiga depois de confirmar o sucesso do guard:

```sh
python3 Tools/hold-awake-during-update.py prepare
# Encerrar normalmente a versão anterior após a confirmação.
bash Tools/install-current-app.sh /tmp/sieg-build-dd/Build/Products/Debug/HeyChomp.app
bash Tools/launch-current-app.sh --resume-keep-awake-session
```

Abra pelo LaunchServices usando o script. **Não execute `Contents/MacOS/Sieghart` diretamente**: esse lançamento já causou crash por atribuição de privacidade ao processo pai. Não altere configurações de bloqueio do macOS nem reinicie sessões do usuário para testar.

## Verificação

```sh
python3 Tools/run-swift-tests.py --plan fast --output /tmp/sieg-validation-unique --derived-data /tmp/sieg-validation-dd
python3 -m unittest discover -s Tests/Python -p test_update_awake_guard.py
```

Use uma pasta de evidências nova por execução. [Tests/README.md](Tests/README.md) descreve os planos. Build **119** universal instalado em 05/11, com assinatura de desenvolvimento e estado de energia preservado. Seleções dirigidas: leitura **294 funções / 803 invocações** e acabamento **140 / 602**; último plano rápido completo: **380 / 1156** em 27/10. [Fechamento e comparação visual](Design/Workflow/sieg-design-comparison-2026-10-29.md).
O 109 intermediário foi superado pelo 110. Contraste, localização, identidade Sieg, recuperação de energia e cancelamento de leitura estão incorporados. As 32 prévias das abas são renders com dados isolados, sem testes de áudio, modelo ou permissões reais. [Checkpoint e limites](../CURRENT_WORK.md).


Contratos e renders não equivalem a aceite de voz, AirPods, atalho físico, permissões, qualidade do modelo ou todas as telas reais. Esses itens continuam em [KNOWN_ISSUES.md](../KNOWN_ISSUES.md). Não iniciar captura ou reprodução de áudio sem autorização atual do usuário.

## Referências para a próxima mudança

- [Recuperação de intenção, OCR e Keep Awake](Design/Workflow/sieg-intent-and-awake-recovery-2026-10-23.md).
- [Home, abertura e navegação](Design/Workflow/sieg-opening-polish-2026-10-22.md).
- [Padrão visual das 16 abas](Design/Workflow/sieg-premium-design-2026-10-22.md).
- [Animações climáticas integradas](Design/Workflow/sieg-weather-finish-2026-10-22.md).
- [Biblioteca de animações e conceitos históricos](Design/Workflow/avatar-animation-library.md).
- [Pesquisas e REA preservadas](../RESEARCH_INDEX.md), com limites explícitos de cada estudo.
- [Workflow e critérios de revisão](Design/Workflow/README.md).

A preparação para o Swift Student Challenge fica em uma etapa própria. O foco atual é concluir e validar o produto; relatórios de sprints anteriores não devem ser apresentados como estado atual.

Atualize [CURRENT_WORK.md](../CURRENT_WORK.md) antes de trocar de tarefa e após cada lote. Preserve o snapshot para Claude e alterações de outros chats. Commit e push dependem da autorização correspondente.

Edição natural de diagramas no build 112: mover, renomear e destacar blocos pelos títulos atuais, preservando relações e recusando ambiguidades. [Mudanças, testes e limites](Design/Workflow/sieg-canvas-revision-2026-10-29.md). Sem testes de áudio físico ou aceite de leitura/modelo real nesta etapa.

Build 114: recuperação de leitura com conversa/recorte originais, rascunho e anexos preservados; expiração encerra apenas a tarefa correspondente. Inclui o contexto e descarte de resultados atrasados do lote 113. [Entrega de 03/11 e limitações](Design/Workflow/sieg-screen-recovery-2026-11-03.md).

Build 115: avisos localizados, detalhes técnicos expansíveis, recuperação dentro da rolagem do widget e anexos legíveis. Indicador do personagem reflete indisponibilidade do modelo. [Acabamento, evidências e limites](Design/Workflow/sieg-interface-polish-2026-11-03.md).

## Apple Foundation Models e nuvem

O modo local está implementado e depende do Apple Intelligence disponível no Mac. A integração Apple Thinking / Private Cloud Compute está preparada no código, mas **não está habilitada no build 119**: o entitlement gerenciado não consta da assinatura. A concessão na conta Apple Developer e o perfil de distribuição ainda precisam ser conferidos. [Estado comprovado e passos de ativação](Design/Workflow/apple-private-cloud-setup-2026-11-03.md).

**Apple Cloud.** A assinatura de desenvolvimento padrão não traz o entitlement de Private Cloud Compute em nenhuma arquitetura. A configuração de assinatura opt-in está preparada. Identificador de distribuição, registro, concessão e perfil continuam pendentes. [Estado e procedimento](Design/Workflow/apple-private-cloud-setup-2026-11-03.md).

Build 116: espera por permissões de voz com prazo/cancelamento e recuperação nos Ajustes. Seleção callbacks/voice-integration: **125 funções / 176 invocações** aprovada. Atualização preservou o Keep Awake ativo; início e encerramento da escuta observados no app, ainda sem aceite de uma conversa completa. [Evidência e limites](Design/Workflow/sieg-voice-access-2026-11-04.md).


## Respostas que viram arquivos

O chat permite salvar uma resposta ou um bloco de código na biblioteca, com retorno à mensagem original. Busca, filtros e prévias ajudam a retomar; exportação conserva o PDF original e oferece texto extraído em `.txt` quando ele está ausente. Contratos dirigidos: **257 funções / 764 invocações** aprovadas; build 118 instalado na cópia canônica. [Mudanças e limites](Design/Workflow/sieg-artifact-flow-2026-11-04.md).

Testes de som e microfone estão suspensos a pedido do usuário desde 04/11.

O teste na janela real abriu a resposta correta depois de trocar de conversa e não reproduziu a borda amarela do catálogo. O 118 anuncia o arquivo primeiro como URL nativa e passou **145 funções / 607 invocações**. No gesto real, o Finder recebeu um `.md` com bytes idênticos à resposta salva. [Fechamento da base HeyClicky e plano do Chomp](Design/Workflow/chomp-heyclicky-closeout-2026-11-05.md).

O **Chomp 119** passou **491 funções / 1383 invocações** no Complete e **422 / 1282** no Fast. Keep Awake, clima e OCR da imagem sintética foram confirmados no app. Seleção da janela certa, gesto de recorte e diagramas reais continuam com aceite separado. [Renomeação e resultados](Design/Workflow/chomp-rename-acceptance-2026-11-05.md).
