# Estado do Apple Private Cloud Compute — 03/11/2026

**O build 115 instalado não inclui o entitlement de PCC.** A integração com PrivateCloudComputeLanguageModel existe no AppleLocalChatEngine, mas o modo Apple Thinking é bloqueado por AppleChatEligibility quando a assinatura não contém a autorização. O modelo local continua sujeito à disponibilidade do Apple Intelligence.

## Evidência local

- O projeto usa Sieghart/Sieghart.entitlements; esse arquivo inclui áudio de entrada, calendário e automação, sem a chave com.apple.developer.private-cloud-compute.
- Foram extraídos os entitlements efetivamente assinados das duas arquiteturas do executável instalado (arm64 e x86_64). Nenhuma contém a chave. O hash corresponde ao build 115 verificado na implantação. [Resultado estático](evidence/sieg-interface-polish-2026-11-03/private-cloud-entitlements.json).
- A conta Apple Developer, o App ID e seus perfis não foram consultados. A ausência no app não comprova se a conta já recebeu aprovação. Não declarar acesso aprovado, recusado ou pedido enviado sem verificar o portal.

## Requisito da Apple, consultado em 03/11/2026

O PCC usa um entitlement gerenciado. A Apple exige participação no App Store Small Business Program, limite inferior a dois milhões de primeiros downloads por app e a atribuição dessa autorização à conta. A página oficial descreve uso via App Store e testes por TestFlight ou distribuição ad hoc. [Elegibilidade e solicitação](https://developer.apple.com/private-cloud-compute/) e [chave do entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.private-cloud-compute).

## Próximos passos para ativar

1. Conferir no portal a elegibilidade e se o entitlement já foi atribuído à conta e ao identificador com.sieghart.app; solicitar quando necessário.
2. Habilitar a capability e gerar um perfil compatível com a distribuição admitida pela Apple. A assinatura de desenvolvimento atual não demonstra permissão para usar o serviço.
3. Incluir a chave booleana com.apple.developer.private-cloud-compute no conjunto de entitlements desse build autorizado, preservando as permissões existentes. Assinar com o perfil correto; conferir o entitlement no app resultante e a disponibilidade real do serviço.
4. Validar uma resposta PCC real, erros de rede/cota e indisponibilidade, sem confundir presença da chave com acesso concedido. Manter os testes físicos de áudio suspensos até o usuário retomá-los.

Nenhuma chave/certificado/perfil foi criado, nenhum pedido foi enviado à Apple e a assinatura do 115 não foi alterada nesta conferência. Este documento é procedimento de ativação, não confirmação de capacidade entregue.

## Atualização após acesso à conta — 04/11/2026

A conta foi consultada no Safari, na equipe JZ8TU3BZ38. O usuário confirmou aceitação do contrato pendente; os recursos de certificados/IDs/perfis ficaram acessíveis. A lista não continha com.sieghart.app. O registro foi preparado e bloqueado pela revisão automática por exigir autorização explícita para um App ID permanente; o usuário então recusou o registro porque considera mudar o nome para Chomp. Nenhum identificador, perfil ou certificado foi criado. A concessão PCC ainda não foi confirmada; uma busca vazia na lista de capacidades padrão não comprova recusa da conta.

Configuração local opt-in preparada: Sieghart/Sieghart.PrivateCloud.entitlements inclui PCC e preserva as permissões de áudio/calendário/automação; Configuration/PrivateCloud.xcconfig exige perfil e identidade explícitos e herda o identificador do produto. Esse arquivo não participa do build padrão e não foi usado no app instalado. A configuração não concede acesso ao serviço. A escolha de nome e autorização para registro permanecem pendentes. Testes físicos de áudio foram autorizados pelo usuário em 03/11, substituindo o adiamento anterior.

Build padrão atual em 04/11: 116 instalado para correção de voz; o xcconfig PCC não foi aplicado. Registro continua pendente da escolha de nome e autorização; concessão e perfil PCC não confirmados. A evidência estática do 115 acima permanece histórica.


## Decisão Chomp — 05/11/2026

Chomp é o nome instalado no build 119. A proposta `com.chompindev.chomp` foi rejeitada pelo usuário por remeter à conta pessoal do Instagram. A distribuição aguarda outro identificador. A cópia de desenvolvimento usa `com.sieghart.app`. O caminho escolhido é confirmar elegibilidade no Small Business Program, preparar migração e registro, solicitar a capacidade gerenciada e validar pelo TestFlight interno para Mac. [Plano e critérios](chomp-heyclicky-closeout-2026-11-05.md#identidade-e-private-cloud-compute).


## Conferência HeyChomp 120 — 05/11/2026

HeyChomp é o aplicativo e Chomp é o antigo Sieg. O build 120 instalado mantém o ID de desenvolvimento `com.sieghart.app`. A extração da assinatura em arm64 e x86_64 confirmou a ausência de PCC. A configuração opt-in permanece preparada. O nome novo não escolhe nem registra um identificador de distribuição. Ainda faltam confirmação de elegibilidade, concessão da Apple, perfil correspondente e resposta real em distribuição de teste. O diagnóstico independente de AFM 3 Core ainda retornou `modelNotReady`.

O usuário indicou `com.HeyChomp.app` como identificador desejado para a futura solicitação do Private Cloud Compute. Pediu adiar a troca do build de desenvolvimento enquanto o ID atual não impedir os testes locais. Nenhum App ID ou pedido de concessão foi enviado nesta rodada.
