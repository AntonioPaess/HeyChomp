# Chomp 119 — renomeação e aceite silencioso

A cópia de desenvolvimento foi renomeada para **Chomp** em 05/11/2026. O [projeto](../../Chomp.xcodeproj), os targets Chomp/ChompTests, os esquemas Chomp/Chomp-Checks e os planos Chomp-Fast/Chomp-Complete usam a marca. Os scripts verificam, atualizam e lançam /Applications/Chomp.app. A cópia Sieghart 118 foi preservada no backup descrito na evidência de instalação. O diretório de fontes e a identidade com.sieghart.app continuam como compatibilidade local. O histórico e a biblioteca tinham os mesmos hashes antes e depois da instalação. O GitHub fica para a renomeação do repositório em etapa própria.

O identificador definitivo para Apple está em aberto após o usuário rejeitar a proposta ligada ao Instagram. O build usa assinatura de desenvolvimento e a configuração padrão. O Private Cloud continua condicionado ao ID definitivo, à concessão gerenciada e ao perfil correspondente.

| Verificação | Resultado |
| --- | --- |
| Build e assinatura | Universal arm64/x86_64. Chomp.app em /Applications, nome e executável Chomp, PID da cópia instalada conferido. |
| Complete | 491 funções e 1383 invocações aprovadas. |
| Fast | 422 funções e 1282 invocações aprovadas. |
| Keep Awake real | Comando digitado por 3 minutos com tela ligada. Recibo exibido e asserção PreventUserIdleDisplaySleep confirmada no macOS. Sessão de teste encerrada. |
| Clima real | Recife, Pernambuco, e a continuação “E em Lisboa?” retornaram os locais corretos e leitura Open-Meteo. |
| Gravação de tela | A autorização antiga rejeitou a assinatura atual. Depois de habilitar Chomp na lista de tela, o app devolveu OCR real. O teste de leitura pediu TextEdit e recebeu texto de outra janela/monitor. O alvo ainda requer correção e aceite. |
| Recorte | O seletor nativo abriu em modo silencioso e foi cancelado. No app instalado, a imagem sintética importada reconheceu exatamente RECORTE ALFA: OCEANO 1963. A seleção física ainda requer aceite. |
| Diagramas reais | CPMapTemplate e MVVM chegaram ao gerador. O diagnóstico local retornou modelNotReady para AFM 3 Core. Ambos mostraram aviso de indisponibilidade e não produziram um diagrama. |
| Som e microfone | Suspensos. O seletor nativo de região é iniciado com captura silenciosa. |

Os planos usaram fixtures de áudio/voz. Para a próxima rodada, validar os três marcadores do documento na janela certa e o recorte físico só da linha ALFA. Repetir os diagramas quando o modelo estiver disponível. A base ainda exige aceite de tela, desenho e voz antes da integração na main.

- [Instalação](evidence/chomp-rename-2026-11-05/deployment.json)
- [Complete](evidence/chomp-rename-2026-11-05/complete-verification.json)
- [Fast](evidence/chomp-rename-2026-11-05/fast-verification.json)
- [Aceite real e limites](evidence/chomp-rename-2026-11-05/live-acceptance.json)

## Chats

- [Chomp — Design e movimento](codex://threads/01a1ac06-68f4-7472-b960-c27b463d5960). Briefing de todas as telas e widgets, vídeo do Claude e coordenação com [Sieg — Avatares e animações](codex://threads/01a1434b-174e-72c3-bd7f-0094220f1da6). O vídeo de 3,17 s é referência de ritmo, virada e interação com a borda. A estética pixelada combina com a Ada.
- [Chomp — REA e integração OpenBot](codex://threads/01a1ac07-2400-7833-82c8-2c225048b517). OpenBot primeiro, com licença e interface de integração verificadas por versão. Hidden Bar, Raycast e Token Meter depois. Ambos aguardam a execução com um agente por vez.
