import SwiftUI

/// Conversa com o Chomp.
///
/// Enviar só acrescenta o balão da pessoa e um aviso de que o protótipo não
/// gera respostas. Respostas prontas fingindo inferência são proibidas no
/// projeto (ver `CLAUDE.md`).
@MainActor
@Observable
final class ChatViewModel {
    private(set) var conversation: Conversation
    let suggestions: [String]
    var draft = ""

    init(data: any DataSource = MockDataSource(), conversationID: Conversation.ID? = nil) {
        conversation = data.conversation(id: conversationID)
        suggestions = data.chatSuggestions
    }

    var title: String { "Chomp" }
    var subtitle: String { "Com a equipe" }
    var messages: [ChatMessage] { conversation.messages }

    func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        // Sai o "digitando" e entra a mensagem da pessoa, seguida do aviso.
        conversation.messages.removeAll { if case .typing = $0.kind { true } else { false } }
        conversation.messages.append(ChatMessage(id: UUID().uuidString, kind: .user, text: text))
        conversation.messages.append(ChatMessage(id: UUID().uuidString, kind: .notice, text: "Protótipo sem conexão: nenhuma resposta é gerada."))
    }

    func useSuggestion(_ suggestion: String) {
        draft = suggestion
    }
}
