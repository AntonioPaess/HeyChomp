import SwiftUI

/// Balão de fala do Chomp com rabinho apontando para o personagem.
struct SpeechBubble: View {
    let text: String
    /// Posição horizontal do rabinho, de 0 (esquerda) a 1 (direita).
    var tailPosition: CGFloat = 0.3

    var body: some View {
        Text(text)
            .font(Typography.body)
            .foregroundStyle(Palette.ink)
            .lineSpacing(2)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                BubbleShape(tailPosition: tailPosition)
                    .fill(Palette.card)
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
            )
    }
}

/// Retângulo arredondado com um rabinho embaixo.
struct BubbleShape: Shape {
    var radius: CGFloat = 20
    var tailPosition: CGFloat = 0.3
    var tailSize: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: radius, style: .continuous)
        let x = rect.minX + rect.width * tailPosition
        path.move(to: CGPoint(x: x - tailSize, y: rect.maxY - 1))
        path.addQuadCurve(to: CGPoint(x: x, y: rect.maxY + tailSize), control: CGPoint(x: x - 2, y: rect.maxY + 2))
        path.addQuadCurve(to: CGPoint(x: x + tailSize, y: rect.maxY - 1), control: CGPoint(x: x + 2, y: rect.maxY + 2))
        path.closeSubpath()
        return path
    }
}

/// Balão de mensagem da conversa. Pessoa à direita em menta; agente à esquerda em cartão.
struct MessageBubble: View {
    let text: String
    var isUser: Bool

    var body: some View {
        Text(text)
            .font(Typography.body)
            .lineSpacing(2)
            .foregroundStyle(isUser ? Palette.onAccent : Palette.ink)
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 20,
                    bottomLeadingRadius: isUser ? 20 : 6,
                    bottomTrailingRadius: isUser ? 6 : 20,
                    topTrailingRadius: 20,
                    style: .continuous
                )
                .fill(isUser ? Palette.accent : Palette.card)
                .shadow(color: .black.opacity(isUser ? 0 : 0.04), radius: 6, y: 2)
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        SpeechBubble(text: "Oi! Eu sou o Chomp.")
        MessageBubble(text: "Me lembra de revisar o orçamento", isUser: true)
        MessageBubble(text: "Combinado!", isUser: false)
    }
    .padding()
    .background(Palette.page)
}
