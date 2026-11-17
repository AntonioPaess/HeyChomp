import SwiftUI

/// Tela do Toni, organizada pelas quatro áreas dele.
struct ToniView: View {
    @State private var viewModel: ToniViewModel

    init(viewModel: ToniViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        AgentScreen(agent: .toni, status: viewModel.status) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Área de transferência")
                PerchedCard(agent: .toni, caption: "\(viewModel.clipboard.count) itens hoje") {
                    VStack(spacing: 0) {
                        ForEach(viewModel.clipboard) { item in
                            InfoRow(symbol: viewModel.symbol(for: item), symbolTint: Agent.toni.tint, title: item.content, detail: "\(item.source) · \(item.time)") {
                                Image(systemName: "doc.on.doc").foregroundStyle(Palette.muted)
                            }
                            if item.id != viewModel.clipboard.last?.id { Divider().padding(.leading, 44) }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Arquivos recentes")
                VStack(spacing: 0) {
                    ForEach(viewModel.files) { file in
                        InfoRow(symbol: file.symbol, title: file.name, detail: file.detail) {
                            Image(systemName: "square.and.arrow.up").foregroundStyle(Palette.muted)
                        }
                        if file.id != viewModel.files.last?.id { Divider().padding(.leading, 44) }
                    }
                }
                .cardStyle(padding: 14)
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Áudio")
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.outputs) { output in
                        Button { viewModel.selectedOutputID = output.id } label: {
                            InfoRow(symbol: output.symbol, title: output.name) {
                                if output.id == viewModel.selectedOutputID {
                                    Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(Palette.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.fill").foregroundStyle(Palette.muted)
                        Slider(value: $viewModel.volume).tint(Agent.toni.tint)
                        Image(systemName: "speaker.wave.3.fill").foregroundStyle(Palette.muted)
                    }
                    .padding(.top, 6)
                }
                .cardStyle(padding: 14)
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Captura")
                CaptureGrid(actions: viewModel.captures)
            }
        }
    }
}

/// Grade de atalhos de captura (também usada na folha de anexos).
struct CaptureGrid: View {
    let actions: [CaptureAction]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(actions) { action in
                Button {} label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: action.symbol).font(.title3).foregroundStyle(Agent.toni.tint)
                        Text(action.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.ink)
                    }
                    .cardStyle(padding: 14)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Folha do "+": o Toni oferece anexos e capturas para a conversa.
struct AttachmentsSheet: View {
    @State private var viewModel: ToniViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ToniViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        AgentDisc(agent: .toni, size: 52)
                        Text("O que vamos mandar para o Chomp?")
                            .font(Typography.headline)
                    }
                    CaptureGrid(actions: viewModel.captures)
                    SectionHeader(title: "Copiados recentemente")
                    VStack(spacing: 0) {
                        ForEach(viewModel.clipboard) { item in
                            Button { dismiss() } label: {
                                InfoRow(symbol: viewModel.symbol(for: item), symbolTint: Agent.toni.tint, title: item.content, detail: item.source)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .cardStyle(padding: 14)
                }
                .padding(Metrics.screenPadding)
            }
            .background(Palette.page.ignoresSafeArea())
            .navigationTitle("Anexar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Toni") {
    NavigationStack { ToniView(viewModel: ToniViewModel()) }
        .previewEnvironment()
}
