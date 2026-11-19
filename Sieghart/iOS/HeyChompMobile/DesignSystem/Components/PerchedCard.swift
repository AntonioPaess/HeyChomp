import SwiftUI

/// Cartão com o agente dono espiando por cima da borda superior.
///
/// É o gesto principal da linguagem visual (`.perched` / `PeekingCharacter` no Mac).
/// As mãos do asset `Peek-*` ficam a cerca de 74% da altura da imagem. Subindo o
/// personagem em metade da largura, as mãos ficam apoiadas exatamente na borda.
///
/// O cartão reserva em cima o espaço do personagem, então pode ser empilhado
/// em `VStack` sem sobreposição.
struct PerchedCard<Content: View>: View {
    enum Placement {
        case leading, center, trailing
    }

    let agent: Agent
    var placement: Placement = .leading
    var peekWidth: CGFloat = Metrics.peekWidth
    /// Linha pequena ao lado do personagem ("Chomp · agora").
    var caption: String?
    @ViewBuilder var content: () -> Content

    private var peekHeight: CGFloat { peekWidth * Metrics.peekAspect }
    /// Quanto do personagem fica acima da borda (as mãos encostam um pouco no cartão).
    private var rise: CGFloat { peekWidth * 0.47 }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: placement == .center ? .center : .leading)
            .padding(.horizontal, 16)
            .padding(.top, peekHeight - rise + 6)
            .padding(.bottom, 14)
            .background(CardSurface())
            .overlay(alignment: overlayAlignment) {
                PeekImage(agent: agent, width: peekWidth)
                    .padding(.horizontal, 10)
                    .offset(y: -rise)
            }
            .overlay(alignment: .topLeading) {
                if let caption, placement == .leading {
                    Text(caption)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.muted)
                        .padding(.leading, 10 + peekWidth + 4)
                        .padding(.top, 9)
                }
            }
            .padding(.top, rise)
            .accessibilityElement(children: .combine)
    }

    private var overlayAlignment: Alignment {
        switch placement {
        case .leading: .topLeading
        case .center: .top
        case .trailing: .topTrailing
        }
    }
}

/// Só o personagem espiando, para usar sobre outros elementos (campos, botões, widgets).
struct PeekImage: View {
    let agent: Agent
    var width: CGFloat = Metrics.peekWidth

    var body: some View {
        Image(agent.peekImageName)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: width * Metrics.peekAspect)
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 24) {
        PerchedCard(agent: .chomp, caption: "Chomp · agora") {
            Text("Você tem 1h20 livre antes da revisão das 16h.")
        }
        PerchedCard(agent: .gantt, placement: .center, peekWidth: 76) {
            Text("Gantt").font(.headline)
        }
    }
    .padding()
    .background(Palette.page)
}
