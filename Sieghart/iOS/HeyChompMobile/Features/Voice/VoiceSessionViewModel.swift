import SwiftUI

/// Sessão de voz em tela cheia.
///
/// Totalmente visual: não abre o microfone, não grava e não reproduz áudio.
/// O tempo e a transcrição são fixos.
@MainActor
@Observable
final class VoiceSessionViewModel {
    enum Phase {
        case listening, paused
    }

    var phase: Phase = .listening
    let elapsed = "0:42"
    let transcript: String
    let team: [AgentStatus]

    init(data: any DataSource = MockDataSource()) {
        transcript = data.voiceTranscript
        team = data.teamStatus
    }

    var statusText: String { phase == .listening ? "Chomp ouvindo…" : "Microfone pausado" }

    func toggleMute() {
        withAnimation(Motion.feedback) { phase = phase == .listening ? .paused : .listening }
    }
}
