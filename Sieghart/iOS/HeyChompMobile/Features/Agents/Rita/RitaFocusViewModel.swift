import SwiftUI

/// Foco da Rita: escolher o modelo de sessão, iniciar ou pausar.
///
/// Sem cronômetro real: iniciar e pausar só trocam o estado exibido.
@MainActor
@Observable
final class RitaFocusViewModel {
    let status: AgentStatus
    let presets: [FocusPreset]
    let sessions: [FocusSession]
    let snapshot: FocusSnapshot

    var selectedPresetID: FocusPreset.ID
    var isRunning = true
    var silencesNotifications = true

    init(data: any DataSource = MockDataSource()) {
        status = data.status(of: .rita)
        presets = data.focusPresets
        sessions = data.focusSessions
        snapshot = data.focusSnapshot
        selectedPresetID = data.focusPresets.first?.id ?? ""
    }

    var selectedPreset: FocusPreset? { presets.first { $0.id == selectedPresetID } }

    /// Com sessão ativa mostra o tempo restante; parada mostra a duração do modelo.
    var ringLabel: String {
        isRunning ? snapshot.remaining : String(format: "%02d:00", selectedPreset?.focusMinutes ?? 25)
    }

    var ringProgress: Double { isRunning ? snapshot.progress : 0 }

    var caption: String {
        if isRunning { return "\(snapshot.cycleLabel) · \(snapshot.nextBreak)" }
        guard let preset = selectedPreset else { return "" }
        return "\(preset.focusMinutes) min de foco, \(preset.breakMinutes) de pausa"
    }

    var primaryTitle: String { isRunning ? "Pausar" : "Iniciar foco" }

    func toggleRunning() {
        withAnimation(Motion.page) { isRunning.toggle() }
    }

    func stop() {
        withAnimation(Motion.page) { isRunning = false }
    }
}
