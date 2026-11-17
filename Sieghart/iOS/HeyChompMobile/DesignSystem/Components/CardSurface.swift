import SwiftUI

/// Superfície de cartão: canto contínuo, contorno finíssimo e sombra só no claro.
struct CardSurface: View {
    var radius: CGFloat = Metrics.cardRadius
    var fill: Color = Palette.card
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 9, y: 4)
    }
}

extension View {
    /// Aplica a superfície de cartão padrão com o recuo interno indicado.
    func cardStyle(padding: CGFloat = 16, radius: CGFloat = Metrics.cardRadius) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CardSurface(radius: radius))
    }
}
