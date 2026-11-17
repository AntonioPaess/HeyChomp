import SwiftUI

/// Primeiro uso em três passos: nome, equipe e permissões.
///
/// As permissões são só interruptores visuais. O protótipo não pede acesso a
/// microfone, calendário nem notificações.
@MainActor
@Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable {
        case welcome, team, permissions
    }

    var step: Step = .welcome
    var name = ""
    var enabledPermissions: Set<PermissionItem.ID> = ["notifications", "calendar"]

    let team = Agent.allCases
    let permissions: [PermissionItem]

    init(data: any DataSource = MockDataSource()) {
        permissions = data.permissions
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var canContinue: Bool { step != .welcome || !trimmedName.isEmpty }

    var primaryTitle: String { step == .permissions ? "Começar" : "Continuar" }

    var teamTitle: String {
        trimmedName.isEmpty ? "Esta é a sua equipe." : "Prazer, \(trimmedName).\nEsta é a sua equipe."
    }

    /// Avança um passo. Retorna `true` quando o primeiro uso terminou.
    func advance() -> Bool {
        guard let next = Step(rawValue: step.rawValue + 1) else { return true }
        withAnimation(Motion.page) { step = next }
        return false
    }

    func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        withAnimation(Motion.page) { step = previous }
    }

    func isEnabled(_ permission: PermissionItem) -> Bool {
        enabledPermissions.contains(permission.id)
    }

    func toggle(_ permission: PermissionItem) {
        if enabledPermissions.contains(permission.id) {
            enabledPermissions.remove(permission.id)
        } else {
            enabledPermissions.insert(permission.id)
        }
    }
}
