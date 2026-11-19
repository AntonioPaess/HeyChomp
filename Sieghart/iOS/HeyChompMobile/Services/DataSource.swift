import Foundation

/// Única fonte de dados das ViewModels.
///
/// No protótipo, só `MockDataSource` implementa este protocolo. Quando houver
/// integração real (pareamento com o Mac, EventKit e afins), basta criar outra
/// implementação e injetá-la em `AppEnvironment`, sem mexer nas telas.
///
/// Os membros são síncronos de propósito: o protótipo não tem rede nem espera.
/// Uma implementação real deve virar `async` aqui e nas ViewModels.
protocol DataSource: Sendable {
    var userName: String { get }
    var todayLabel: String { get }

    // Equipe
    var teamStatus: [AgentStatus] { get }
    var suggestion: ChompSuggestion { get }
    var permissions: [PermissionItem] { get }

    // Conversas
    var conversations: [Conversation] { get }
    var chatSuggestions: [String] { get }
    var voiceTranscript: String { get }

    // Gantt
    var weekDays: [WeekDay] { get }
    var todayEvents: [CalendarEvent] { get }
    var journal: [JournalEntry] { get }

    // Rita
    var focusPresets: [FocusPreset] { get }
    var focusSessions: [FocusSession] { get }
    var focusSnapshot: FocusSnapshot { get }

    // Elinor
    var budget: BudgetSummary { get }
    var categories: [SpendingCategory] { get }
    var transactions: [Transaction] { get }
    var bills: [UpcomingBill] { get }

    // Ada
    var codeProjects: [CodeProject] { get }
    var codeTasks: [CodeTask] { get }
    var snippet: CodeSnippet { get }

    // Toni
    var clipboard: [ClipboardItem] { get }
    var recentFiles: [FileItem] { get }
    var audioOutputs: [AudioOutput] { get }
    var captureActions: [CaptureAction] { get }

    // Chomp
    var recentHandoffs: [Handoff] { get }
}

extension DataSource {
    func status(of agent: Agent) -> AgentStatus {
        teamStatus.first { $0.agent == agent }
            ?? AgentStatus(agent: agent, activity: .idle, detail: "Livre", badge: "Livre")
    }

    func conversation(id: Conversation.ID?) -> Conversation {
        conversations.first { $0.id == id } ?? conversations[0]
    }
}
