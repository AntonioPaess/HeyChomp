import Foundation

/// Estado de um agente num momento, como aparece na fileira da equipe e nos widgets.
struct AgentStatus: Identifiable, Hashable, Sendable {
    enum Activity: Hashable, Sendable {
        /// Trabalhando agora. Mostra o selo de "digitando" e o ponto menta.
        case working
        /// Disponível, sem tarefa.
        case idle
    }

    var agent: Agent
    var activity: Activity
    /// Frase curta do que está fazendo ("Foco · 18 min").
    var detail: String
    /// Rótulo da pílula de status ("Em foco", "Livre", "1h20").
    var badge: String

    var id: Agent { agent }
    var isWorking: Bool { activity == .working }
}
