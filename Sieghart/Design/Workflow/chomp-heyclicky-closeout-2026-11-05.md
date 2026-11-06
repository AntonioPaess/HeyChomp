# Fechamento da base HeyClicky e transição para Chomp

A meta para a `main` é um fluxo confiável de assistência sobre o que está na tela. A versão 119 usa a marca Chomp e mantém a identidade de desenvolvimento `com.sieghart.app` para a rodada de aceite. A integração de outros produtos e a refatoração visual entram depois da base estável.

## O que ainda precisa passar antes da main

| Entrega | Estado e critério de aceite |
| --- | --- |
| Tela e seleção | Já há captura, seleção, OCR, cursor e recuperação quando falta permissão. Testar em janela real com texto conhecido, tela inteira e recorte. Incluir duas telas, permissão negada e retomada após conceder. Conferir que o texto e a posição correspondem ao recorte. |
| Explicação e desenho | Já há canvas, revisão de blocos e resposta conjunta de desenho com explicação. Testar um exemplo real de `CPMapTemplate` e um de MVVM. O diagrama deve ser legível, estar ancorado ao elemento certo e aceitar revisão parcial sem apagar os outros blocos. Incluir cancelamento e retomada de uma orientação com etapas. |
| Voz e atalhos | O 116 corrigiu espera de permissão. Ainda falta aceite físico de segurar e soltar, transcrição, resposta no idioma selecionado, interrupção, eco e AirPods. Medir tempo até primeiro texto e primeira fala, com troca de rota, rede e repouso. Manter a etapa suspensa até o usuário liberar som. |
| Ações reais | Repetir Keep Awake com duração, tela ligada e recibo. Validar clima para cidades diferentes com continuação curta. Cobrir falha do modelo e de rede com recuperação que mantém a pergunta. |
| Entrega de resultados | Abrir a resposta original em outro chat passou no 117 real. A soltura no Finder é um critério próprio. O 118 anuncia primeiro a URL do arquivo. O usuário soltou o cartão na pasta real do Finder e a cópia `.md` teve 339 bytes idênticos ao resultado salvo. Outros formatos e destinos continuam com aceite próprio. |
| Integração | Auditar as mudanças locais e separar os commits do lote quando autorizados. A `main` local era ancestral do HEAD da continuação, a 53 commits de distância na leitura de 05/11. Conferir o remoto antes do PR, executar Fast e Complete sobre o candidato final e levar a matriz de aceite junto. |

Para uma paridade mais ampla com o HeyClicky, o ditado global com inserção no app em foco é uma entrega própria. O `DictationTranscriber` atual alimenta reconhecimento dos pedidos do Sieg. Ainda faltam o destino de inserção, a revisão de transcrições e os testes em editor e terminal. Documentos fora da área visível, rotinas longas e mais conectores também precisam de escopo explícito. [Dossiê HeyClicky](../../Sieghart-Research/applications/heyclicky.md).

## Aceite da biblioteca na janela real

O teste no build 117 abriu outra conversa primeiro. Pela biblioteca, a ação Abrir resposta original selecionou o chat da Ada e destacou a mensagem correta. A borda amarela do exportador ficou ausente no chat real escuro. O gesto automatizado inicial gerou uma representação correta, sem entrega no Finder. O 118 colocou `public.file-url` antes dos demais formatos e corrigiu o nome exportado e o singular da contagem. Passaram **145 funções / 607 invocações** na seleção `local-chat | interactions`, com 195/195 fontes esperadas instrumentadas.

Após atualização, a ferramenta de interface falhou ao iniciar gestos de mouse. O usuário concluiu o arraste manual na pasta real do Finder em `/tmp/chomp-drag-qa-2026-11-05`. A leitura do arquivo confirmou a extensão `.md` e 339 bytes idênticos ao resultado salvo. A falha da primeira tentativa não isola a causa do comportamento anterior. O escopo deste aceite é a resposta Markdown no Finder. [Observações](evidence/sieg-artifact-native-2026-11-05/observations.json) · [Contratos](evidence/sieg-artifact-native-2026-11-05/verification.json) · [Instalação](evidence/sieg-artifact-native-2026-11-05/deployment-state.json).

## Ordem após a base

1. **Design do Chomp.** Consolidar navegação, componentes, tipografia, contraste e estados nas abas. Aplicar a mesma linguagem de movimento à janela, aos painéis e às transições de resultado. Usar os estados que já movem o avatar para sincronizar escuta, trabalho, resultado e erro com a interface. Validar tema claro/escuro, teclado e Reduzir Movimento.
2. **Hidden Bar e Raycast.** Implementar a organização dos ícones como módulo próprio e uma paleta que reutilize o catálogo de ações do Chomp. O mantenedor do Hidden Bar documenta uma limitação no macOS 27 e uma abordagem que usa API privada. Conferir as opções públicas e o impacto na distribuição antes de escolher a implementação. [Hidden Bar](https://github.com/dwarvesf/hidden/releases) · [Dossiê Raycast](../../Sieghart-Research/applications/raycast.md).
3. **Token Meter.** Reaproveitar a tela de Uso de IA para mostrar origem, consumo, janela de cota e distinção entre custo real e estimado. Identificar o produto exato a usar como referência antes de importar qualquer código.
4. **OpenBot.** Avaliar filas persistentes, workspaces de agentes e entregas, aproveitando o journal atual. O repositório aponta licença não comercial para a versão corrente. Usar como referência de produto e revisar a licença antes de qualquer reutilização de código. [OpenBot](https://github.com/nightly-labs/openbot#license-and-attribution).

## Identidade e Private Cloud Compute

Decisão para distribuição: **Chomp** como nome visível. O identificador definitivo está em aberto. O usuário descartou o identificador que usava seu nome de Instagram. A Apple permite editar o nome em momentos do ciclo de publicação. O Bundle ID fica vinculado ao registro depois do upload de um build. [Informações do app](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/).

1. Confirmar a participação da equipe no App Store Small Business Program e a elegibilidade de primeiros downloads. A Apple exige também a concessão do entitlement gerenciado para PCC. [Private Cloud Compute](https://developer.apple.com/private-cloud-compute/).
2. Preparar a migração de identidade com cópia de segurança, testes de preferências, histórico e biblioteca. Auditar Keychain, permissões de tela/microfone/acessibilidade, login item, instalador, LaunchServices e guard de Keep Awake. Testar a cópia canônica e informar permissões que precisem ser concedidas de novo. [Mudança de Bundle ID](https://developer.apple.com/documentation/xcode/changing-the-bundle-identifier).
3. Registrar o App ID explícito quando autorizado e consultar **Capability Requests**. A Apple atribui a capacidade à equipe/App ID. Selecionar o perfil compatível no xcconfig opt-in após a concessão e conferir perfil e assinatura nas duas arquiteturas. [Capacidades gerenciadas](https://developer.apple.com/help/account/capabilities/capability-requests/).
4. Escolher **TestFlight interno para Mac** como primeira validação de PCC. Preparar a configuração de distribuição e verificar App Sandbox e o impacto nas ferramentas do Mac. Rodar um teste digitado com conteúdo sintético e verificar resposta real, cota, falha de rede e fallback local. [TestFlight para Mac](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/) · [Distribuição macOS](https://developer.apple.com/macos/distribution/).

Manter o modelo local como padrão para conversas comuns. Oferecer PCC explicitamente em tarefas que se beneficiem de mais contexto, como análise de um documento longo. A rota já existe no código e depende da assinatura e da disponibilidade do serviço. A concessão, o perfil e a disponibilidade para o identificador definitivo ainda precisam ser confirmados. [Guia Foundation Models](https://developer.apple.com/documentation/FoundationModels/adding-server-side-intelligence-with-private-cloud-compute).
