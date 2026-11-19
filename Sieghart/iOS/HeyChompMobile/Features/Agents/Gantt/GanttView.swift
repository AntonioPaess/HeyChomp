import SwiftUI

/// Tela do Gantt com duas abas: Agenda (faixa da semana e linha do tempo) e
/// Diário (bullet journal com os símbolos • ○ –).
struct GanttView: View {
    @State private var viewModel: GanttViewModel

    init(viewModel: GanttViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        AgentScreen(agent: .gantt, status: viewModel.status) {
            Picker("Seção", selection: $viewModel.tab) {
                ForEach(GanttViewModel.Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            switch viewModel.tab {
            case .agenda: agenda
            case .journal: journal
            }

            ComingSoonCard(agent: .gantt, title: "E-mail", detail: "Resumo da caixa de entrada e respostas sugeridas. Entra depois da agenda e do diário.", symbol: "envelope")
        }
    }

    private var agenda: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                ForEach(viewModel.weekDays) { day in
                    Button { viewModel.selectedDay = day.id } label: {
                        VStack(spacing: 4) {
                            Text(day.weekday).font(.system(size: 10, weight: .semibold))
                            Text("\(day.number)").font(Typography.number(17, weight: .semibold))
                            Circle().fill(day.hasEvents ? Agent.gantt.tint : .clear).frame(width: 5, height: 5)
                        }
                        .foregroundStyle(day.id == viewModel.selectedDay ? Palette.ink : Palette.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(day.id == viewModel.selectedDay ? Palette.card : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if let next = viewModel.nextEvent {
                PerchedCard(agent: .gantt, caption: "Próximo · \(next.relative ?? "")") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(next.title).font(Typography.title)
                        Text("\(next.time) – \(next.endTime ?? "") · \(next.location ?? "")")
                            .font(Typography.callout)
                            .foregroundStyle(Palette.muted)
                        HStack(spacing: 8) {
                            Button("Avisar 15 min antes") {}.buttonStyle(.chompPrimary)
                            Button("Abrir no Calendário") {}.buttonStyle(.chompSecondary)
                        }
                        .padding(.top, 8)
                    }
                }
            }

            VStack(spacing: 0) {
                ForEach(viewModel.events) { event in
                    EventLine(event: event).opacity(event.isPast ? 0.6 : 1)
                    if event.id != viewModel.events.last?.id { Divider().padding(.leading, 60) }
                }
            }
            .cardStyle(padding: 14)
        }
    }

    private var journal: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Terça, 17 · \(viewModel.openTasks) tarefas abertas")
            VStack(spacing: 0) {
                ForEach(viewModel.journal) { entry in
                    Button { viewModel.toggle(entry) } label: { JournalRow(entry: entry) }
                        .buttonStyle(.plain)
                    if entry.id != viewModel.journal.last?.id { Divider().padding(.leading, 36) }
                }
            }
            .cardStyle(padding: 14)
            Text("• tarefa   ○ evento   – nota   × feita   > migrada")
                .font(Typography.footnote)
                .foregroundStyle(Palette.muted)
                .padding(.horizontal, 4)
        }
    }
}

private struct JournalRow: View {
    let entry: JournalEntry

    private var symbol: String {
        switch entry.state {
        case .done: "×"
        case .migrated: ">"
        case .open: entry.kind.rawValue
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(symbol)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(entry.state == .open ? Agent.gantt.tint : Palette.muted)
                .frame(width: 22)
            Text(entry.text)
                .font(Typography.callout)
                .foregroundStyle(entry.state == .open ? Palette.ink : Palette.muted)
                .strikethrough(entry.state == .done)
            Spacer()
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

#Preview("Gantt") {
    NavigationStack { GanttView(viewModel: GanttViewModel()) }
        .previewEnvironment()
}
