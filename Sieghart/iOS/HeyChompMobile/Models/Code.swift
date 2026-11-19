import Foundation

/// Tarefa de código acompanhada pela Ada.
struct CodeTask: Identifiable, Hashable, Sendable {
    enum State: String, Hashable, Sendable {
        case review = "Revisar"
        case inProgress = "Em andamento"
        case done = "Feito"
    }

    let id: String
    var title: String
    var project: String
    var state: State
    var updated: String
}

/// Projeto (repositório) que a Ada conhece.
struct CodeProject: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var branch: String
    var pending: Int
}

/// Trecho de código guardado numa conversa.
struct CodeSnippet: Hashable, Sendable {
    var language: String
    var title: String
    var code: String
}
