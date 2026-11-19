import SwiftUI

/// Escolha do ícone do app: o Chomp é o padrão e qualquer agente pode aparecer.
///
/// Muda só o ícone. O Chomp continua sendo o companheiro principal do app;
/// a equipe não é um seletor de avatares para substituí-lo (ver `Sieghart/README.md`).
@MainActor
@Observable
final class AppIconPickerViewModel {
    private let service: any AppIconService
    private(set) var selected: Agent
    private(set) var isApplying = false
    var errorMessage: String?

    let options = Agent.allCases

    init(service: any AppIconService) {
        self.service = service
        let current = service.currentIconName
        selected = Agent.allCases.first { $0.alternateIconName == current } ?? .chomp
    }

    var isAvailable: Bool { service.supportsAlternateIcons }

    func isSelected(_ agent: Agent) -> Bool { agent == selected }

    func select(_ agent: Agent) async {
        guard agent != selected, !isApplying else { return }
        isApplying = true
        defer { isApplying = false }
        do {
            try await service.setIcon(named: agent.alternateIconName)
            withAnimation(Motion.feedback) { selected = agent }
        } catch {
            errorMessage = "Não deu para trocar o ícone agora."
        }
    }
}
