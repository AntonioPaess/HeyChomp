import Foundation

/// Modelo de sessão de foco que a Rita oferece.
struct FocusPreset: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var focusMinutes: Int
    var breakMinutes: Int
}

/// Sessão concluída ou em andamento hoje.
struct FocusSession: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var time: String
    var duration: String
    var isCurrent: Bool = false
}

/// Estado do foco atual, como aparece na tela inicial, no widget e na Live Activity.
struct FocusSnapshot: Hashable, Sendable {
    var remaining: String
    /// Fração já cumprida (0...1).
    var progress: Double
    var cycleLabel: String
    var nextBreak: String
}
