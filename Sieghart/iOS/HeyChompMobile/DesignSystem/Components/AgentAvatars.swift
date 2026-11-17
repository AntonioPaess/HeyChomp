import SwiftUI

/// Avatar redondo com anel na cor do agente e ponto de status.
/// Usado na fileira da equipe, nas listas e no histórico.
struct AgentAvatar: View {
    let agent: Agent
    var size: CGFloat = 50
    /// `nil` esconde o ponto de status.
    var isWorking: Bool?
    var showsRing = true
    var background: Color = Palette.card

    var body: some View {
        Circle()
            .fill(background)
            .overlay(
                Image(agent.portraitImageName)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(1.12)
                    .offset(y: size * 0.08)
            )
            .clipShape(Circle())
            .padding(showsRing ? max(2, size * 0.06) : 0)
            .overlay {
                if showsRing {
                    Circle().strokeBorder(agent.tint, lineWidth: size > 36 ? 2 : 1.5)
                }
            }
            .frame(width: size, height: size)
            .overlay(alignment: .bottomTrailing) {
                if let isWorking {
                    Circle()
                        .fill(isWorking ? Palette.accent : Color.gray)
                        .frame(width: size * 0.26, height: size * 0.26)
                        .overlay(Circle().stroke(Palette.page, lineWidth: 2.5))
                }
            }
            .accessibilityLabel(agent.name)
    }
}

/// Rosto do agente num círculo com brilho na cor dele (widgets v2, equipe e Live Activity).
struct AgentDisc: View {
    let agent: Agent
    var size: CGFloat = 86
    var showsRing = true
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let strong = colorScheme == .dark ? 0.70 : 0.45
        let soft = colorScheme == .dark ? 0.22 : 0.14
        Circle()
            .fill(
                RadialGradient(
                    colors: [agent.tint.opacity(strong), agent.tint.opacity(soft), agent.tint.opacity(0.02)],
                    center: UnitPoint(x: 0.5, y: 0.62),
                    startRadius: 0,
                    endRadius: size * 0.55
                )
            )
            .overlay(
                Image(agent.portraitImageName)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.11)
                    .offset(y: size * 0.1)
            )
            .clipShape(Circle())
            .overlay {
                if showsRing {
                    Circle().strokeBorder(agent.tint.opacity(0.45), lineWidth: 1)
                }
            }
            .frame(width: size, height: size)
            .accessibilityLabel(agent.name)
    }
}

/// Selo menta de "digitando": marca quem está trabalhando agora.
struct TypingBadge: View {
    var size: CGFloat = 24
    var outline: Color = Palette.card

    var body: some View {
        Circle()
            .fill(Palette.accent)
            .overlay(
                HStack(spacing: size * 0.1) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(Palette.onAccent).frame(width: size * 0.16, height: size * 0.16)
                    }
                }
            )
            .frame(width: size, height: size)
            .overlay(Circle().stroke(outline, lineWidth: 3))
            .accessibilityLabel("Trabalhando")
    }
}

/// Marca do Chomp: cápsula menta com os dois olhos.
/// Aparece na Dynamic Island, no acessório "Falar" e na Live Activity de voz.
struct ChompMark: View {
    var width: CGFloat = 58
    var height: CGFloat = 36
    var fill: Color = Palette.accent
    var eye: Color = Palette.eye

    var body: some View {
        Capsule()
            .fill(fill)
            .overlay(
                HStack(spacing: width * 0.1) {
                    Ellipse().fill(eye).frame(width: height * 0.2, height: height * 0.36)
                    Ellipse().fill(eye).frame(width: height * 0.2, height: height * 0.36)
                }
            )
            .frame(width: width, height: height)
            .accessibilityLabel("Chomp")
    }
}

#Preview {
    HStack(spacing: 16) {
        AgentAvatar(agent: .rita, isWorking: true)
        AgentDisc(agent: .gantt, size: 70)
        TypingBadge()
        ChompMark()
    }
    .padding()
    .background(Palette.page)
}
