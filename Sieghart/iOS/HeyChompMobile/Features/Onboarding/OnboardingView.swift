import SwiftUI

/// Primeiro uso: o Chomp se apresenta, mostra a equipe e pede as permissões.
struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    @Environment(AppModel.self) private var appModel
    @Environment(AppRouter.self) private var router

    init(viewModel: OnboardingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                Group {
                    switch viewModel.step {
                    case .welcome: WelcomeStep(viewModel: viewModel)
                    case .team: TeamStep(viewModel: viewModel)
                    case .permissions: PermissionsStep(viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 24)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            }
            .scrollDismissesKeyboard(.interactively)
            footer
        }
        .background(Palette.page.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            if viewModel.step != .welcome {
                Button { viewModel.back() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Palette.ink)
                .accessibilityLabel("Voltar")
            }
            Spacer()
        }
        .frame(height: 32)
        .overlay(StepDots(count: OnboardingViewModel.Step.allCases.count, current: viewModel.step.rawValue))
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Button(viewModel.primaryTitle) {
                if viewModel.advance() {
                    appModel.completeOnboarding(name: viewModel.name)
                }
            }
            .buttonStyle(.chompLarge)
            .disabled(!viewModel.canContinue)
            .opacity(viewModel.canContinue ? 1 : 0.5)

            if viewModel.step == .welcome {
                Button {
                    router.present(.pairMac)
                } label: {
                    Label("Já uso o HeyChomp no Mac", systemImage: "laptopcomputer")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .frame(height: 40)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}

/// Indicador de passos: o atual vira uma cápsula menta.
private struct StepDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Palette.accent : Palette.ink.opacity(0.15))
                    .frame(width: index == current ? 20 : 6, height: 6)
            }
        }
        .animation(Motion.page, value: current)
        .accessibilityElement()
        .accessibilityLabel("Passo \(current + 1) de \(count)")
    }
}

// MARK: - Passos

/// Passo 1: o Chomp pergunta o nome.
private struct WelcomeStep: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 4) {
                SpeechBubble(text: "Oi! Eu sou o Chomp. Eu e a equipe também cuidamos do seu dia pelo iPhone.", tailPosition: 0.42)
                Image(Agent.chomp.portraitImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 210, height: 210)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)

            Text("Como posso te chamar?")
                .font(Typography.largeTitle)
                .padding(.top, 18)

            TextField("Seu nome", text: $viewModel.name)
                .font(.system(size: 19, weight: .medium))
                .textContentType(.givenName)
                .submitLabel(.continue)
                .focused($isNameFocused)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.card))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isNameFocused ? Palette.accent : Palette.separator, lineWidth: 1.5)
                )
                .padding(.top, 18)

            Text("Dá para mudar depois em Ajustes.")
                .font(Typography.footnote)
                .foregroundStyle(Palette.muted)
                .padding(.top, 10)
                .padding(.leading, 4)
        }
    }
}

/// Passo 2: os seis cartões com o personagem espiando.
private struct TeamStep: View {
    let viewModel: OnboardingViewModel

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.teamTitle)
                .font(Typography.largeTitle)
                .padding(.top, 16)
            Text("Cada um cuida de uma parte do dia. Fale com o Chomp e ele chama quem precisa.")
                .font(Typography.body)
                .foregroundStyle(Palette.muted)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(viewModel.team) { agent in
                    TeamIntroCard(agent: agent)
                }
            }
            .padding(.top, 8)
        }
    }
}

private struct TeamIntroCard: View {
    let agent: Agent

    var body: some View {
        PerchedCard(agent: agent, placement: .center, peekWidth: 84) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Circle().fill(agent.tint).frame(width: 8, height: 8)
                    Text(agent.name).font(.system(size: 16, weight: .bold))
                }
                Text(agent.role)
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                if let upcoming = agent.upcomingFeature, agent != .gantt {
                    SoonPill(text: upcoming).padding(.top, 4)
                }
            }
        }
    }
}

/// Passo 3: permissões, cada uma com o agente que vai usá-la.
private struct PermissionsStep: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("O que a equipe pode usar?")
                .font(Typography.largeTitle)
                .padding(.top, 16)
            Text("Você pode mudar cada uma depois. Nada é pedido ao sistema neste protótipo.")
                .font(Typography.body)
                .foregroundStyle(Palette.muted)

            VStack(spacing: 0) {
                ForEach(viewModel.permissions) { permission in
                    InfoRow(symbol: permission.symbol, symbolTint: permission.owner.tint, title: permission.title, detail: permission.detail) {
                        Toggle("", isOn: Binding(
                            get: { viewModel.isEnabled(permission) },
                            set: { _ in viewModel.toggle(permission) }
                        ))
                        .labelsHidden()
                    }
                    if permission.id != viewModel.permissions.last?.id {
                        Divider().padding(.leading, 44)
                    }
                }
            }
            .cardStyle(padding: 14)
            .padding(.top, 12)

            HStack(spacing: 10) {
                AgentAvatar(agent: .chomp, size: 34, showsRing: false)
                Text("O Chomp avisa quando alguém da equipe precisar de algo novo.")
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.muted)
            }
            .padding(.top, 8)
        }
    }
}

#Preview("Primeiro uso") {
    OnboardingView(viewModel: OnboardingViewModel())
        .previewEnvironment(onboarded: false)
}
