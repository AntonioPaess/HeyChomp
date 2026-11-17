import SwiftUI

/// Tela inicial do app.
///
/// De cima para baixo: saudação, fileira da equipe, sugestão do Chomp, "Hoje"
/// (agenda do Gantt), resumos de foco, finanças, código e área de transferência.
/// A barra "Pergunte ao Chomp" fica sempre fixa embaixo.
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @Environment(AppModel.self) private var appModel
    @Environment(AppRouter.self) private var router

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HomeHeader(date: viewModel.todayLabel, greeting: viewModel.greeting(for: appModel.userName))
                TeamStatusRow(team: viewModel.team) { router.push(.agent($0)) }
                    .padding(.top, 14)

                if !viewModel.isSuggestionDismissed {
                    SuggestionCard(
                        suggestion: viewModel.suggestion,
                        onPrimary: { router.push(.agent(viewModel.suggestion.target)) },
                        onSecondary: viewModel.dismissSuggestion
                    )
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                SectionHeader(title: "Hoje", actionTitle: "Ver agenda") { router.push(.agent(.gantt)) }
                    .padding(.top, 22)

                Button { router.push(.agent(.gantt)) } label: {
                    AgendaCard(events: viewModel.agendaPreview)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)

                SectionHeader(title: "Equipe trabalhando")
                    .padding(.top, 22)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
                    SummaryCard(agent: .rita, title: "Foco", value: viewModel.focus.remaining, detail: viewModel.focus.cycleLabel, progress: viewModel.focus.progress) {
                        router.push(.agent(.rita))
                    }
                    SummaryCard(agent: .elinor, title: viewModel.budget.month, value: viewModel.budget.spent, detail: "\(Int(viewModel.budget.progress * 100))% do orçamento", progress: viewModel.budget.progress) {
                        router.push(.agent(.elinor))
                    }
                    SummaryCard(agent: .ada, title: "Código", value: "\(viewModel.pendingCodeCount)", detail: "tarefas pendentes", progress: nil) {
                        router.push(.agent(.ada))
                    }
                    SummaryCard(agent: .toni, title: "Copiados", value: "\(viewModel.clipboard.count)", detail: viewModel.clipboard.first?.content ?? "", progress: nil) {
                        router.push(.agent(.toni))
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, Metrics.screenPadding)
            .padding(.bottom, 24)
        }
        .background(Palette.page.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            AskChompBar(
                onPlus: { router.present(.attachments) },
                onText: { router.push(.chat(nil)) },
                onMic: { router.startVoiceSession() }
            )
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(
                LinearGradient(colors: [Palette.page.opacity(0), Palette.page], startPoint: .top, endPoint: .center)
                    .ignoresSafeArea()
            )
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Partes da tela inicial

private struct HomeHeader: View {
    let date: String
    let greeting: String
    @Environment(AppRouter.self) private var router

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Palette.muted)
                Text(greeting)
                    .font(Typography.largeTitle)
            }
            Spacer()
            HStack(spacing: 8) {
                CircleIconButton(symbol: "bubble.left.and.bubble.right", label: "Conversas", size: 38) {
                    router.push(.conversations)
                }
                CircleIconButton(symbol: "person.crop.circle", label: "Ajustes", size: 38) {
                    router.push(.settings)
                }
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }
}

/// Fileira com os seis agentes e o ponto de status. Tocar abre a tela do agente.
struct TeamStatusRow: View {
    let team: [AgentStatus]
    var onSelect: (Agent) -> Void

    var body: some View {
        HStack {
            ForEach(team) { status in
                Button { onSelect(status.agent) } label: {
                    VStack(spacing: 5) {
                        AgentAvatar(agent: status.agent, size: 50, isWorking: status.isWorking)
                        Text(status.agent.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Palette.muted)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(status.agent.name), \(status.detail)")
                if status.id != team.last?.id { Spacer(minLength: 0) }
            }
        }
    }
}

/// Sugestão do Chomp em cartão com ele espiando e pílulas de ação.
private struct SuggestionCard: View {
    let suggestion: ChompSuggestion
    var onPrimary: () -> Void
    var onSecondary: () -> Void

    var body: some View {
        PerchedCard(agent: .chomp, caption: "Chomp · agora") {
            VStack(alignment: .leading, spacing: 12) {
                Text(suggestion.text)
                    .font(.system(size: 15.5))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Button(suggestion.primaryAction, action: onPrimary).buttonStyle(.chompPrimary)
                    Button(suggestion.secondaryAction, action: onSecondary).buttonStyle(.chompSecondary)
                }
            }
        }
    }
}

/// Três eventos do dia com o Gantt espiando. O próximo fica em destaque.
struct AgendaCard: View {
    let events: [CalendarEvent]

    var body: some View {
        PerchedCard(agent: .gantt, caption: "Gantt") {
            VStack(spacing: 2) {
                ForEach(events) { event in
                    EventLine(event: event)
                }
            }
        }
    }
}

struct EventLine: View {
    let event: CalendarEvent
    /// Versão menor para widgets: fonte reduzida e sem o tempo relativo.
    var compact = false

    var body: some View {
        HStack(spacing: 10) {
            Text(event.time)
                .font(.system(size: compact ? 13 : 14, weight: event.isNext ? .semibold : .medium).monospacedDigit())
                .foregroundStyle(event.isNext ? Palette.ink : Palette.muted)
                .frame(width: compact ? 40 : 46, alignment: .leading)
            Capsule()
                .fill(event.isNext ? Agent.gantt.tint : Palette.ink.opacity(0.15))
                .frame(width: 3, height: 18)
            Text(event.title)
                .font(.system(size: compact ? 13 : 14, weight: event.isNext ? .semibold : .regular))
                .foregroundStyle(event.isNext ? Palette.ink : Palette.muted)
                .lineLimit(1)
            Spacer()
            if let relative = event.relative, !compact {
                Text(relative).font(.system(size: 12, weight: .medium)).foregroundStyle(Palette.muted)
            }
        }
        .padding(.vertical, compact ? 3 : 5)
    }
}

/// Resumo de um especialista em cartão pequeno com ele espiando.
private struct SummaryCard: View {
    let agent: Agent
    let title: String
    let value: String
    let detail: String
    let progress: Double?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            PerchedCard(agent: agent, peekWidth: 70) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Typography.caption).foregroundStyle(Palette.muted)
                    Text(value).font(Typography.number(26)).foregroundStyle(Palette.ink)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                        .lineLimit(1)
                    if let progress {
                        ProgressTrack(progress: progress, tint: agent.tint).padding(.top, 8)
                    } else {
                        Color.clear.frame(height: 13)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Início") {
    NavigationStack { HomeView(viewModel: HomeViewModel()) }
        .previewEnvironment()
}
