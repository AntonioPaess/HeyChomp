# Arquitetura do protótipo iOS

## Princípios

1. **MVVM estrito.** Cada tela tem uma `View` (só layout) e uma `ViewModel` (estado e ações de interface). Models são dados puros.
2. **Uma fonte de dados.** As ViewModels só leem dados pelo protocolo `DataSource`. No protótipo, a única implementação é `MockDataSource`.
3. **Navegação centralizada.** As telas pedem navegação ao `AppRouter` e nunca constroem outras telas. Quem liga uma rota a uma tela é a `ScreenFactory`.
4. **Sem lógica escondida.** Nenhum timer, rede, persistência ou API de sistema. As ações só mudam estado de tela.
5. **Mesmo vocabulário visual do Mac.** Os tokens e componentes repetem o `CompanionStyle` do app macOS.

## Camadas

```
            ┌──────────────┐  lê   ┌──────────────┐
  View  ──▶ │  ViewModel   │ ────▶ │  DataSource  │ ◀── MockDataSource (hoje)
 (layout)   │ @Observable  │       │  (protocolo) │ ◀── implementação real (depois)
            └──────┬───────┘       └──────────────┘
                   │ usa
                   ▼
               Models (structs Sendable)

  View ──▶ AppRouter (push, sheet, voz) ──▶ RootView/ScreenFactory constroem a próxima tela
  View ──▶ AppModel (nome, tema, primeiro uso)
```

### App/

| Arquivo | Papel |
|---|---|
| `HeyChompMobileApp.swift` | `@main`. Cria `AppModel`, `AppRouter` e `MockDataSource` e aplica as `LaunchOptions`. |
| `AppModel.swift` | Estado global na memória: primeiro uso concluído, nome e aparência. |
| `AppRouter.swift` | `Route` (pilha), `Sheet` (folhas) e a sessão de voz em tela cheia. |
| `RootView.swift` | Mostra o primeiro uso ou o `NavigationStack` e apresenta folhas e voz. |
| `ScreenFactory.swift` | O único `switch` de rota para tela; injeta a `DataSource` em cada ViewModel. |
| `LaunchOptions.swift` | `-startScreen` e `-appearance` para revisão e capturas. |
| `PreviewSupport.swift` | `.previewEnvironment()` para as prévias do Xcode (só em DEBUG). |

### ViewModels

- `@MainActor @Observable final class`, criadas pela `ScreenFactory` (ou pela tela pai) e guardadas pela View em `@State`:

  ```swift
  struct GanttView: View {
      @State private var viewModel: GanttViewModel
      init(viewModel: GanttViewModel) { _viewModel = State(initialValue: viewModel) }
  }
  ```

- Recebem `data: any DataSource` no `init`, com `MockDataSource()` como padrão para as prévias.
- Expõem textos já prontos para a tela (`ringLabel`, `caption`, `summary`) e ações curtas (`toggle`, `advance`, `send`). A View não monta regra nenhuma.

### Models/

Structs e enums `Sendable` sem dependência de SwiftUI. Datas, horários e valores em reais são **texto fixo**, porque o protótipo não calcula nada. Na implementação real, troque por `Date` e `Decimal` com formatadores na ViewModel.

`Agent` descreve a equipe: nome, papel, descrição, recurso "em breve" e os nomes dos assets. O Chomp ainda usa a chave `sig` nos assets do Mac.

### DesignSystem/

| Item | Uso |
|---|---|
| `Theme.swift` | `Palette` (cores adaptativas), `Metrics`, `Typography` (números em SF Rounded) e `Motion`. |
| `Agent+Style.swift` | `tint` (cor de marca do agente) e `symbol`. A cor do agente **nunca** vai em texto. |
| `PerchedCard` / `PeekImage` | Cartão com o dono espiando por cima. As mãos do asset ficam a cerca de 74% da altura, então o personagem sobe 47% da largura. |
| `SpeechBubble`, `MessageBubble` | Balão do Chomp com rabinho e balões da conversa. |
| `ChompPillStyle`, `SoonPill`, `StatusPill` | Pílulas de ação, de "em breve" e de status. |
| `AgentAvatar`, `AgentDisc`, `TypingBadge`, `ChompMark` | Avatar com anel e status, rosto com brilho (v2), selo de "digitando" e marca do Chomp. |
| `ProgressRing`, `ProgressTrack`, `WaveformBars`, `TypingDots`, `AgentGlow` | Indicadores e fundos. |
| `SectionHeader`, `InfoRow`, `ComingSoonCard`, `AgentHeader` | Seções, linhas de lista, recurso futuro e cabeçalho das telas de agente. |
| `AskChompBar`, `MessageComposer`, `MicButton` | Barra da tela inicial e campo da conversa. |

Regra visual da mistura v1 + v2: **quem fala ou trabalha aparece de rosto** (`AgentDisc`). **Em conteúdo com dono, o dono espia** (`PerchedCard`).

## Ícone do app

- O ícone principal `AppIcon` vem do catálogo compartilhado com o Mac: um único `.appiconset` com as entradas do iOS (1024 px em claro, escuro e tingido) e do macOS (16 a 512 pt, na grade de 824 px, **só a versão escura**).
- Os ícones alternativos estão listados em `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`. `Agent.alternateIconName` liga cada agente ao seu conjunto.
- `Services/AppIconService.swift` isola a API do sistema: a ViewModel (`AppIconPickerViewModel`) recebe o serviço pelo protocolo, e as prévias usam `PreviewAppIconService`.
- O app não consegue carregar um appiconset como `Image`, por isso a tela de escolha usa as miniaturas `IconPreview-<agente>` (claro e escuro).
- Para mudar a arte, edite `Tools/app-icon/generate_app_icons.py` e rode-o de novo. Ele reescreve todos os conjuntos e a prancha de conferência.
- No Mac, o ícone fica sempre o Chomp. O app é `LSUIElement` (não aparece no Dock), e trocar o ícone em execução no macOS só afetaria o Dock.

## Projeto Xcode

- O projeto é separado do `HeyChomp.xcodeproj` do Mac, que não foi alterado.
- `HeyChompMobile/` é uma **pasta sincronizada**: arquivos novos entram no alvo sem editar o `project.pbxproj`.
- Recursos: `Resources/Assets.xcassets` (ícones alternativos, miniaturas e cor de destaque) e o catálogo compartilhado do Mac, por referência, que traz o `AppIcon` principal.
- Bundle `com.heychomp.ios`, versão 0.1, só iPhone, só retrato.
- **Identificadores da família HeyChomp** (padronizados em 17/11/2026), todos com o mesmo prefixo para facilitar App Groups e Keychain compartilhado:

  | Produto | Identificador |
  |---|---|
  | App do Mac | `com.heychomp.mac` (antes `com.sieghart.app`) |
  | App do iPhone | `com.heychomp.ios` |
  | Extensão de widgets do iPhone (futura) | `com.heychomp.ios.widgets` |
  | Testes do Mac | `com.heychomp.mac.tests` |
  | App Group (quando houver) | `group.com.heychomp` |
- Os textos são literais em pt-BR (`developmentRegion = pt-BR`, `SWIFT_EMIT_LOC_STRINGS = YES`). Quando houver outro idioma, gere o String Catalog a partir deles.

## Como adicionar uma tela

1. Crie `Features/<Nome>/<Nome>ViewModel.swift` (`@MainActor @Observable`, `init(data: any DataSource = MockDataSource())`).
2. Crie `Features/<Nome>/<Nome>View.swift` com a ViewModel em `@State` e um `#Preview` usando `.previewEnvironment()`.
3. Se a tela precisar de dados novos, acrescente o modelo em `Models/`, o membro no protocolo `DataSource` e o valor fictício em `MockDataSource`.
4. Acrescente um caso em `Route` (ou `Sheet`) e o `switch` correspondente em `ScreenFactory`.
5. Opcional: um valor de `-startScreen` em `LaunchOptions` e na lista do `Tools/capture-screens.sh`.

## Caminho para o app real

1. **Dados:** escrever implementações reais de `DataSource` (EventKit para o Gantt, pareamento com o Mac etc.), torná-lo `async` e passar a carregar na ViewModel com estados de carregamento e erro.
2. **Código compartilhado:** levar `Models/`, a `Palette` e os componentes neutros para um Swift Package usado também pelo Mac. Isso exige separar `NSColor`/`NSWorkspace` do `CompanionStyle`.
3. **Widgets:** criar a extensão WidgetKit reaproveitando as views de `Features/WidgetGallery/Widgets/` (`WidgetFrame` vira `containerBackground`; os acessórios viram as famílias `.accessory*`) e um alvo de Live Activity com `ActivityKit`.
4. **Voz:** só com autorização explícita para testar microfone, seguindo as regras do `CLAUDE.md`.
5. **Integração ao projeto principal:** se o iOS for para o mesmo `.xcodeproj` do Mac, fazer num PR curto e isolado, porque aquele pbxproj não usa grupos sincronizados.
