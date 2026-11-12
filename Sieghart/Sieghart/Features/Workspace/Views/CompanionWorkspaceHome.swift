import SwiftUI

struct CompanionWorkspaceHome: View {
    @ObservedObject var room: AgentRoomViewModel
    @ObservedObject var chat: LocalChatViewModel
    @ObservedObject var coordinator: SpatialAssistantCoordinator
    let language: String
    let animates: Bool
    let openChat: () -> Void
    let speak: () -> Void
    let settings: () -> Void
    @Environment(\.islandPreview) private var preview
    @State private var query = ""
    @State private var showArchived = false
    @State private var hovered: LocalChatPersona?
    @State private var hoveredConversation: String?
    @State private var tutorial = false
    @State private var workflow = false
    @FocusState private var focusedPersona: LocalChatPersona?
    private let team: [LocalChatPersona] = [.sig, .rita, .ada, .gantt, .elinor, .toni]
    private var en: Bool { language.hasPrefix("en") }
    private var conversations: [LocalChatConversation] { chat.matchingConversations(query, archived: showArchived) }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            welcome
            teamSection
            Divider()
            conversationSection
            if !coordinator.taskJournal.tasks.isEmpty || coordinator.taskJournal.storageIssue != nil {
                Divider()
                CompanionTaskShelf(journal: coordinator.taskJournal, language: language,
                    resume: { coordinator.resumeTask($0) }, pause: { coordinator.pauseTask($0) })
            }
            Divider()
            CompanionRoutineShelf(routines: coordinator.routines, language: language)
            if !coordinator.artifacts.items.isEmpty {
                Divider()
                CompanionArtifactShelf(library: coordinator.artifacts, language: language, openSource: { item in
                    if chat.revealSource(of: item) { room.page = .chat; openChat(); return true }
                    return false
                })
            }
            if coordinator.screenAccessIssue == .permission { ScreenPermissionHelp(language: language).companionCard() }
            Divider()
            HStack {
                Button(en ? "Learn the gestures" : "Aprender os gestos") { tutorial = true }
                Spacer()
                Button(en ? "Inputs and permissions" : "Ativação e permissões", action: settings)
            }.buttonStyle(.borderless).font(WorkspaceTypography.caption)
        }
        .task { await chat.prepare() }
        .sheet(isPresented: $workflow) { CompanionWorkflowComposer(runner: coordinator.workflows, language: language) }
        .sheet(isPresented: $tutorial) { CompanionVoiceTutorial(language: language) }
    }

    private var welcome: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text(en ? "Your day, with Chomp" : "Seu dia, com o Chomp")
                    .font(WorkspaceTypography.caption.weight(.medium)).foregroundStyle(CompanionStyle.muted)
                Text(en ? "What shall we start with?" : "Por onde vamos começar?")
                    .font(.system(size: 30, weight: .semibold, design: .rounded)).tracking(-0.6)
                    .fixedSize(horizontal: false, vertical: true)
                Text(en ? "Bring an idea, ask a question or pick up where you left off." : "Traga uma ideia, tire uma dúvida ou retome de onde parou.")
                    .font(WorkspaceTypography.body).foregroundStyle(CompanionStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    Button { open(.sig) } label: {
                        Label(en ? "Chat with Chomp" : "Conversar com o Chomp", systemImage: "bubble.left")
                    }.buttonStyle(.borderedProminent)
                    Button(action: speak) { Label(en ? "Speak" : "Falar", systemImage: "mic") }
                        .buttonStyle(.bordered)
                }.controlSize(.large).padding(.top, 4)
            }.frame(maxWidth: .infinity, alignment: .leading)
            CompanionCharacter(size: 164, avatar: .sig, animates: animates,
                voicePhase: isWorking(.sig) ? .working : .inactive)
                .frame(width: 164, height: 182).accessibilityHidden(true)
        }.padding(.vertical, 8)
    }

    private var teamSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(en ? "Your team" : "Sua equipe").font(WorkspaceTypography.section)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { ForEach(team, id: \.self) { person in teamMember(person).frame(minWidth: 96) } }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(team, id: \.self) { person in teamMember(person) }
                }
            }
        }
    }

    private func teamMember(_ person: LocalChatPersona) -> some View {
        Button { open(person) } label: {
            VStack(spacing: 6) {
                CompanionCharacter(size: 78, avatar: person.avatar,
                    animates: animates && (hovered == person || focusedPersona == person),
                    voicePhase: isWorking(person) ? .working : .inactive)
                    .accessibilityHidden(true)
                Text(person.title).font(.system(size: 13, weight: .semibold))
                Text(isWorking(person) ? (en ? "Working…" : "Trabalhando…") : role(person))
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                    .lineLimit(2).multilineTextAlignment(.center).frame(height: 27, alignment: .top)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10).padding(.horizontal, 5)
            .background(hovered == person ? CompanionStyle.edge.opacity(0.04) : .clear, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .focused($focusedPersona, equals: person)
        .onHover { hovered = $0 ? person : nil }
        .help(role(person))
        .accessibilityLabel(en ? "Chat with \(person.title), \(role(person))" : "Conversar com \(person.title), \(role(person))")
        .accessibilityValue(isWorking(person) ? (en ? "Working" : "Trabalhando") : "")
    }

    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text(showArchived ? (en ? "Archived conversations" : "Conversas arquivadas") : (en ? "Conversations" : "Conversas"))
                    .font(WorkspaceTypography.section)
                Text("\(conversations.count)").font(WorkspaceTypography.caption).foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Toggle(en ? "Show archived" : "Mostrar arquivadas", isOn: $showArchived)
                    Divider()
                    Button(en ? "Work in stages" : "Trabalho em etapas") { workflow = true }
                } label: { Label(en ? "Organize" : "Organizar", systemImage: "line.3.horizontal.decrease") }
                Menu {
                    ForEach(team, id: \.self) { person in
                        Button(person.title) {
                            Task { if await chat.create(person) != nil { room.page = .chat; openChat() } }
                        }
                    }
                } label: { Label(en ? "New conversation" : "Nova conversa", systemImage: "plus") }
            }.controlSize(.regular)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                if preview { Text(en ? "Search conversations" : "Buscar conversas").foregroundStyle(.secondary) }
                else { TextField(en ? "Search conversations" : "Buscar conversas", text: $query).textFieldStyle(.plain) }
                if !query.isEmpty {
                    Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).accessibilityLabel(en ? "Clear search" : "Limpar busca")
                }
            }
            .font(WorkspaceTypography.body).padding(10)
            .background(CompanionStyle.edge.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
            if conversations.isEmpty {
                WorkspaceEmptyState(title: emptyTitle, detail: emptyDetail,
                    symbol: query.isEmpty ? "bubble.left.and.bubble.right" : "magnifyingglass")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(conversations) { conversation in
                        conversationRow(conversation)
                        if conversation.id != conversations.last?.id { Divider().padding(.leading, 58) }
                    }
                }
            }
        }
    }

    private func conversationRow(_ conversation: LocalChatConversation) -> some View {
        Button {
            chat.select(conversation.id); room.page = .chat; openChat()
        } label: {
            HStack(alignment: .center, spacing: 14) {
                CompanionCharacter(size: 36, avatar: conversation.persona.avatar, animates: false).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(conversation.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        if conversation.pinned == true {
                            Image(systemName: "pin.fill").font(.caption2).foregroundStyle(CompanionStyle.accentInk)
                                .accessibilityLabel(en ? "Pinned" : "Fixada")
                        }
                    }
                    Text(AdaThoughtDisclosure.parse(conversation.messages.last?.text ?? (en ? "Start a conversation" : "Comece uma conversa")).visibleReply)
                        .font(WorkspaceTypography.caption).foregroundStyle(.secondary).lineLimit(2)
                }.frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 5) {
                    Text(conversation.persona.title).font(WorkspaceTypography.caption)
                    Text(conversation.updatedAt, style: .relative).font(.system(size: 10)).foregroundStyle(.secondary)
                }.frame(width: 96, alignment: .trailing)
            }
            .padding(.horizontal, 8).padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(hoveredConversation == conversation.id ? CompanionStyle.edge.opacity(0.035) : .clear, in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hoveredConversation = $0 ? conversation.id : nil }
        .contextMenu {
            Button(conversation.pinned == true ? (en ? "Unpin" : "Desafixar") : (en ? "Pin" : "Fixar")) {
                Task { await chat.setPinned(conversation.id, conversation.pinned != true) }
            }
            Button(showArchived ? (en ? "Restore" : "Restaurar") : (en ? "Archive" : "Arquivar")) {
                Task { await chat.setArchived(conversation.id, !showArchived) }
            }.disabled(chat.generatingID == conversation.id)
        }
    }

    private var emptyTitle: String {
        if !query.isEmpty { return en ? "No conversations found" : "Nenhuma conversa encontrada" }
        if showArchived { return en ? "No archived conversations" : "Nenhuma conversa arquivada" }
        return en ? "A conversation starts here" : "Uma conversa começa aqui"
    }
    private var emptyDetail: String {
        if !query.isEmpty { return en ? "Try another word from a title or message." : "Tente outra palavra do título ou das mensagens." }
        if showArchived { return en ? "Conversations you archive appear here." : "As conversas que você arquivar aparecem aqui." }
        return en ? "Choose Chomp or a specialist above. Your history stays close by." : "Escolha o Chomp ou um especialista acima. Seu histórico fica sempre por perto."
    }
    private func open(_ person: LocalChatPersona) {
        Task { if await chat.openPersona(person) != nil { room.page = .chat; openChat() } }
    }
    private func isWorking(_ person: LocalChatPersona) -> Bool {
        if chat.generatingID.flatMap({ id in chat.conversations.first { $0.id == id }?.persona }) == person { return true }
        return coordinator.taskJournal.tasks.contains { task in
            task.state == .running && task.workflow?.first(where: { $0.result == nil }).map { $0.kind == .research ? person == .sig : $0.persona == person } == true
        }
    }
    private func role(_ person: LocalChatPersona) -> String {
        switch person {
        case .sig: en ? "Your coordinator" : "Seu coordenador"
        case .ada: en ? "Code" : "Código"
        case .rita: en ? "Focus and breaks" : "Foco e pausas"
        case .gantt: en ? "Your day" : "Seu dia"
        case .elinor: en ? "Resources" : "Recursos"
        case .toni: en ? "Files and writing" : "Arquivos e escrita"
        }
    }
}
