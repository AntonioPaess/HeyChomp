import Foundation

/// Sugestão proativa do Chomp no topo da tela inicial.
struct ChompSuggestion: Hashable, Sendable {
    var text: String
    var primaryAction: String
    var secondaryAction: String
    /// Agente que a ação principal abre.
    var target: Agent
}

/// Permissão pedida no primeiro uso. No protótipo, o interruptor é só visual.
struct PermissionItem: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var detail: String
    var symbol: String
    var owner: Agent
}
