import SwiftUI

/// Anel de progresso (foco da Rita, acessórios da tela bloqueada).
struct ProgressRing<Label: View>: View {
    var progress: Double
    var tint: Color
    var lineWidth: CGFloat = 8
    var track: Color = Palette.fill
    @ViewBuilder var label: () -> Label

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            label()
        }
    }
}

/// Barra fina de progresso na cor do agente.
struct ProgressTrack: View {
    var progress: Double
    var tint: Color
    var height: CGFloat = 5

    var body: some View {
        Capsule()
            .fill(Palette.fill)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule().fill(tint).frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: height)
            .accessibilityValue("\(Int(progress * 100))%")
    }
}

/// Onda sonora estática. Não há captura de áudio no protótipo.
struct WaveformBars: View {
    var heights: [CGFloat] = [6, 11, 16, 9, 13, 5, 10, 15, 8, 12, 6, 9, 14, 7, 4]
    var tint: Color = Palette.accent
    var barWidth: CGFloat = 3

    var body: some View {
        HStack(alignment: .center, spacing: barWidth) {
            ForEach(heights.indices, id: \.self) { index in
                Capsule().fill(tint).frame(width: barWidth, height: heights[index])
            }
        }
        .accessibilityHidden(true)
    }
}

/// Indicador de "digitando" dentro de um balão.
struct TypingDots: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Palette.muted)
                    .opacity(0.45 + Double(index) * 0.15)
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 6, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous)
                .fill(Palette.card)
        )
        .accessibilityLabel("Digitando")
    }
}

/// Brilho radial de baixo para cima na cor do agente (fundo dos widgets e das telas de agente).
struct AgentGlow: View {
    let agent: Agent
    var intensity: Double = 0.38
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RadialGradient(
            colors: [agent.tint.opacity(colorScheme == .dark ? intensity : intensity * 0.65), .clear],
            center: UnitPoint(x: 0.5, y: 1.05),
            startRadius: 0,
            endRadius: 260
        )
    }
}
