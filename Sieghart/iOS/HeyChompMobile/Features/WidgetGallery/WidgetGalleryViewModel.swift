import SwiftUI

/// Dados da galeria de widgets.
///
/// As views em `Widgets/` recebem só valores simples, para poderem ir depois
/// para uma extensão WidgetKit sem depender das ViewModels do app.
@MainActor
@Observable
final class WidgetGalleryViewModel {
    enum Section: String, CaseIterable, Identifiable {
        case home = "Início"
        case lock = "Bloqueio"
        case live = "Ao vivo"
        var id: String { rawValue }
    }

    var section: Section = .home
    let team: [AgentStatus]
    let events: [CalendarEvent]
    let focus: FocusSnapshot
    let clipboard: [ClipboardItem]
    let userName: String

    init(data: any DataSource = MockDataSource()) {
        team = data.teamStatus
        events = data.todayEvents
        focus = data.focusSnapshot
        clipboard = data.clipboard
        userName = data.userName
    }

    var nextEvent: CalendarEvent? { events.first(where: \.isNext) }
    var agendaPreview: [CalendarEvent] { events.filter { !$0.isPast || $0.time == "13:30" }.prefix(3).map { $0 } }

    /// Etapas recentes do Chomp, da mais antiga à atual.
    let chompSteps = ["Agenda conferida", "Foco marcado", "Montando seu resumo"]
}
