import SwiftUI

/// Parear com o HeyChomp do Mac. Só a explicação visual: não há pareamento real.
struct PairMacView: View {
    private let steps = [
        "Abra o HeyChomp no Mac.",
        "Em Ajustes, escolha “Parear iPhone”.",
        "Aponte a câmera do iPhone para o código.",
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Palette.night)
                        .frame(height: 190)
                    HStack(spacing: 22) {
                        Image(systemName: "laptopcomputer").font(.system(size: 54, weight: .light))
                        Image(Agent.chomp.portraitImageName).resizable().scaledToFit().frame(width: 70)
                        Image(systemName: "iphone").font(.system(size: 50, weight: .light))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }
                .overlay(alignment: .bottom) {
                    AgentGlow(agent: .chomp, intensity: 0.5)
                        .frame(height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .allowsHitTesting(false)
                }
                .accessibilityHidden(true)

                SpeechBubble(text: "Com o Mac pareado, a equipe continua no iPhone o que começou no Mac.", tailPosition: 0.5)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(Typography.number(15))
                                .foregroundStyle(Palette.onAccent)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Palette.accent))
                            Text(step).font(Typography.callout).padding(.top, 3)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .cardStyle()

                Button("Escanear código", systemImage: "qrcode.viewfinder") {}
                    .buttonStyle(.chompLarge)
                Text("Protótipo: o pareamento ainda não existe.")
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.muted)
            }
            .padding(Metrics.screenPadding)
        }
        .background(Palette.page.ignoresSafeArea())
        .navigationTitle("Parear com o Mac")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Parear") {
    NavigationStack { PairMacView() }
        .previewEnvironment()
}
