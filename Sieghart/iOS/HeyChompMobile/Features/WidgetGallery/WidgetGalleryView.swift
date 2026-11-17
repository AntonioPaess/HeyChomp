import SwiftUI

/// Galeria com todos os widgets em tamanho real, na direção mista (v1 + v2):
/// quem fala ou trabalha aparece de rosto; em conteúdo, o dono espia por cima.
struct WidgetGalleryView: View {
    @State private var viewModel: WidgetGalleryViewModel

    init(viewModel: WidgetGalleryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Seção", selection: $viewModel.section) {
                    ForEach(WidgetGalleryViewModel.Section.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                switch viewModel.section {
                case .home: homeWidgets
                case .lock: lockWidgets
                case .live: liveWidgets
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 32)
        }
        .background(Palette.page.ignoresSafeArea())
        .navigationTitle("Widgets")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var homeWidgets: some View {
        VStack(alignment: .leading, spacing: 14) {
            GalleryLabel("Médio · Pergunte ao Chomp")
            AskChompWidget(userName: viewModel.userName)
            GalleryLabel("Pequenos · Chomp e equipe")
            HStack(spacing: 24) {
                ChompFaceWidget(steps: viewModel.chompSteps)
                TeamGridWidget(agents: [.chomp, .rita, .gantt, .toni])
            }
            GalleryLabel("Médio · Agenda do Gantt")
            AgendaWidget(events: viewModel.agendaPreview)
            GalleryLabel("Pequenos · Foco e área de transferência")
            HStack(spacing: 24) {
                FocusWidget(focus: viewModel.focus)
                ClipboardWidget(item: viewModel.clipboard.first, extraCount: viewModel.clipboard.count - 1)
            }
            GalleryLabel("Grande · Equipe")
            TeamWidget(team: viewModel.team)
        }
    }

    private var lockWidgets: some View {
        VStack(alignment: .leading, spacing: 14) {
            GalleryLabel("Tela bloqueada")
            LockScreenPreview(nextEvent: viewModel.nextEvent, focus: viewModel.focus)
            Text("Acessórios são monocromáticos: o iOS pinta tudo de uma cor só. Dados de finanças nunca aparecem aqui.")
                .font(Typography.footnote)
                .foregroundStyle(Palette.muted)
        }
    }

    private var liveWidgets: some View {
        VStack(alignment: .leading, spacing: 14) {
            GalleryLabel("Dynamic Island · voz")
            DynamicIslandVoice()
            GalleryLabel("Live Activity · resposta do Chomp")
            SummaryLiveActivity()
            GalleryLabel("Live Activity · foco da Rita")
            FocusLiveActivity(focus: viewModel.focus)
        }
    }
}

private struct GalleryLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(Typography.caption)
            .foregroundStyle(Palette.muted)
            .padding(.top, 6)
    }
}

#Preview("Widgets") {
    NavigationStack { WidgetGalleryView(viewModel: WidgetGalleryViewModel()) }
        .previewEnvironment()
}
