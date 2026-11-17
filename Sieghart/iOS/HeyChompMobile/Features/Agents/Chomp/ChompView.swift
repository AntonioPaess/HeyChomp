import SwiftUI

/// Tela do Chomp, o orquestrador.
struct ChompView: View {
    @State private var viewModel: ChompViewModel
    @Environment(AppRouter.self) private var router

    init(viewModel: ChompViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        AgentScreen(agent: .chomp, status: viewModel.status) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Como funciona")
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.flow.enumerated()), id: \.offset) { index, step in
                        InfoRow(symbol: step.symbol, symbolTint: Palette.accent, title: step.title, detail: step.detail)
                        if index < viewModel.flow.count - 1 { Divider().padding(.leading, 44) }
                    }
                }
                .cardStyle(padding: 14)
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Repasses recentes")
                VStack(spacing: 14) {
                    ForEach(viewModel.handoffs, id: \.self) { handoff in
                        Button { router.push(.agent(handoff.agent)) } label: { HandoffCard(handoff: handoff) }
                            .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Especialistas")
                VStack(spacing: 0) {
                    ForEach(viewModel.team) { status in
                        Button { router.push(.agent(status.agent)) } label: {
                            HStack(spacing: 12) {
                                AgentAvatar(agent: status.agent, size: 36, isWorking: status.isWorking)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(status.agent.name).font(.system(size: 15, weight: .semibold))
                                    Text(status.agent.role).font(Typography.footnote).foregroundStyle(Palette.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        if status.id != viewModel.team.last?.id { Divider().padding(.leading, 48) }
                    }
                }
                .cardStyle(padding: 14)
            }
        }
    }
}

#Preview("Chomp") {
    NavigationStack { ChompView(viewModel: ChompViewModel()) }
        .previewEnvironment()
}
