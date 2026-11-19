import SwiftUI

/// Estado global do protótipo: primeiro uso, nome e aparência.
///
/// Fica só na memória. Fechar o app volta ao primeiro uso, a não ser que
/// `-startScreen` diga outra coisa (ver `LaunchOptions`).
@MainActor
@Observable
final class AppModel {
    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: "Sistema"
            case .light: "Claro"
            case .dark: "Escuro"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    /// Fonte de dados injetada em todas as ViewModels.
    let data: any DataSource
    var hasCompletedOnboarding = false
    var userName: String
    var appearance: Appearance = .system

    init(data: any DataSource) {
        self.data = data
        self.userName = data.userName
    }

    func completeOnboarding(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { userName = trimmed }
        withAnimation(Motion.page) { hasCompletedOnboarding = true }
    }

    func restartOnboarding() {
        withAnimation(Motion.page) { hasCompletedOnboarding = false }
    }
}
