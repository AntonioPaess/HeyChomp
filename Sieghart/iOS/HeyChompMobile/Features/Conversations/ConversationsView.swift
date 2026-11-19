import SwiftUI

/// Histórico de conversas, com os agentes que participaram de cada uma.
struct ConversationsView: View {
    @State private var viewModel: ConversationsViewModel
    @Environment(AppRouter.self) private var router

    init(viewModel: ConversationsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.conversations) { conversation in
                Button { router.push(.chat(conversation.id)) } label: {
                    ConversationRow(conversation: conversation)
                }
                .listRowBackground(Palette.card)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.page.ignoresSafeArea())
        .overlay {
            if viewModel.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            }
        }
        .searchable(text: $viewModel.query, prompt: "Buscar conversas")
        .navigationTitle("Conversas")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.push(.chat(nil)) } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Nova conversa")
            }
        }
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            ParticipantStack(agents: conversation.participants)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conversation.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
                    Spacer()
                    Text(conversation.timestamp).font(Typography.footnote).foregroundStyle(Palette.muted)
                }
                Text(conversation.preview)
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.muted)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Até três avatares sobrepostos.
private struct ParticipantStack: View {
    let agents: [Agent]

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(agents.prefix(3).enumerated()), id: \.element) { index, agent in
                AgentAvatar(agent: agent, size: 30, showsRing: false, background: Palette.inset)
                    .overlay(Circle().stroke(Palette.card, lineWidth: 2))
                    .offset(x: CGFloat(index) * 14)
            }
        }
        .frame(width: 58, alignment: .leading)
        .accessibilityHidden(true)
    }
}

#Preview("Conversas") {
    NavigationStack { ConversationsView(viewModel: ConversationsViewModel()) }
        .previewEnvironment()
}
