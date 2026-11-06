# Comparação visual e fechamento do build 110 — 29/10/2026

O build **110** universal está instalado em `/Applications/Sieghart.app`. A comparação solicitada usa telas preservadas e renders dos componentes de produção, sem redesenhar a interface para criar diferenças.

## Imagens lado a lado

- [Home com marcações](evidence/sieg-design-comparison-2026-10-29/comparacao-home.png).
- [Aparência com marcações](evidence/sieg-design-comparison-2026-10-29/comparacao-aparencia.png).
- [Origem e hashes das 34 imagens utilizadas/preservadas](evidence/sieg-design-comparison-2026-10-29/provenance.json).
- [Catálogo atual: 16 abas, claro e escuro](evidence/sieg-design-comparison-2026-10-29/catalog/catalog.json).

O lado antigo vem de `Design/Concepts/app-overview-preview.png` e `app-appearance-preview.png`, preservados no commit `524c669` de **07/10**. O lado atual foi renderizado em **28/10**, com as views SwiftUI do código do 110 e dados isolados. Não são capturas de conversas reais. As imagens originais estão inteiras, ajustadas proporcionalmente e sem recorte. Os únicos elementos acrescentados são a composição, os títulos e os marcadores explicativos.

É uma comparação da **evolução geral**, não um diff visual do 108 para o 110. A Home central com equipe/conversas já existia nas evidências de 22/10. Agora a comparação permite ver navegação agrupada, conversas/biblioteca, identidade fixa do Sieg e especialistas em lugar do seletor antigo de personagens intercambiáveis.

Composição reproduzível: `swift -module-cache-path /tmp/sieg-comparison-module-cache evidence/sieg-design-comparison-2026-10-29/render-comparisons.swift evidence/sieg-design-comparison-2026-10-29`, executado a partir desta pasta. Foram conferidas visualmente as duas pranchas, a Home e Aparência atuais e suas duas fontes históricas. Texto das anotações tem verificação de altura no compositor. As demais 28 imagens do catálogo estão preservadas, mas não representam aceite individual de todos os estados.

## Correções incorporadas no 110

- Keep Awake verifica se a própria asserção nativa permanece efetivamente mantida, recupera a proteção perdida sem reiniciar o prazo e informa erro se não consegue confirmar a aquisição. Retoma também quando a tela acorda ou a sessão fica ativa. O cartão deixa de atribuir todo estado sem proteção às condições configuradas.
- Leitura digitada genérica, além da rota nominal da Ada, descarta captura/resposta atrasada de um turno cancelado. Fonte vazia/negada não vira uma explicação inventada.
- Contraste do editor acompanha o tema; rótulo acessível acompanha idioma/personagem sem perder rascunho. Alternador, seleção de tema e ajuda do modelo usam localização adequada. O nome apresentado é **Sieg**, preservando o identificador persistido `sig`.
- Atualizações conferem time e identidade de assinatura: depois de instalada uma identidade de desenvolvimento, o instalador recusa retornar acidentalmente a uma assinatura ad hoc ou a outro time. A migração do antigo ad hoc foi permitida. Não foram criadas credenciais nem alterada a confiança do sistema.

## Evidência e limites

[Resultado dirigido e metadados do 110](evidence/sieg-reliability-build110-2026-10-28/README.md): **193 funções / 594 invocações aprovadas**, 195/195 fontes instrumentadas e fontes estáveis. Inclui uma asserção nativa curta pertencente ao próprio teste, sem iniciar sessão do usuário. Essa seleção do plano Complete não é o plano inteiro. O último plano rápido completo continua sendo o de 27/10, **380/1156**.

Build universal compilado com sucesso. Assinatura pessoal Apple Development do time JZ8TU3BZ38 foi verificada na instalação; a primeira identidade escolhida foi recusada pelo Xcode e não foi contornada. Guard confirmou a retomada antes de liberar a proteção temporária, preservando o término **28/10 às 23:55:47 em Recife**. É uma observação histórica; não afirmar que o Keep Awake está ativo no dia 29.

O ensaio de tela real do 108 chegou à recuperação de permissão da cópia canônica, sem ler a classe ou gerar um diagrama validado. O usuário depois orientou continuar no design/código; não conceder permissões nem repetir perguntas automaticamente. Leitura real, tradução e qualidade factual/visual de diagramas continuam pendentes. O histórico posterior de energia indicou suspensão por fechamento da tampa nas observações anteriores: não tratar essa evidência como demonstração de repouso ocioso apesar de uma asserção mantida.

Não houve teste de microfone, áudio, AirPods, atalho físico, conta real ou nova permissão. O catálogo é estático: não valida animações, teclado, VoiceOver ou todas as combinações de conteúdo/erros. Produto e auditoria HIG ainda não estão declarados completos. Sem agente/worktree adicional, commit ou push.

Próximo passo: revisar estados preenchidos, erros e painéis longos, preservando personagens aprovados; quando o usuário decidir retomar permissões, testar classe conhecida → leitura → explicação e diagrama no app real.
