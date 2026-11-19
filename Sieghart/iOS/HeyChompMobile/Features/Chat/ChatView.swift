import SwiftUI

/// Conversa: balões da pessoa e do Chomp, cartões de repasse para a equipe,
/// sugestões em pílulas e barra de mensagem com microfone.
struct ChatView: View {
    @State private var viewModel: ChatViewModel
    @Environment(AppRouter.self) private var router

    init(viewModel: ChatViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text("Hoje, \(viewModel.conversation.timestamp)")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    ForEach(viewModel.messages) { message in
                        MessageRow(message: message) { agent in router.push(.agent(agent)) }
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) {
                withAnimation(Motion.page) { proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom) }
            }
        }
        .background(Palette.page.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { composer }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(viewModel.title).font(.system(size: 16, weight: .semibold))
                    HStack(spacing: 5) {
                        Circle().fill(Palette.accent).frame(width: 6, height: 6)
                        Text(viewModel.subtitle).font(.system(size: 12)).foregroundStyle(Palette.muted)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Histórico", systemImage: "clock") { router.push(.conversations) }
                    Button("Ver equipe", systemImage: "person.3") { router.push(.team) }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                        Button {
                            viewModel.useSuggestion(suggestion)
                        } label: {
                            if suggestion == viewModel.suggestions.first {
                                Label(suggestion, systemImage: "sparkle")
                            } else {
                                Text(suggestion)
                            }
                        }
                        .buttonStyle(.chompSecondary)
                    }
                }
                .padding(.horizontal, 14)
            }
            MessageComposer(
                text: $viewModel.draft,
                onPlus: { router.present(.attachments) },
                onMic: { router.startVoiceSession() },
                onSend: viewModel.send
            )
            .padding(.horizontal, 14)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Palette.page.opacity(0.96).ignoresSafeArea())
    }
}

/// Uma linha da conversa, conforme o tipo de mensagem.
private struct MessageRow: View {
    let message: ChatMessage
    var onOpenAgent: (Agent) -> Void

    var body: some View {
        switch message.kind {
        case .user:
            MessageBubble(text: message.text, isUser: true)
                .frame(maxWidth: 300, alignment: .trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        case .agent(let agent):
            HStack(alignment: .bottom, spacing: 8) {
                AgentAvatar(agent: agent, size: 30, showsRing: false)
                MessageBubble(text: message.text, isUser: false)
                    .frame(maxWidth: 290, alignment: .leading)
            }
        case .handoff(let handoff):
            Button { onOpenAgent(handoff.agent) } label: {
                HandoffCard(handoff: handoff)
            }
            .buttonStyle(.plain)
            .padding(.leading, 38)
        case .typing(let agent):
            HStack(alignment: .bottom, spacing: 8) {
                AgentAvatar(agent: agent, size: 30, showsRing: false)
                TypingDots()
            }
        case .notice:
            Label(message.text, systemImage: "info.circle")
                .font(Typography.footnote)
                .foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
    }
}

/// Repasse do Chomp para um especialista, com o especialista espiando.
struct HandoffCard: View {
    let handoff: Handoff

    var body: some View {
        PerchedCard(agent: handoff.agent, peekWidth: 66) {
            VStack(alignment: .leading, spacing: 2) {
                Text(handoff.caption).font(Typography.caption).foregroundStyle(Palette.muted)
                Text(handoff.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.ink)
                Text(handoff.detail).font(Typography.footnote).foregroundStyle(Palette.muted)
            }
            .padding(.leading, 64)
            .padding(.top, -18)
        }
    }
}

#Preview("Conversa") {
    NavigationStack { ChatView(viewModel: ChatViewModel()) }
        .previewEnvironment()
}
