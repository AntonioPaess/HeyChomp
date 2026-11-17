import SwiftUI

extension Agent {
    /// Cor de marca do agente (anéis, pontos, barras e brilho). Nunca use em texto.
    var tint: Color {
        switch self {
        case .chomp: Palette.accent
        case .rita: .adaptive(light: 0x61216D, dark: 0xDB9CF6)
        case .ada: .adaptive(light: 0x0B6A87, dark: 0x1497A5)
        case .gantt: .adaptive(light: 0x775113, dark: 0xF3E334)
        case .elinor: .adaptive(light: 0xCC5F01, dark: 0xCF7B03)
        case .toni: .adaptive(light: 0x2806BF, dark: 0xA96EFC)
        }
    }

    /// SF Symbol que resume a área do agente (abas, listas de permissões).
    var symbol: String {
        switch self {
        case .chomp: "sparkle"
        case .rita: "timer"
        case .ada: "chevron.left.forwardslash.chevron.right"
        case .gantt: "calendar"
        case .elinor: "chart.pie"
        case .toni: "tray.full"
        }
    }
}
