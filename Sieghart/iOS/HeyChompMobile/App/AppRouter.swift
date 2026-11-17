import SwiftUI

/// Destinos empilhados no `NavigationStack` a partir da tela inicial.
enum Route: Hashable {
    /// Conversa com o Chomp. `nil` abre a conversa mais recente.
    case chat(Conversation.ID?)
    case conversations
    case team
    case agent(Agent)
    case settings
    case widgetGallery
    case appIcon
    case pairMac
}

/// Telas apresentadas por cima (folhas).
enum Sheet: String, Identifiable {
    /// Anexos do "+" (Toni: foto, arquivo, captura).
    case attachments
    /// Parear com o Mac a partir do primeiro uso.
    case pairMac

    var id: String { rawValue }
}

/// Navegação do app num único lugar, para as telas não se conhecerem diretamente.
@MainActor
@Observable
final class AppRouter {
    var path: [Route] = []
    var sheet: Sheet?
    /// Sessão de voz em tela cheia.
    var isVoiceSessionPresented = false

    func push(_ route: Route) {
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }

    func present(_ sheet: Sheet) {
        self.sheet = sheet
    }

    func startVoiceSession() {
        isVoiceSessionPresented = true
    }

    /// Fecha a voz e abre a conversa, como no botão de teclado da sessão de voz.
    func switchVoiceToChat() {
        isVoiceSessionPresented = false
        push(.chat(nil))
    }
}
