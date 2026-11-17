import SwiftUI

/// Código da Ada: projetos, tarefas e um trecho guardado.
@MainActor
@Observable
final class AdaCodeViewModel {
    let status: AgentStatus
    let projects: [CodeProject]
    let tasks: [CodeTask]
    let snippet: CodeSnippet

    var filter: CodeTask.State?

    init(data: any DataSource = MockDataSource()) {
        status = data.status(of: .ada)
        projects = data.codeProjects
        tasks = data.codeTasks
        snippet = data.snippet
    }

    var visibleTasks: [CodeTask] {
        guard let filter else { return tasks }
        return tasks.filter { $0.state == filter }
    }

    static let filters: [(title: String, state: CodeTask.State?)] = [
        ("Todas", nil), ("Revisar", .review), ("Em andamento", .inProgress), ("Feitas", .done),
    ]
}
