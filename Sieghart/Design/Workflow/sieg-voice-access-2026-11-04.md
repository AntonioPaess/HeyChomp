# Recuperação de permissões de voz — 04/11/2026

## Reprodução e correção

No build 115, a prévia mudou para Parar prévia e voltou a Ouvir prévia sem erro/crash visível. Falar ficou em Checking microphone and speech access; Cancelar restaurou o estado inativo. Não houve transcrição de uma frase conhecida nem validação acústica humana.

SpeechAuthorizationBridge e o pedido de microfone aguardavam callback sem prazo. Agora o chamador termina em até 20 segundos por etapa, pode ser cancelado e recebe uma mensagem específica com destino para Ajustes. O callback nativo tardio/duplicado é descartado após a primeira resolução. O sistema operacional pode manter seu próprio pedido de autorização; a correção não concede permissões nem cancela o diálogo do macOS. NativeVoiceCapture e SpeechAnalyzerPipeline usam os mesmos bridges. ActivationController acompanha a Task de preparação para cancelá-la/substituí-la; conversa contínua conserva a falha para oferecer recuperação.

Mensagens de estado/erro na tela Ativação usam localização e um botão abre Microfone ou Reconhecimento de Fala conforme a etapa. Não foi removida a checagem de autorização.

## Verificação

Seleção dirigida do Complete, callbacks e voice-integration: **125 funções / 176 invocações aprovadas**, fontes estáveis, sem seletores ausentes/inesperados e 195/195 fontes de produção instrumentadas. Inclui callback fora da main thread, ausência de callback, cancelamento, cancelamento anterior ao pedido e entrega tardia/duplicada para fala/microfone. Os contratos usam requesters injetados, sem pedir autorização ao macOS ou gravar áudio. [Resultado](evidence/sieg-voice-access-2026-11-04/verification.json).

Build **116** padrão universal instalado e aberto em /Applications/Sieghart.app. A primeira compilação foi interrompida após ausência de progresso observável e saiu com erro interno; a compilação em pasta nova passou. O primeiro encerramento não ocorreu porque o auxiliar em /tmp havia sido apagado; ele foi recriado e a atualização concluída normalmente. O guard confirmou retomada do Keep Awake ativo e liberou a proteção temporária. Não foi aplicado o xcconfig PCC. [Estado instalado](evidence/sieg-voice-access-2026-11-04/deployment-state.json).

No reteste, com a janela trazida à frente, o app chegou a Escutando e depois voltou ao botão Falar, sem crash visível. Não houve frase conhecida transcrita nem resposta por voz validada. Essa observação não demonstra qualidade acústica, comportamento de todos os dispositivos ou que o prazo tenha sido exercitado pelo macOS; o prazo e callbacks tardios foram verificados nos contratos. Áudio físico autorizado pelo usuário em 03/11; permissão real, fala conhecida, AirPods, atalho e naturalidade não estão aceitos pelos contratos.

## Apple Cloud e nome

Conta consultada e contrato resolvido pelo usuário. Não há App ID específico do produto na lista observada; tentativa de registro foi bloqueada pela revisão automática e o usuário recusou autorizar o identificador por estar escolhendo o novo nome. Nada foi registrado. Configuração PCC opt-in preparada localmente, sem mudar a assinatura instalada. Concessão PCC/perfil ainda não confirmados. Não registrar nome/ID alternativo por conta própria.
