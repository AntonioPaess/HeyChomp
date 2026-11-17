import SwiftUI

/// Constrói cada tela com a sua ViewModel.
///
/// É o único lugar que liga uma `Route` a uma View. As telas pedem navegação ao
/// `AppRouter` e não constroem as outras telas.
enum ScreenFactory {
    @MainActor @ViewBuilder
    static func view(for route: Route, data: any DataSource) -> some View {
        switch route {
        case .chat(let id):
            ChatView(viewModel: ChatViewModel(data: data, conversationID: id))
        case .conversations:
            ConversationsView(viewModel: ConversationsViewModel(data: data))
        case .team:
            TeamView(viewModel: TeamViewModel(data: data))
        case .agent(let agent):
            agentView(agent, data: data)
        case .settings:
            SettingsView(viewModel: SettingsViewModel(data: data))
        case .widgetGallery:
            WidgetGalleryView(viewModel: WidgetGalleryViewModel(data: data))
        case .pairMac:
            PairMacView()
        case .appIcon:
            AppIconPickerView(viewModel: AppIconPickerViewModel(service: SystemAppIconService()))
        }
    }

    @MainActor @ViewBuilder
    static func view(for sheet: Sheet, data: any DataSource) -> some View {
        switch sheet {
        case .attachments:
            AttachmentsSheet(viewModel: ToniViewModel(data: data))
        case .pairMac:
            NavigationStack { PairMacView() }
        }
    }

    /// Cada agente tem a própria tela de trabalho.
    @MainActor @ViewBuilder
    static func agentView(_ agent: Agent, data: any DataSource) -> some View {
        switch agent {
        case .chomp: ChompView(viewModel: ChompViewModel(data: data))
        case .rita: RitaFocusView(viewModel: RitaFocusViewModel(data: data))
        case .ada: AdaCodeView(viewModel: AdaCodeViewModel(data: data))
        case .gantt: GanttView(viewModel: GanttViewModel(data: data))
        case .elinor: ElinorFinanceView(viewModel: ElinorFinanceViewModel(data: data))
        case .toni: ToniView(viewModel: ToniViewModel(data: data))
        }
    }
}
