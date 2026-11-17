import SwiftUI

/// Tela da Ada: projetos, tarefas filtráveis e trecho de código guardado.
struct AdaCodeView: View {
    @State private var viewModel: AdaCodeViewModel

    init(viewModel: AdaCodeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        AgentScreen(agent: .ada, status: viewModel.status) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Projetos")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.projects) { project in
                            VStack(alignment: .leading, spacing: 6) {
                                Image(systemName: "folder").foregroundStyle(Agent.ada.tint)
                                Text(project.name).font(.system(size: 15, weight: .semibold))
                                Label(project.branch, systemImage: "arrow.triangle.branch")
                                    .font(Typography.footnote)
                                    .foregroundStyle(Palette.muted)
                                    .lineLimit(1)
                                Text(project.pending == 0 ? "Em dia" : "\(project.pending) pendente(s)")
                                    .font(Typography.caption)
                                    .foregroundStyle(project.pending == 0 ? Palette.muted : Palette.ink)
                            }
                            .frame(width: 160, alignment: .leading)
                            .cardStyle(padding: 14)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Tarefas")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AdaCodeViewModel.filters, id: \.title) { item in
                            Button(item.title) { withAnimation(Motion.feedback) { viewModel.filter = item.state } }
                                .buttonStyle(ChompPillStyle(kind: viewModel.filter == item.state ? .primary : .secondary))
                        }
                    }
                }
                PerchedCard(agent: .ada, caption: "Ada") {
                    VStack(spacing: 0) {
                        ForEach(viewModel.visibleTasks) { task in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: task.state == .done ? "checkmark.circle.fill" : "circle.dashed")
                                    .foregroundStyle(task.state == .done ? Palette.muted : Agent.ada.tint)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title).font(.system(size: 15, weight: .medium))
                                    Text("\(task.project) · \(task.updated)").font(Typography.footnote).foregroundStyle(Palette.muted)
                                }
                                Spacer()
                                SoonPill(text: task.state.rawValue)
                            }
                            .padding(.vertical, 8)
                        }
                        if viewModel.visibleTasks.isEmpty {
                            Text("Nada aqui.").font(Typography.footnote).foregroundStyle(Palette.muted).padding(.vertical, 8)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Trecho guardado")
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(viewModel.snippet.title).font(.system(size: 15, weight: .semibold))
                        Spacer()
                        SoonPill(text: viewModel.snippet.language)
                    }
                    Text(viewModel.snippet.code)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.inset))
                    Button("Copiar", systemImage: "doc.on.doc") {}.buttonStyle(.chompSecondary)
                }
                .cardStyle()
            }
        }
    }
}

#Preview("Ada") {
    NavigationStack { AdaCodeView(viewModel: AdaCodeViewModel()) }
        .previewEnvironment()
}
