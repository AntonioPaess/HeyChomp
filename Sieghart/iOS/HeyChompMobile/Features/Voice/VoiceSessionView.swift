import SwiftUI

/// Falar com o Chomp: rosto grande com brilho, transcrição ao vivo e controles
/// no padrão de chamada (silenciar, teclado e encerrar em vermelho).
struct VoiceSessionView: View {
    @State private var viewModel: VoiceSessionViewModel
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    init(viewModel: VoiceSessionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Palette.night.ignoresSafeArea()
            AgentGlow(agent: .chomp, intensity: 0.45).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    ChompMark(width: 46, height: 28)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.elapsed).font(Typography.number(16, weight: .semibold))
                        Text(viewModel.statusText).font(Typography.footnote).opacity(0.6)
                    }
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()

                ZStack(alignment: .topLeading) {
                    Image(Agent.chomp.portraitImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 230, height: 230)
                        .scaleEffect(viewModel.phase == .listening ? 1 : 0.94)
                        .animation(Motion.arrival, value: viewModel.phase)
                    if viewModel.phase == .listening {
                        TypingBadge(size: 30, outline: Palette.night).offset(x: 12, y: 40)
                    }
                }
                .accessibilityHidden(true)

                Text("“\(viewModel.transcript)”")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                WaveformBars(heights: [8, 16, 26, 14, 22, 9, 18, 28, 12, 20, 10, 15, 24, 11, 6], tint: Palette.accent, barWidth: 4)
                    .opacity(viewModel.phase == .listening ? 1 : 0.3)
                    .padding(.top, 26)

                HStack(spacing: 8) {
                    ForEach(viewModel.team.filter(\.isWorking)) { status in
                        AgentDisc(agent: status.agent, size: 30, showsRing: false)
                    }
                    Text("A equipe está acompanhando")
                        .font(Typography.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 22)

                Spacer()

                HStack(spacing: 28) {
                    VoiceControl(symbol: viewModel.phase == .listening ? "mic.fill" : "mic.slash.fill", label: "Silenciar", fill: Color.white.opacity(0.16)) {
                        viewModel.toggleMute()
                    }
                    VoiceControl(symbol: "keyboard", label: "Escrever", fill: Color.white.opacity(0.16)) {
                        router.switchVoiceToChat()
                    }
                    VoiceControl(symbol: "xmark", label: "Encerrar", fill: Palette.destructive) {
                        dismiss()
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

private struct VoiceControl: View {
    let symbol: String
    let label: String
    let fill: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 66, height: 66)
                    .background(Circle().fill(fill))
                Text(label).font(Typography.footnote).foregroundStyle(.white.opacity(0.75))
            }
        }
        .accessibilityLabel(label)
    }
}

#Preview("Voz") {
    VoiceSessionView(viewModel: VoiceSessionViewModel())
        .previewEnvironment()
}
