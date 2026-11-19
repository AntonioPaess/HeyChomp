import SwiftUI

/// Tamanhos reais dos widgets no iPhone de 6,1" (pontos).
enum WidgetFamilySize {
    case small, medium, large

    var size: CGSize {
        switch self {
        case .small: CGSize(width: 170, height: 170)
        case .medium: CGSize(width: 364, height: 170)
        case .large: CGSize(width: 364, height: 382)
        }
    }
}

/// Moldura do widget: canto de 23 pt e fundo com brilho na cor do agente.
/// No escuro o fundo é quase preto (como nas referências); no claro, branco.
struct WidgetFrame<Content: View>: View {
    let family: WidgetFamilySize
    var glow: Agent?
    var glowIntensity: Double = 0.30
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content()
            .frame(width: family.size.width, height: family.size.height)
            .background(
                ZStack {
                    colorScheme == .dark ? Palette.night : Color.white
                    if let glow { AgentGlow(agent: glow, intensity: glowIntensity) }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.07), radius: 10, y: 4)
    }
}

/// Elemento interno do widget sobre o qual o personagem espia.
struct WidgetInset<Content: View>: View {
    var agent: Agent?
    var peekWidth: CGFloat = 64
    var radius: CGFloat = Metrics.insetRadius
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Palette.inset))
            .overlay(alignment: .topLeading) {
                if let agent {
                    PeekImage(agent: agent, width: peekWidth)
                        .padding(.leading, 6)
                        .offset(y: -peekWidth * 0.5)
                }
            }
    }
}

/// Linhas de etapas que sobem e somem: feitas apagadas, a atual em negrito.
struct StepTicker: View {
    let steps: [String]
    var size: CGFloat = 12.5

    var body: some View {
        VStack(spacing: 2) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                let isCurrent = index == steps.count - 1
                HStack(spacing: 4) {
                    Image(systemName: isCurrent ? "sparkle" : "checkmark")
                        .foregroundStyle(isCurrent ? Palette.accent : Palette.ink)
                    Text(step)
                }
                .font(.system(size: isCurrent ? size : size - 2.5, weight: isCurrent ? .semibold : .medium))
                .opacity(isCurrent ? 1 : (index == steps.count - 2 ? 0.55 : 0.28))
                .lineLimit(1)
            }
        }
        .foregroundStyle(Palette.ink)
    }
}
