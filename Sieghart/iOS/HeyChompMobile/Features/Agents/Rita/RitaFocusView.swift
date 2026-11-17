import SwiftUI

/// Tela da Rita: anel de foco, modelos de sessão, sessões de hoje e Saúde (em breve).
struct RitaFocusView: View {
    @State private var viewModel: RitaFocusViewModel

    init(viewModel: RitaFocusViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        AgentScreen(agent: .rita, status: viewModel.status) {
            focusCard

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Modelo")
                Picker("Modelo", selection: $viewModel.selectedPresetID) {
                    ForEach(viewModel.presets) { preset in
                        Text("\(preset.name) \(preset.focusMinutes)").tag(preset.id)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(viewModel.isRunning)
                Toggle("Silenciar notificações durante o foco", isOn: $viewModel.silencesNotifications)
                    .font(Typography.callout)
                    .cardStyle(padding: 14)
                    .padding(.top, 6)
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Hoje")
                VStack(spacing: 0) {
                    ForEach(viewModel.sessions) { session in
                        InfoRow(symbol: session.isCurrent ? "timer" : "checkmark", symbolTint: session.isCurrent ? Agent.rita.tint : Palette.muted, title: session.title, detail: session.time) {
                            Text(session.duration).font(Typography.footnote).foregroundStyle(Palette.muted)
                        }
                        if session.id != viewModel.sessions.last?.id { Divider().padding(.leading, 44) }
                    }
                }
                .cardStyle(padding: 14)
            }

            ComingSoonCard(agent: .rita, title: "Saúde", detail: "Sono, passos e lembretes de pausa com o Apple Health. A Rita ainda não lê nenhum dado de saúde.", symbol: "heart.text.square")
        }
    }

    private var focusCard: some View {
        PerchedCard(agent: .rita, placement: .center, peekWidth: 96) {
            VStack(spacing: 14) {
                ProgressRing(progress: viewModel.ringProgress, tint: Agent.rita.tint, lineWidth: 12) {
                    VStack(spacing: 2) {
                        Text(viewModel.ringLabel).font(Typography.number(44))
                        Text(viewModel.isRunning ? "restantes" : "pronta").font(Typography.footnote).foregroundStyle(Palette.muted)
                    }
                }
                .frame(width: 200, height: 200)
                .animation(Motion.page, value: viewModel.ringProgress)

                Text(viewModel.caption).font(Typography.footnote).foregroundStyle(Palette.muted)

                HStack(spacing: 10) {
                    Button(viewModel.primaryTitle, action: viewModel.toggleRunning).buttonStyle(.chompPrimary)
                    if viewModel.isRunning {
                        Button("Encerrar", action: viewModel.stop).buttonStyle(.chompSecondary)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
}

#Preview("Rita") {
    NavigationStack { RitaFocusView(viewModel: RitaFocusViewModel()) }
        .previewEnvironment()
}
