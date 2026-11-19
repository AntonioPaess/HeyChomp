import SwiftUI

/// Perfil do Chomp: como ele distribui os pedidos e o que repassou por último.
@MainActor
@Observable
final class ChompViewModel {
    let status: AgentStatus
    let handoffs: [Handoff]
    let team: [AgentStatus]

    init(data: any DataSource = MockDataSource()) {
        status = data.status(of: .chomp)
        handoffs = data.recentHandoffs
        team = data.teamStatus.filter { $0.agent != .chomp }
    }

    /// Passos de como um pedido anda pela equipe.
    let flow: [(symbol: String, title: String, detail: String)] = [
        ("waveform", "Você pede", "Por voz ou texto, no app, no widget ou na tela bloqueada."),
        ("arrow.triangle.branch", "O Chomp decide", "Escolhe quem da equipe resolve, ou responde sozinho."),
        ("person.2", "A equipe faz", "Cada especialista trabalha na sua área e devolve o resultado."),
        ("text.bubble", "Ele te conta", "A resposta volta num balão, com o cartão do que foi feito."),
    ]
}
