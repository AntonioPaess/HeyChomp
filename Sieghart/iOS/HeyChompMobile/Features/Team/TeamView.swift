import SwiftUI

/// Equipe em grade: cada agente de rosto com brilho, status e o que faz.
struct TeamView: View {
    @State private var viewModel: TeamViewModel
    @Environment(AppRouter.self) private var router

    init(viewModel: TeamViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.summary)
                    .font(Typography.callout)
                    .foregroundStyle(Palette.muted)
                    .padding(.horizontal, 4)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.team) { status in
                        Button { router.push(.agent(status.agent)) } label: {
                            TeamMemberCard(status: status)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Metrics.screenPadding)
        }
        .background(Palette.page.ignoresSafeArea())
        .navigationTitle("Equipe")
    }
}

private struct TeamMemberCard: View {
    let status: AgentStatus

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                AgentDisc(agent: status.agent, size: 92)
                if status.isWorking { TypingBadge(size: 22).offset(x: 2, y: 4) }
            }
            Text(status.agent.name).font(.system(size: 16, weight: .bold))
            Text(status.agent.role)
                .font(Typography.footnote)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
            StatusPill(text: status.badge, isActive: status.isWorking)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                CardSurface()
                AgentGlow(agent: status.agent, intensity: 0.18)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
            }
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview("Equipe") {
    NavigationStack { TeamView(viewModel: TeamViewModel()) }
        .previewEnvironment()
}
