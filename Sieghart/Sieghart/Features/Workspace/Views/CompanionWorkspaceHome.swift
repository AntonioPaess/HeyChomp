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
    @State private var hoveredConversation: String?
    @EnvironmentObject private var notch: NotchWidgetViewModel
    @State private var tutorial = false
    @State private var workflow = false
    private var en: Bool { language.hasPrefix("en") }
    private var conversations: [LocalChatConversation] {
        Array(chat.matchingConversations("", archived: false).sorted { $0.updatedAt > $1.updatedAt }.prefix(8))
    }
    private var locale: Locale { Locale(identifier: language) }

    /// Hoje: only real events (conversations, running work, results). Agent nudges will
    /// join this list through the same row primitive once agents produce them.
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            WorkspacePageHeading(title: en ? "Today" : "Hoje", subtitle: subtitle)
            RitaNudgeRow(nudges: notch.ritaNudges)
            RunningNowSection(hidesWhenEmpty: true, perches: true)
            CompanionTeamStrip(language: language, animates: animates, isWorking: isWorking, open: open)
            if !coordinator.taskJournal.tasks.isEmpty || coordinator.taskJournal.storageIssue != nil {
                CompanionTaskShelf(journal: coordinator.taskJournal, language: language,
                    resume: { coordinator.resumeTask($0) }, pause: { coordinator.pauseTask($0) })
            }
            conversationList
            CompanionRoutineShelf(routines: coordinator.routines, language: language)
            if !coordinator.artifacts.items.isEmpty {
                CompanionArtifactShelf(library: coordinator.artifacts, language: language, openSource: { item in
                    if chat.revealSource(of: item) { room.page = .chat; openChat(); return true }
                    return false
                })
            }
            if coordinator.screenAccessIssue == .permission { ScreenPermissionHelp(language: language).companionCard() }
            footer
        }
        .task { await chat.prepare() }
        .sheet(isPresented: $workflow) { CompanionWorkflowComposer(runner: coordinator.workflows, language: language) }
        .sheet(isPresented: $tutorial) { CompanionVoiceTutorial(language: language) }
    }

    private var subtitle: String {
        let day = Date().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
        let count = conversations.count
        let noun = en ? (count == 1 ? "conversation" : "conversations") : (count == 1 ? "conversa" : "conversas")
        return "\(day) · \(count) \(noun)"
    }

    private var conversationList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(en ? "Earlier" : "Mais cedo").font(WorkspaceTypography.caption.weight(.semibold))
                .foregroundStyle(CompanionStyle.muted)
            Button { open(.sig) } label: {
                HStack(spacing: 12) {
                    AvatarView(persona: .sig, size: 28, speaking: isWorking(.sig), animates: animates)
                    Text(en ? "Type to talk to Chomp…" : "Digite para conversar com o Chomp…")
                        .font(WorkspaceTypography.body).foregroundStyle(CompanionStyle.muted)
                    Spacer(minLength: 0)
                }.frame(minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(.plain)
            if conversations.isEmpty {
                Text(en ? "Nothing here yet. Talk to Chomp and your day will show up here." : "Nada por aqui ainda. Converse com o Chomp e seus dias aparecem aqui.")
                    .font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted).padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(conversations) { conversation in
                        conversationRow(conversation)
                        if conversation.id != conversations.last?.id { Divider().padding(.leading, 55) }
                    }
                }
            }
        }
    }

    private func conversationRow(_ conversation: LocalChatConversation) -> some View {
        let person = conversation.persona
        return Button {
            chat.select(conversation.id); room.page = .chat; openChat()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                // Specialists carry a 3 x 16 pt marker in their own color; Chomp, the default voice, has none.
                Capsule().fill(person == .sig ? Color.clear : CompanionStyle.agent(person)).frame(width: 3, height: 16)
                    .accessibilityHidden(true)
                AvatarView(persona: person, size: 28, speaking: isWorking(person), animates: false)
                    .padding(-6)
                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.title).font(WorkspaceTypography.body.weight(.medium)).lineLimit(1)
                    Text(AdaThoughtDisclosure.parse(conversation.messages.last?.text ?? (en ? "Start a conversation" : "Comece uma conversa")).visibleReply)
                        .font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
                if conversation.pinned == true {
                    Image(systemName: "pin.fill").font(.caption2).foregroundStyle(CompanionStyle.muted)
                        .accessibilityLabel(en ? "Pinned" : "Fixada")
                }
                Text(conversation.updatedAt.formatted(.dateTime.hour().minute().locale(locale)))
                    .font(WorkspaceTypography.caption.monospacedDigit()).foregroundStyle(CompanionStyle.muted)
            }
            .padding(.vertical, 10).padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(hoveredConversation == conversation.id ? CompanionStyle.edge.opacity(0.05) : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hoveredConversation = $0 ? conversation.id : nil }
        .contextMenu {
            Button(conversation.pinned == true ? (en ? "Unpin" : "Desafixar") : (en ? "Pin" : "Fixar")) {
                Task { await chat.setPinned(conversation.id, conversation.pinned != true) }
            }
            Button(en ? "Archive" : "Arquivar") {
                Task { await chat.setArchived(conversation.id, true) }
            }.disabled(chat.generatingID == conversation.id)
        }
    }

    private var footer: some View {
        HStack(spacing: 16) {
            Button(en ? "Work in stages" : "Trabalho em etapas") { workflow = true }
            Button(en ? "Learn the gestures" : "Aprender os gestos") { tutorial = true }
            Spacer()
            Button(en ? "Inputs and permissions" : "Ativação e permissões", action: settings)
        }.buttonStyle(.borderless).font(WorkspaceTypography.caption)
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
}

/// The team, large: the characters are the app's identity, so they get room.
/// Tiles animate on hover or keyboard focus; working agents show a dot in their color.
struct CompanionTeamStrip: View {
    let language: String
    let animates: Bool
    var isWorking: (LocalChatPersona) -> Bool = { _ in false }
    var open: (LocalChatPersona) -> Void = { _ in }
    @State private var hovered: LocalChatPersona?
    @FocusState private var focused: LocalChatPersona?
    private var en: Bool { language.hasPrefix("en") }
    private let team: [LocalChatPersona] = [.sig, .rita, .ada, .gantt, .elinor, .toni]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(en ? "Your team" : "Sua equipe").font(WorkspaceTypography.caption.weight(.semibold))
                .foregroundStyle(CompanionStyle.muted)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { ForEach(team, id: \.self) { tile($0).frame(minWidth: 100) } }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(team, id: \.self) { tile($0) }
                }
            }
        }
    }

    private func tile(_ person: LocalChatPersona) -> some View {
        let active = hovered == person || focused == person
        return Button { open(person) } label: {
            VStack(spacing: 6) {
                CompanionCharacter(size: 64, avatar: person.avatar, animates: animates && active,
                    voicePhase: isWorking(person) ? .working : .inactive)
                    .frame(height: 72).accessibilityHidden(true)
                Text(person.title).font(WorkspaceTypography.body.weight(.semibold))
                HStack(spacing: 4) {
                    if isWorking(person) { Circle().fill(CompanionStyle.agent(person)).frame(width: 6, height: 6) }
                    Text(isWorking(person) ? (en ? "Working…" : "Trabalhando…") : CompanionTeamCopy.short(person, en: en))
                        .font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14).padding(.horizontal, 6)
            .background(CompanionStyle.edge.opacity(active ? 0.07 : 0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(CompanionStyle.edge.opacity(0.07), lineWidth: 0.5) }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(active && animates ? 1.02 : 1)
            .animation(.spring(duration: 0.25, bounce: 0.2), value: active)
        }
        .buttonStyle(.plain)
        .focused($focused, equals: person)
        .onHover { hovered = $0 ? person : nil }
        .help(CompanionTeamCopy.long(person, en: en))
        .accessibilityLabel(en ? "Chat with \(person.title), \(CompanionTeamCopy.short(person, en: en))" : "Conversar com \(person.title), \(CompanionTeamCopy.short(person, en: en))")
    }
}

enum CompanionTeamCopy {
    static func short(_ person: LocalChatPersona, en: Bool) -> String {
        switch person {
        case .sig: en ? "Your coordinator" : "Seu coordenador"
        case .rita: en ? "Focus and breaks" : "Foco e pausas"
        case .ada: en ? "Code" : "Código"
        case .gantt: en ? "Your day" : "Seu dia"
        case .elinor: en ? "Resources" : "Recursos"
        case .toni: en ? "Files and writing" : "Arquivos e escrita"
        }
    }
    static func long(_ person: LocalChatPersona, en: Bool) -> String {
        switch person {
        case .sig: en ? "Starts the conversation and brings in the others." : "Começa a conversa e chama os outros."
        case .rita: en ? "Will notice long stretches without moving and help you pace your focus." : "Vai notar longos períodos sem se mexer e ajudar você a dosar o foco."
        case .ada: en ? "Reviews, explains and writes code with you." : "Revisa, explica e escreve código com você."
        case .gantt: en ? "Calendar, reminders and what comes next." : "Agenda, lembretes e o que vem a seguir."
        case .elinor: en ? "Your Mac's battery, memory and usage." : "Bateria, memória e uso do seu Mac."
        case .toni: en ? "Finds, organizes and drafts your files and texts." : "Encontra, organiza e redige seus arquivos e textos."
        }
    }
}

/// Equipe as a character select screen: hover or arrow keys pick a member, who steps onto
/// the stage, introduces themself line by line and lists what they can do.
struct CompanionTeamPage: View {
    let language: String
    let animates: Bool
    var open: (LocalChatPersona) -> Void = { _ in }
    var showsChat = true
    @State private var selected: LocalChatPersona = .sig
    @State private var typed = 0
    @State private var revealTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var en: Bool { language.hasPrefix("en") }
    private let team: [LocalChatPersona] = [.sig, .rita, .ada, .gantt, .elinor, .toni]
    private var profile: CompanionTeamProfile { CompanionTeamProfile.of(selected, en: en) }
    private var moving: Bool { animates && !reduceMotion }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .center, spacing: 36) {
                stage
                details
            }
            .frame(minHeight: 340)
            selector
        }
        .onAppear { reveal() }
        .onChange(of: selected) { _, _ in reveal() }
        .focusable()
        .focusEffectDisabled()
        .onMoveCommand { direction in
            guard let index = team.firstIndex(of: selected) else { return }
            switch direction {
            case .left: selected = team[(index + team.count - 1) % team.count]
            case .right: selected = team[(index + 1) % team.count]
            default: break
            }
        }
        .onKeyPress(.return) { open(selected); return .handled }
    }

    private var stage: some View {
        ZStack(alignment: .bottom) {
            RadialGradient(colors: [CompanionStyle.agent(selected).opacity(0.28), .clear], center: .center, startRadius: 10, endRadius: 170)
                .frame(width: 340, height: 340)
            Ellipse().fill(Color.black.opacity(0.28)).frame(width: 150, height: 22).blur(radius: 6).offset(y: -18)
            ForEach([selected], id: \.self) { person in
                CompanionCharacter(size: 210, avatar: person.avatar, animates: moving)
                    .frame(width: 260, height: 250).offset(y: -26)
                    .transition(.asymmetric(insertion: .scale(scale: 0.85).combined(with: .opacity), removal: .opacity))
            }
        }
        .frame(width: 320, height: 330)
        .animation(moving ? .spring(duration: 0.4, bounce: 0.3) : nil, value: selected)
        .accessibilityHidden(true)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(selected.title).font(.system(size: 34, weight: .bold))
                HStack(spacing: 6) {
                    Capsule().fill(CompanionStyle.agent(selected)).frame(width: 3, height: 14)
                    Text(CompanionTeamCopy.short(selected, en: en)).font(WorkspaceTypography.body).foregroundStyle(CompanionStyle.muted)
                }
            }
            Text(String(profile.intro.prefix(typed)))
                .font(.system(size: 15)).lineSpacing(3)
                .frame(maxWidth: 460, minHeight: 44, alignment: .topLeading)
                .accessibilityLabel(profile.intro)
            VStack(alignment: .leading, spacing: 9) {
                Text(en ? "Abilities" : "Habilidades").font(WorkspaceTypography.caption.weight(.semibold)).foregroundStyle(CompanionStyle.muted)
                ForEach(Array(profile.abilities.enumerated()), id: \.offset) { index, ability in
                    Label(ability.text, systemImage: ability.symbol).font(WorkspaceTypography.body)
                        .opacity(typed >= profile.intro.count || reduceMotion ? 1 : 0.0)
                        .offset(x: typed >= profile.intro.count || !moving ? 0 : -6)
                        .animation(moving ? .spring(duration: 0.35, bounce: 0).delay(Double(index) * 0.06) : nil, value: typed >= profile.intro.count)
                }
            }
            Text(profile.notices).font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted).frame(maxWidth: 460, alignment: .leading)
            if showsChat {
                Button(en ? "Chat with \(selected.title)" : "Conversar com \(selected.title)") { open(selected) }
                    .buttonStyle(CompanionButtonStyle(primary: true)).padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selector: some View {
        HStack(spacing: 10) {
            ForEach(team, id: \.self) { person in
                let isOn = person == selected
                Button { if selected == person { open(person) } else { selected = person } } label: {
                    VStack(spacing: 4) {
                        CompanionCharacter(size: 54, avatar: person.avatar, animates: moving && isOn).frame(height: 60)
                        Text(person.title).font(WorkspaceTypography.caption.weight(isOn ? .semibold : .regular))
                            .foregroundStyle(isOn ? CompanionStyle.ink : CompanionStyle.muted)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(CompanionStyle.edge.opacity(isOn ? 0.07 : 0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isOn ? CompanionStyle.agent(person) : CompanionStyle.edge.opacity(0.07), lineWidth: isOn ? 2 : 0.5)
                    }
                    .scaleEffect(isOn && moving ? 1.04 : 1)
                    .animation(moving ? .spring(duration: 0.25, bounce: 0.25) : nil, value: isOn)
                }
                .buttonStyle(.plain)
                .onHover { if $0 { selected = person } }
                .accessibilityLabel(person.title)
                .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    private func reveal() {
        revealTask?.cancel()
        let total = profile.intro.count
        guard moving else { typed = total; return }
        typed = 0
        revealTask = Task { @MainActor in
            while typed < total, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                typed = min(total, typed + 2)
            }
        }
    }
}

struct CompanionTeamProfile {
    struct Ability { let symbol: String; let text: String }
    let intro: String
    let abilities: [Ability]
    let notices: String

    static func of(_ person: LocalChatPersona, en: Bool) -> CompanionTeamProfile {
        switch person {
        case .sig:
            return .init(intro: en ? "I'm Chomp. Tell me what you need and I'll bring in the right teammate." : "Eu sou o Chomp. Diga o que precisa e eu chamo a pessoa certa da equipe.",
                abilities: [.init(symbol: "bubble.left.and.bubble.right", text: en ? "Talks by voice or text" : "Conversa por voz ou texto"),
                            .init(symbol: "person.2.wave.2", text: en ? "Hands work to specialists" : "Passa o trabalho aos especialistas"),
                            .init(symbol: "text.viewfinder", text: en ? "Reads your screen when you ask" : "Lê a tela quando você pede")],
                notices: en ? "Notices: what you ask and what is running." : "Nota: o que você pede e o que está em andamento.")
        case .rita:
            return .init(intro: en ? "I'm Rita. I keep your focus steady and remind you to stand up." : "Eu sou a Rita. Cuido do seu foco e lembro você de levantar.",
                abilities: [.init(symbol: "leaf", text: en ? "Focus sessions and breaks" : "Sessões de foco e pausas"),
                            .init(symbol: "figure.stand", text: en ? "Stand-up reminders" : "Avisos para levantar"),
                            .init(symbol: "timer", text: en ? "Timers and stopwatch" : "Timers e cronômetro")],
                notices: en ? "Notices: long stretches of continuous use on this Mac." : "Nota: longos períodos de uso contínuo neste Mac.")
        case .ada:
            return .init(intro: en ? "I'm Ada. Show me code and I'll explain, review or write it with you." : "Eu sou a Ada. Me mostre o código e eu explico, reviso ou escrevo com você.",
                abilities: [.init(symbol: "chevron.left.forwardslash.chevron.right", text: en ? "Explains and reviews code" : "Explica e revisa código"),
                            .init(symbol: "arrow.triangle.branch", text: en ? "Reads your GitHub repositories" : "Lê seus repositórios do GitHub"),
                            .init(symbol: "magnifyingglass", text: en ? "Researches in the background" : "Pesquisa em segundo plano")],
                notices: en ? "Notices: repositories you allow her to read." : "Nota: os repositórios que você permitir.")
        case .gantt:
            return .init(intro: en ? "I'm Gantt. I keep your day in order, from the next meeting to the last reminder." : "Eu sou o Gantt. Organizo o seu dia, da próxima reunião ao último lembrete.",
                abilities: [.init(symbol: "calendar", text: en ? "Calendar and reminders" : "Agenda e lembretes"),
                            .init(symbol: "bell", text: en ? "Meeting alerts" : "Alertas de reunião"),
                            .init(symbol: "list.bullet.clipboard", text: en ? "Daily summaries" : "Resumos do dia")],
                notices: en ? "Notices: calendars you share with HeyChomp." : "Nota: as agendas que você compartilhar.")
        case .elinor:
            return .init(intro: en ? "I'm Elinor. I watch your Mac's energy so it keeps up with you." : "Eu sou a Elinor. Cuido da energia do seu Mac para ele acompanhar você.",
                abilities: [.init(symbol: "cpu", text: en ? "System monitor" : "Monitor do sistema"),
                            .init(symbol: "cup.and.saucer", text: en ? "Keep Awake" : "Keep Awake"),
                            .init(symbol: "sun.max", text: en ? "Display and power" : "Tela e energia")],
                notices: en ? "Notices: battery, memory and temperature." : "Nota: bateria, memória e temperatura.")
        case .toni:
            return .init(intro: en ? "I'm Toni. I find, organize and draft your files and texts." : "Eu sou o Toni. Encontro, organizo e escrevo seus arquivos e textos.",
                abilities: [.init(symbol: "tray", text: en ? "Library and files" : "Biblioteca e arquivos"),
                            .init(symbol: "doc.on.clipboard", text: en ? "Clipboard history" : "Histórico da área de transferência"),
                            .init(symbol: "viewfinder", text: en ? "Screen capture" : "Captura de tela")],
                notices: en ? "Notices: files you drop on him and what you copy." : "Nota: arquivos que você soltar e o que você copiar.")
        }
    }
}
