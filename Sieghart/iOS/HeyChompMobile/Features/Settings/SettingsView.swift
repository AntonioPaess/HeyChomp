import SwiftUI

/// Ajustes do app.
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Environment(AppModel.self) private var appModel
    @Environment(AppRouter.self) private var router

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var appModel = appModel
        Form {
            Section {
                HStack(spacing: 14) {
                    AgentDisc(agent: .chomp, size: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        TextField("Seu nome", text: $appModel.userName)
                            .font(.system(size: 18, weight: .semibold))
                        Text("Como o Chomp te chama").font(Typography.footnote).foregroundStyle(Palette.muted)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Aparência") {
                Picker("Tema", selection: $appModel.appearance) {
                    ForEach(AppModel.Appearance.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button { router.push(.pairMac) } label: {
                    InfoRow(symbol: "laptopcomputer", symbolTint: Palette.accent, title: "Parear com o Mac", detail: "Não pareado") {
                        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                    }
                }
                .buttonStyle(.plain)
                Button { router.push(.appIcon) } label: {
                    InfoRow(symbol: "app.badge", symbolTint: Palette.accent, title: "Ícone do app", detail: "Escolha quem aparece na tela de início") {
                        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                    }
                }
                .buttonStyle(.plain)
                Button { router.push(.widgetGallery) } label: {
                    InfoRow(symbol: "square.grid.2x2", symbolTint: Palette.accent, title: "Widgets e tela bloqueada", detail: "Veja todos os tamanhos") {
                        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Palette.muted)
                    }
                }
                .buttonStyle(.plain)
                Toggle("Atalho de voz no botão de Ação", isOn: $viewModel.voiceShortcut)
            } header: {
                Text("HeyChomp")
            }

            Section {
                ForEach(Agent.allCases) { agent in
                    Toggle(isOn: viewModel.binding(for: agent)) {
                        HStack(spacing: 10) {
                            AgentAvatar(agent: agent, size: 30, showsRing: false, background: Palette.inset)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(agent.name)
                                Text(agent.role).font(Typography.footnote).foregroundStyle(Palette.muted)
                            }
                        }
                    }
                }
            } header: {
                Text("Notificações")
            } footer: {
                Text("Cada agente avisa só sobre a área dele.")
            }

            Section("Sobre") {
                LabeledContent("Versão", value: viewModel.version)
                Text("Protótipo de design: todos os dados são fictícios e nada é enviado ou salvo.")
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.muted)
                Button("Rever o primeiro uso") {
                    router.popToRoot()
                    appModel.restartOnboarding()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.page.ignoresSafeArea())
        .navigationTitle("Ajustes")
    }
}

#Preview("Ajustes") {
    NavigationStack { SettingsView(viewModel: SettingsViewModel()) }
        .previewEnvironment()
}
