import SwiftUI
import UIKit

// Sistema visual do HeyChomp no iPhone.
//
// Os valores vêm do `CompanionStyle` do Mac (Sieghart/Shared/Components/DesignSystem.swift,
// "janela quieta, personagens expressivos"):
// - um único acento, a menta do Chomp: #00945F no claro e #3EDC9A no escuro;
// - a cor de cada agente aparece só em marcas (anéis, pontos, barras), nunca em texto;
// - superfícies neutras, cantos contínuos e sombra leve só no tema claro.
//
// Quando o código for compartilhado com o Mac, estes tokens devem ir para um pacote
// comum. O `CompanionStyle` usa NSColor e não compila no iOS.

/// Paleta adaptativa (claro/escuro).
enum Palette {
    /// Fundo das telas.
    static let page = Color.adaptive(light: 0xF7F7F7, dark: 0x1E1E1E)
    /// Cartões e balões.
    static let card = Color.adaptive(light: 0xFFFFFF, dark: 0x252525)
    /// Elemento dentro de um cartão (campos, listas internas).
    static let inset = Color.adaptive(light: 0xF2F2F4, dark: 0x303030)
    static let separator = Color.adaptive(light: 0xE6E6E6, dark: 0x343434)
    /// Texto principal.
    static let ink = Color.adaptive(light: 0x1D1D1F, dark: 0xEDEDED)
    /// Metadados e textos secundários (7:1 no claro, 6,4:1 no escuro).
    static let muted = Color.adaptive(light: 0x595959, dark: 0xA0A0A0)
    /// Menta do Chomp: só em preenchimentos, interruptores, progresso e anéis.
    static let accent = Color.adaptive(light: 0x00945F, dark: 0x3EDC9A)
    /// Texto sobre a menta.
    static let onAccent = Color.adaptive(light: 0x00150C, dark: 0x04170F)
    /// Preenchimento neutro de botões secundários e trilhas.
    static let fill = Color.primary.opacity(0.06)
    static let hairline = Color.primary.opacity(0.07)
    /// Vermelho de encerrar (sessão de voz), como no padrão de chamada do iOS.
    static let destructive = Color(hex: 0xE5484D)
    /// Fundo escuro fixo dos widgets com brilho e da Dynamic Island.
    static let night = Color(hex: 0x0C0C0D)
    /// Olhos do Chomp na marca.
    static let eye = Color(hex: 0xFFF6E6)
}

/// Medidas recorrentes.
enum Metrics {
    static let screenPadding: CGFloat = 18
    static let cardRadius: CGFloat = 22
    static let insetRadius: CGFloat = 15
    static let sectionSpacing: CGFloat = 20
    /// Largura padrão do personagem espiando em cartões grandes.
    static let peekWidth: CGFloat = 88
    /// Proporção dos assets `Peek-*` (480 × 340 px).
    static let peekAspect: CGFloat = 340.0 / 480.0
}

/// Tipografia. Números em SF Rounded, como os cronômetros e o relógio do conceito.
enum Typography {
    static let largeTitle = Font.system(size: 30, weight: .bold)
    static let title = Font.system(size: 22, weight: .bold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 16)
    static let callout = Font.system(size: 15)
    static let caption = Font.system(size: 12, weight: .semibold)
    static let footnote = Font.system(size: 13)

    static func number(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}

/// Movimento contido: retorno de controle rápido, chegada de página suave.
enum Motion {
    static let feedback = Animation.easeOut(duration: 0.14)
    static let page = Animation.easeOut(duration: 0.22)
    static let arrival = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.30)
}

extension Color {
    /// Cor sRGB a partir de um inteiro 0xRRGGBB.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    /// Cor que muda com o tema do sistema.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}
