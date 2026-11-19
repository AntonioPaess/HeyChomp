import SwiftUI

/// Histórico de conversas com busca local.
@MainActor
@Observable
final class ConversationsViewModel {
    private let all: [Conversation]
    var query = ""

    init(data: any DataSource = MockDataSource()) {
        all = data.conversations
    }

    /// Filtra pelo título e pela última mensagem, sem diferenciar maiúsculas e acentos.
    var conversations: [Conversation] {
        let term = query.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return all }
        return all.filter {
            $0.title.localizedStandardContains(term) || $0.preview.localizedStandardContains(term)
        }
    }

    var isEmpty: Bool { conversations.isEmpty }
}
