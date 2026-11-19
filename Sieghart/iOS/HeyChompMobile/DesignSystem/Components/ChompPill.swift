import SwiftUI

/// Pílula de ação (`ChompPill` no Mac). Primária em menta; secundária em neutro.
struct ChompPillStyle: ButtonStyle {
    enum Kind { case primary, secondary }
    enum Size { case regular, large }

    var kind: Kind = .secondary
    var size: Size = .regular

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size == .large ? .system(size: 17, weight: .semibold) : .system(size: 14, weight: .semibold))
            .foregroundStyle(kind == .primary ? Palette.onAccent : Palette.ink)
            .padding(.horizontal, size == .large ? 24 : 15)
            .frame(height: size == .large ? 54 : 34)
            .frame(maxWidth: size == .large ? .infinity : nil)
            .background(Capsule().fill(kind == .primary ? Palette.accent : Palette.fill))
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Motion.feedback, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ChompPillStyle {
    static var chompPrimary: ChompPillStyle { ChompPillStyle(kind: .primary) }
    static var chompSecondary: ChompPillStyle { ChompPillStyle(kind: .secondary) }
    static var chompLarge: ChompPillStyle { ChompPillStyle(kind: .primary, size: .large) }
}

/// Pílula informativa de recurso que ainda não existe ("Saúde · em breve").
struct SoonPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Palette.muted)
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(Capsule().fill(Palette.fill))
    }
}

/// Pílula de status ("Em foco", "Livre"). Menta quando o agente está trabalhando.
struct StatusPill: View {
    let text: String
    var isActive: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(isActive ? Palette.onAccent : Palette.muted)
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(Capsule().fill(isActive ? Palette.accent : Palette.fill))
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack {
            Button("Iniciar foco") {}.buttonStyle(.chompPrimary)
            Button("Agora não") {}.buttonStyle(.chompSecondary)
        }
        Button("Continuar") {}.buttonStyle(.chompLarge)
        HStack {
            SoonPill(text: "Saúde · em breve")
            StatusPill(text: "Em foco", isActive: true)
            StatusPill(text: "Livre", isActive: false)
        }
    }
    .padding()
}
