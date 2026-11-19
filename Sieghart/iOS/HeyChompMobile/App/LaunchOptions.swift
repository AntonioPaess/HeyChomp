import Foundation

/// Opções de lançamento para revisar telas sem passar pelo primeiro uso.
///
/// Os argumentos `-chave valor` caem em `UserDefaults` automaticamente:
///
///     xcrun simctl launch booted com.heychomp.ios -startScreen rita -appearance dark
///
/// `-startScreen`: onboarding (padrão), home, chat, conversations, voice, team,
/// chomp, rita, ada, gantt, elinor, toni, settings, widgets, pair, icon.
/// `-appearance`: system (padrão), light, dark.
struct LaunchOptions {
    var startScreen: String?
    var appearance: String?

    static var current: LaunchOptions {
        let defaults = UserDefaults.standard
        return LaunchOptions(
            startScreen: defaults.string(forKey: "startScreen"),
            appearance: defaults.string(forKey: "appearance")
        )
    }

    @MainActor
    func apply(to model: AppModel, router: AppRouter) {
        if let appearance, let value = AppModel.Appearance(rawValue: appearance) {
            model.appearance = value
        }
        guard let startScreen, startScreen != "onboarding" else { return }
        model.hasCompletedOnboarding = true

        if let agent = Agent(rawValue: startScreen) {
            router.path = [.team, .agent(agent)]
            return
        }
        switch startScreen {
        case "chat": router.path = [.chat(nil)]
        case "conversations": router.path = [.conversations]
        case "voice": router.isVoiceSessionPresented = true
        case "team": router.path = [.team]
        case "settings": router.path = [.settings]
        case "widgets": router.path = [.settings, .widgetGallery]
        case "pair": router.path = [.settings, .pairMac]
        case "icon": router.path = [.settings, .appIcon]
        default: break
        }
    }
}
