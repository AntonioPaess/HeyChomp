import SwiftUI

/// Tela inicial: sugestão do Chomp, equipe, agenda de hoje e resumos.
@MainActor
@Observable
final class HomeViewModel {
    let todayLabel: String
    let team: [AgentStatus]
    let suggestion: ChompSuggestion
    let events: [CalendarEvent]
    let focus: FocusSnapshot
    let budget: BudgetSummary
    let codeTasks: [CodeTask]
    let clipboard: [ClipboardItem]

    /// "Agora não" esconde a sugestão até a próxima abertura.
    var isSuggestionDismissed = false

    init(data: any DataSource = MockDataSource()) {
        todayLabel = data.todayLabel
        team = data.teamStatus
        suggestion = data.suggestion
        events = data.todayEvents
        focus = data.focusSnapshot
        budget = data.budget
        codeTasks = data.codeTasks
        clipboard = data.clipboard
    }

    /// Saudação fixa da tarde (o protótipo não lê o relógio).
    func greeting(for name: String) -> String { "Boa tarde, \(name)" }

    /// Três eventos em volta do próximo: o anterior, o próximo e o seguinte.
    var agendaPreview: [CalendarEvent] {
        guard let index = events.firstIndex(where: \.isNext) else { return Array(events.prefix(3)) }
        let start = max(0, index - 1)
        return Array(events[start..<min(events.count, start + 3)])
    }

    var pendingCodeCount: Int { codeTasks.filter { $0.state != .done }.count }

    func dismissSuggestion() {
        withAnimation(Motion.page) { isSuggestionDismissed = true }
    }
}
