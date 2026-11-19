import SwiftUI

/// Ajustes → Ícone do app. Mostra os seis ícones "Espiando" no tema atual;
/// o iOS troca sozinho entre claro, escuro e tingido.
struct AppIconPickerView: View {
    @State private var viewModel: AppIconPickerViewModel

    init(viewModel: AppIconPickerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    AgentAvatar(agent: .chomp, size: 40, showsRing: false)
                    SpeechBubble(text: "Eu começo no ícone, mas pode chamar qualquer um da equipe para a tela de início.", tailPosition: 0.08)
                }

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(viewModel.options) { agent in
                        Button {
                            Task { await viewModel.select(agent) }
                        } label: {
                            IconOption(agent: agent, isSelected: viewModel.isSelected(agent))
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.isAvailable || viewModel.isApplying)
                    }
                }

                Text("O ícone acompanha o tema claro, escuro ou tingido do iPhone. O Chomp continua sendo quem responde no app.")
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.muted)
                    .padding(.horizontal, 4)
            }
            .padding(Metrics.screenPadding)
        }
        .background(Palette.page.ignoresSafeArea())
        .navigationTitle("Ícone do app")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ícone", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct IconOption: View {
    let agent: Agent
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(agent.iconPreviewName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(isSelected ? Palette.accent : .clear, lineWidth: 3)
                )
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Palette.onAccent, Palette.accent)
                            .background(Circle().fill(Palette.page).padding(2))
                            .offset(x: 6, y: -6)
                    }
                }
            Text(agent.name)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Palette.ink : Palette.muted)
            // Todas as opções reservam a altura da pílula, para a grade ficar alinhada.
            SoonPill(text: "Padrão").opacity(agent == .chomp ? 1 : 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ícone \(agent.name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Ícone do app") {
    NavigationStack { AppIconPickerView(viewModel: AppIconPickerViewModel(service: PreviewAppIconService())) }
        .previewEnvironment()
}
