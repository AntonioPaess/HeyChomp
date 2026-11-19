import SwiftUI

/// Ajustes: perfil, aparência, Mac, notificações por agente e sobre o protótipo.
///
/// Nome e aparência alteram o `AppModel` (só na memória). As notificações são
/// interruptores visuais.
@MainActor
@Observable
final class SettingsViewModel {
    var notifications: [Agent: Bool]
    var voiceShortcut = true
    let version = "0.1 (protótipo)"

    init(data: any DataSource = MockDataSource()) {
        notifications = Dictionary(uniqueKeysWithValues: Agent.allCases.map { ($0, $0 != .ada) })
    }

    func binding(for agent: Agent) -> Binding<Bool> {
        Binding(
            get: { self.notifications[agent] ?? false },
            set: { self.notifications[agent] = $0 }
        )
    }
}
