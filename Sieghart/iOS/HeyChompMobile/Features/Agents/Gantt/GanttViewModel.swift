import SwiftUI

/// Agenda e bullet journal do Gantt.
///
/// Marcar um item do diário só muda o estado na tela. O dia selecionado
/// também é visual: todos os dias mostram a mesma agenda fictícia.
@MainActor
@Observable
final class GanttViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case agenda = "Agenda"
        case journal = "Diário"
        var id: String { rawValue }
    }

    let status: AgentStatus
    let weekDays: [WeekDay]
    let events: [CalendarEvent]
    private(set) var journal: [JournalEntry]

    var tab: Tab = .agenda
    var selectedDay: WeekDay.ID = 17

    init(data: any DataSource = MockDataSource()) {
        status = data.status(of: .gantt)
        weekDays = data.weekDays
        events = data.todayEvents
        journal = data.journal
    }

    var nextEvent: CalendarEvent? { events.first(where: \.isNext) }

    var openTasks: Int { journal.filter { $0.kind == .task && $0.state == .open }.count }

    /// Alterna uma tarefa entre aberta e feita. Migradas, eventos e notas não mudam.
    func toggle(_ entry: JournalEntry) {
        guard entry.kind == .task, entry.state != .migrated,
              let index = journal.firstIndex(where: { $0.id == entry.id }) else { return }
        withAnimation(Motion.feedback) {
            journal[index].state = journal[index].state == .done ? .open : .done
        }
    }
}
