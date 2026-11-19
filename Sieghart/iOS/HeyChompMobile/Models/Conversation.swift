import Foundation

/// Uma conversa com o Chomp, com as mensagens e os repasses para a equipe.
struct Conversation: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    /// Texto exibido no histórico (fixo no protótipo, sem formatação de data).
    var timestamp: String
    var messages: [ChatMessage]
    /// Agentes que participaram (para os avatares do histórico).
    var participants: [Agent]

    var preview: String {
        messages.last(where: { $0.isText })?.text ?? ""
    }
}

/// Item da linha do tempo da conversa.
struct ChatMessage: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        /// Mensagem digitada ou falada pela pessoa.
        case user
        /// Resposta de um agente (normalmente o Chomp) num balão.
        case agent(Agent)
        /// Cartão de repasse: o Chomp pediu algo a um especialista.
        case handoff(Handoff)
        /// Indicador de "digitando".
        case typing(Agent)
        /// Aviso do sistema (por exemplo, que o protótipo não gera respostas).
        case notice
    }

    let id: String
    var kind: Kind
    var text: String

    var isText: Bool {
        switch kind {
        case .user, .agent: true
        default: false
        }
    }
}

/// Repasse do Chomp para um especialista, desenhado como cartão com o agente espiando.
struct Handoff: Hashable, Sendable {
    var agent: Agent
    /// Linha pequena de cima ("Gantt · lembrete criado").
    var caption: String
    var title: String
    var detail: String
}
