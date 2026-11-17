import SwiftUI

// Sieg owns these conversations. Coucou's MIT chat layout and interaction are
// reused through AgentChatBackground, AgentChatBubble and AgentChatComposer;
// generation uses Apple's on-device model or Private Cloud Compute with thinking.
struct AgentRoomView: View {
    @ObservedObject var model: AgentRoomViewModel
    var compact = false
    var observesActivity = true

    var body: some View {
        LocalAgentRoomView(room: model, chat: model.localChat, compact: compact, active: observesActivity)
    }
}

private struct LocalAgentRoomView: View {
    @ObservedObject var room: AgentRoomViewModel
    @ObservedObject var chat: LocalChatViewModel
    var compact: Bool
    var active: Bool
    @Environment(\.islandPreview) private var preview
    @State private var settings = false
    @Environment(\.locale) private var locale
    private var en: Bool { locale.language.languageCode?.identifier == "en" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Button { room.page = .room } label: {
                        Label(en ? "Conversations" : "Conversas", systemImage: "square.grid.2x2")
                            .font(AdaRoomTheme.badgeFont(size: 11))
                            .foregroundStyle(room.page == .room ? CompanionStyle.ink : CompanionStyle.muted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background {
                                if room.page == .room {
                                    Capsule().fill(CompanionStyle.edge.opacity(0.10))
                                }
                            }
                    }.buttonStyle(.plain)

                    Button {
                        Task {
                            if chat.selected == nil { _ = await chat.create() }
                            room.page = .chat
                        }
                    } label: {
                        Label(en ? "Chat" : "Conversa", systemImage: "bubble.left.and.bubble.right.fill")
                            .font(AdaRoomTheme.badgeFont(size: 11))
                            .foregroundStyle(room.page == .chat ? CompanionStyle.ink : CompanionStyle.muted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background {
                                if room.page == .chat {
                                    Capsule().fill(CompanionStyle.edge.opacity(0.10))
                                }
                            }
                    }.buttonStyle(.plain)
                }
                .padding(2.5)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 0.7) }

                Spacer(minLength: 0)

                HStack(spacing: 5) {
                    Image(systemName: "apple.intelligence")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.52, green: 0.62, blue: 1.0),
                                    Color(red: 0.78, green: 0.48, blue: 0.98)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(en ? chat.configuration.mode.shortTitle : (chat.configuration.mode == .privateCloudThinking ? "Apple Cloud" : "Neste Mac"))
                        .font(AdaRoomTheme.badgeFont(size: 10.5))
                        .foregroundStyle(CompanionStyle.ink.opacity(0.85))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 0.7) }
                .help(Text(LocalizedStringKey(chat.configuration.mode.explanation)))

                Button { settings = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CompanionStyle.ink.opacity(0.85))
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay { Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7) }
                }
                .buttonStyle(.plain)
                .help(en ? "Conversation settings · model and GitHub" : "Configurações das conversas · modelo e GitHub")
                .accessibilityLabel(en ? "Conversation settings" : "Configurações das conversas")
            }.frame(height: 26)
            if room.page == .room {
                LocalChatRooms(chat: chat, compact: compact) { id in chat.select(id); room.page = .chat }
                    .frame(height: compact ? nil : 370)
            } else if let selected = chat.selected {
                LocalChatPrompt(chat: chat, conversation: selected, compact: compact, active: active)
            } else {
                VStack(spacing: 12) {
                    CompanionCharacter(size: 56, avatar: .sig, animates: false)
                    Text(en ? "A small next step, together." : "Um próximo passo, juntos.")
                        .font(AdaRoomTheme.titleFont(size: 15))
                    Button(en ? "New chat" : "Nova conversa") { Task { _ = await chat.create(); room.page = .chat } }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(CompanionStyle.ink)
        .frame(maxWidth: .infinity, maxHeight: compact ? .infinity : nil, alignment: .topLeading)
        .tint(CompanionStyle.accentInk)
        .buttonStyle(CompanionButtonStyle(compact: true))
        .focusEffectDisabled()
        .task { if !preview { await chat.prepare() } }
        .sheet(isPresented: $settings) { AdaChatSettingsView(chat: chat) }
    }
}

private struct LocalChatRooms: View {
    @ObservedObject var chat: LocalChatViewModel
    var compact: Bool
    var open: (String) -> Void
    @Environment(\.locale) private var locale
    @Environment(\.islandPreview) private var preview
    private var en: Bool { locale.language.languageCode?.identifier == "en" }
    @State private var page = 0
    private let pageSize = 5
    private var pages: Int { max(1, (chat.conversations.count + pageSize - 1) / pageSize) }
    private var visible: [LocalChatConversation] { Array(chat.conversations.dropFirst(page * pageSize).prefix(pageSize)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Choose a conversation, or start a new one.")
                    .font(AdaRoomTheme.bodyFont(size: 11.5))
                    .foregroundStyle(CompanionStyle.muted)
                if preview {
                    Label(en ? "Talk to…" : "Conversar com…", systemImage: "chevron.down")
                        .font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.accentInk)
                } else {
                    Menu("Talk to…") {
                        ForEach(LocalChatPersona.allCases, id: \.rawValue) { persona in
                            Button(persona.title + " · " + persona.avatar.subtitle) {
                                Task { if let id = await chat.create(persona) { open(id) } }
                            }
                        }
                    }.menuStyle(.borderlessButton).fixedSize()
                }
                Spacer(minLength: 0)
                if pages > 1 {
                    Button { page = max(0, page - 1) } label: { Image(systemName: "chevron.left") }.disabled(page == 0)
                    Text("\(page + 1) / \(pages)").font(AdaRoomTheme.badgeFont(size: 10))
                    Button { page = min(pages - 1, page + 1) } label: { Image(systemName: "chevron.right") }.disabled(page + 1 >= pages)
                }
            }.frame(height: 22)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(visible) { conversation in
                    Button { open(conversation.id) } label: { card(conversation) }.buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete conversation", role: .destructive) { Task { await chat.delete(conversation.id) } }
                        }
                }
                Button {
                    Task { if let id = await chat.create() { open(id) } }
                } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(CompanionStyle.edge.opacity(0.06))
                                .frame(width: 38, height: 38)
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(CompanionStyle.accentInk)
                        }
                        Text(en ? "New chat" : "Nova conversa")
                            .font(AdaRoomTheme.badgeFont(size: 11.5))
                            .foregroundStyle(CompanionStyle.ink.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: compact ? 120 : 150)
                    .modifier(WorkspaceSurface(radius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                CompanionStyle.edge.opacity(0.15),
                                style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                            )
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }.buttonStyle(.plain).disabled(chat.loading).accessibilityLabel(en ? "Create a new conversation with Chomp" : "Criar uma nova conversa com o Chomp")
            }
            if let notice = chat.notice {
                Text(notice)
                    .font(AdaRoomTheme.badgeFont(size: 11))
                    .foregroundStyle(CompanionStyle.muted)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
            if chat.conversations.isEmpty {
                Text(chat.loading ? (en ? "Reading saved conversations…" : "Lendo suas conversas…") : (en ? "Start with Chomp. Your specialists are a conversation away." : "Comece com o Chomp. Seus especialistas estão a uma conversa de distância."))
                    .font(AdaRoomTheme.bodyFont(size: 11.5))
                    .foregroundStyle(CompanionStyle.muted)
            }
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onChange(of: chat.conversations.count) { _, _ in page = min(page, pages - 1) }
    }
    private func card(_ conversation: LocalChatConversation) -> some View {
        let isSelected = chat.selectedID == conversation.id
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Spacer()
                CompanionCharacter(size: compact ? 38 : 48, avatar: conversation.persona.avatar, animates: false)
                Spacer()
            }.frame(height: compact ? 50 : 66)
            Text(conversation.title)
                .font(AdaRoomTheme.titleFont(size: 11.5))
                .foregroundStyle(CompanionStyle.ink)
                .lineLimit(1)
            Text(chat.generatingID == conversation.id ? (en ? "Replying…" : "Respondendo…") : conversation.messages.last?.text ?? (en ? "Start a conversation with \(conversation.persona.title)." : "Comece uma conversa com \(conversation.persona.title)."))
                .font(AdaRoomTheme.bodyFont(size: 10.5))
                .foregroundStyle(CompanionStyle.muted)
                .lineLimit(2)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: compact ? 120 : 150)
        .modifier(WorkspaceSurface(selected: isSelected, radius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Conversas on the workspace page, in the iPhone app's language: a list of cards with
/// the teammates' faces on the left and the open conversation on the right, so the
/// page is used edge to edge instead of a small chat in a large empty area.
struct WorkspaceConversations: View {
    @ObservedObject var room: AgentRoomViewModel
    @ObservedObject var chat: LocalChatViewModel
    @State private var query = ""
    @State private var hovered: String?
    @State private var settings = false
    @Environment(\.locale) private var locale
    @Environment(\.islandPreview) private var preview
    private var en: Bool { locale.language.languageCode?.identifier == "en" }
    private var items: [LocalChatConversation] {
        chat.matchingConversations(query, archived: false).sorted {
            ($0.pinned == true ? 1 : 0, $0.updatedAt) > ($1.pinned == true ? 1 : 0, $1.updatedAt)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            list.frame(width: 310)
            conversation
        }
        .frame(minHeight: 600, alignment: .top)
        .task { if !preview { await chat.prepare() } }
        .sheet(isPresented: $settings) { AdaChatSettingsView(chat: chat) }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundStyle(CompanionStyle.muted)
                    TextField(en ? "Search conversations" : "Buscar conversas", text: $query).textFieldStyle(.plain)
                }
                .padding(.horizontal, 12).frame(height: 32)
                .background(CompanionStyle.edge.opacity(0.05), in: Capsule())
                Button { Task { _ = await chat.create(); room.page = .chat } } label: {
                    Image(systemName: "square.and.pencil").font(.system(size: 13, weight: .semibold)).foregroundStyle(CompanionStyle.accent)
                        .frame(width: 32, height: 32).background(CompanionStyle.edge.opacity(0.05), in: Circle())
                }.buttonStyle(.plain).focusEffectDisabled().help(en ? "New conversation" : "Nova conversa")
                Button { settings = true } label: {
                    Image(systemName: "slider.horizontal.3").font(.system(size: 12, weight: .semibold)).foregroundStyle(CompanionStyle.muted)
                        .frame(width: 32, height: 32).background(CompanionStyle.edge.opacity(0.05), in: Circle())
                }.buttonStyle(.plain).focusEffectDisabled()
                    .help(en ? "Conversation settings · model and GitHub" : "Configurações das conversas · modelo e GitHub")
            }
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(items) { row($0) }
                    if items.isEmpty {
                        OwnerSays(persona: .sig, text: LocalizedStringKey(query.isEmpty
                            ? (en ? "No conversations yet. Say hi and we'll start one." : "Nenhuma conversa ainda. Diga oi e a gente começa.")
                            : (en ? "Nothing matches that search." : "Nada combina com essa busca.")))
                            .padding(.top, 8)
                    }
                }
            }.scrollIndicators(.hidden)
        }
        .heyCard(padding: 10, radius: 20)
        .frame(maxHeight: 640)
    }

    private func row(_ item: LocalChatConversation) -> some View {
        let isOn = chat.selected?.id == item.id
        return Button { chat.select(item.id); room.page = .chat } label: {
            HStack(alignment: .top, spacing: 10) {
                faces(item.persona).padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        if item.pinned == true { Image(systemName: "pin.fill").font(.system(size: 9)).foregroundStyle(CompanionStyle.muted) }
                        Spacer(minLength: 4)
                        Text(item.updatedAt.formatted(.dateTime.hour().minute().locale(locale)))
                            .font(.system(size: 10).monospacedDigit()).foregroundStyle(CompanionStyle.muted)
                    }
                    Text(AdaThoughtDisclosure.parse(item.messages.last?.text ?? (en ? "Start a conversation" : "Comece uma conversa")).visibleReply)
                        .font(.system(size: 11)).foregroundStyle(CompanionStyle.muted).lineLimit(2)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isOn ? CompanionStyle.accent.opacity(0.14) : hovered == item.id ? CompanionStyle.edge.opacity(0.05) : .clear,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain).focusEffectDisabled()
        .onHover { hovered = $0 ? item.id : nil }
        .contextMenu {
            Button(item.pinned == true ? (en ? "Unpin" : "Desafixar") : (en ? "Pin" : "Fixar")) { Task { await chat.setPinned(item.id, item.pinned != true) } }
            Button(en ? "Archive" : "Arquivar") { Task { await chat.setArchived(item.id, true) } }.disabled(chat.generatingID == item.id)
        }
    }

    /// Chomp always takes the request; a specialist who joined sits in front of him.
    private func faces(_ persona: LocalChatPersona) -> some View {
        ZStack(alignment: .bottomTrailing) {
            AgentRingAvatar(persona: .sig, size: persona == .sig ? 34 : 26)
                .offset(x: persona == .sig ? 0 : -8, y: persona == .sig ? 0 : -6)
            if persona != .sig { AgentRingAvatar(persona: persona, size: 26) }
        }.frame(width: 36, height: 34)
    }

    @ViewBuilder private var conversation: some View {
        Group {
            if let selected = chat.selected {
                LocalChatPrompt(chat: chat, conversation: selected, compact: false, active: true)
            } else {
                VStack(spacing: 12) {
                    AgentDisc(persona: .sig, size: 96)
                    Text(en ? "A small next step, together." : "Um próximo passo, juntos.").font(.system(size: 17, weight: .semibold))
                    Button { Task { _ = await chat.create(); room.page = .chat } } label: {
                        Text(en ? "New conversation" : "Nova conversa").modifier(ChompPill(primary: true))
                    }.buttonStyle(.plain)
                }.frame(maxWidth: .infinity, minHeight: 560)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .heyCard(padding: 12, radius: 20)
    }
}
