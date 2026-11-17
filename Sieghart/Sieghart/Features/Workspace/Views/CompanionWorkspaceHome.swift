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
    var openCalendar: () -> Void = {}
    @State private var hoveredConversation: String?
    @EnvironmentObject private var notch: NotchWidgetViewModel
    @EnvironmentObject private var assistant: AssistantViewModel
    @AppStorage("companion.userName") private var userName = ""
    @State private var tutorial = false
    @State private var workflow = false
    private var en: Bool { language.hasPrefix("en") }
    private var conversations: [LocalChatConversation] {
        Array(chat.matchingConversations("", archived: false).sorted { $0.updatedAt > $1.updatedAt }.prefix(8))
    }
    private var locale: Locale { Locale(identifier: language) }

    /// Hoje, in the iPhone app's language: a greeting, the team with live status, an ask
    /// bar, Chomp's suggestion, Gantt's day and the conversations. Only real data.
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .bottom, spacing: 24) {
                greeting
                Spacer(minLength: 16)
                teamRow
            }
            AskChompBar(prompt: en ? "Ask Chomp" : "Pergunte ao Chomp", type: { open(.sig) }, speak: speak)
            // Two columns on a wide window, one on a narrow one: no empty stretches.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 16) { mainColumn }.frame(minWidth: 460, maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 16) { sideColumn }.frame(width: 330)
                }
                VStack(alignment: .leading, spacing: 16) { mainColumn; sideColumn }
            }
            footer
        }
        .task { await chat.prepare() }
        .sheet(isPresented: $workflow) { CompanionWorkflowComposer(runner: coordinator.workflows, language: language) }
        .sheet(isPresented: $tutorial) { CompanionVoiceTutorial(language: language) }
    }

    @ViewBuilder private var mainColumn: some View {
        RitaNudgeRow(nudges: notch.ritaNudges)
        chompSuggestion
        conversationList
        if !coordinator.artifacts.items.isEmpty {
            CompanionArtifactShelf(library: coordinator.artifacts, language: language, openSource: { item in
                if chat.revealSource(of: item) { room.page = .chat; openChat(); return true }
                return false
            })
        }
        if coordinator.screenAccessIssue == .permission { ScreenPermissionHelp(language: language).companionCard() }
    }

    @ViewBuilder private var sideColumn: some View {
        HomeTodayCard(calendar: notch.calendar, en: en, locale: locale, animates: animates, openCalendar: openCalendar)
        teamWorking
        RunningNowSection(hidesWhenEmpty: true, perches: true)
        if !coordinator.taskJournal.tasks.isEmpty || coordinator.taskJournal.storageIssue != nil {
            CompanionTaskShelf(journal: coordinator.taskJournal, language: language,
                resume: { coordinator.resumeTask($0) }, pause: { coordinator.pauseTask($0) })
        }
        CompanionRoutineShelf(routines: coordinator.routines, language: language)
    }

    /// "Equipe trabalhando": small tiles, each with its owner peeking, like the iPhone app.
    private var teamWorking: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(en ? "Team at work" : "Equipe trabalhando").font(WorkspaceTypography.caption.weight(.semibold)).foregroundStyle(CompanionStyle.muted)
            HStack(alignment: .top, spacing: 10) {
                Button { notch.showTimer() } label: {
                    tile(label: en ? "Focus" : "Foco",
                         value: assistant.hasActiveSession ? assistant.pomodoroTimeLabel : "—",
                         detail: assistant.hasActiveSession ? (en ? "Rita is holding it" : "A Rita está segurando") : (en ? "Ready to focus" : "Pronta para focar"))
                }.buttonStyle(.plain).perched(.rita, size: 30).padding(.top, 26)
                Button(action: openCalendar) {
                    tile(label: en ? "Next" : "Próximo",
                         value: notch.calendar.nextEvent.map { $0.startDate.formatted(.dateTime.hour().minute().locale(locale)) } ?? "—",
                         detail: notch.calendar.nextEvent?.title ?? (en ? "No meetings" : "Sem reuniões"))
                }.buttonStyle(.plain).perched(.gantt, size: 30).padding(.top, 26)
            }
        }
    }

    private func tile(label: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundStyle(CompanionStyle.muted)
            Text(verbatim: value).font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
            Text(verbatim: detail).font(.system(size: 10)).foregroundStyle(CompanionStyle.muted).lineLimit(1)
        }.heyCard(padding: 12, radius: 14)
    }

    private var subtitle: String {
        let day = Date().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
        let count = conversations.count
        let noun = en ? (count == 1 ? "conversation" : "conversations") : (count == 1 ? "conversa" : "conversas")
        return "\(day) · \(count) \(noun)"
    }

    private var conversationList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(en ? "Conversations" : "Conversas").font(WorkspaceTypography.caption.weight(.semibold))
                    .foregroundStyle(CompanionStyle.muted)
                Spacer()
                Button(en ? "See all" : "Ver todas", action: openChat).buttonStyle(.plain)
                    .font(WorkspaceTypography.caption.weight(.semibold)).foregroundStyle(CompanionStyle.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
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
            }.heyCard(padding: 8)
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

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subtitle).font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
            Text(verbatim: greetingLine).font(.system(size: 28, weight: .bold))
        }
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 12 ? (en ? "Good morning" : "Bom dia") : hour < 18 ? (en ? "Good afternoon" : "Boa tarde") : (en ? "Good evening" : "Boa noite")
        let name = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? part : "\(part), \(name)"
    }

    /// The team as avatars with a ring in their color and a live status dot.
    private var teamRow: some View {
        HStack(spacing: 12) {
            ForEach([LocalChatPersona.sig, .rita, .ada, .gantt, .elinor, .toni], id: \.self) { person in
                Button { open(person) } label: {
                    VStack(spacing: 5) {
                        AgentRingAvatar(persona: person, size: 44, working: person == .sig || isWorking(person) || (person == .rita && assistant.hasActiveSession))
                        Text(person.title).font(.system(size: 11)).foregroundStyle(CompanionStyle.muted)
                    }.contentShape(Rectangle())
                }
                .buttonStyle(.plain).focusEffectDisabled()
                .help(CompanionTeamCopy.long(person, en: en))
                .accessibilityLabel(en ? "Chat with \(person.title)" : "Conversar com \(person.title)")
            }
        }
    }

    /// Chomp's suggestion for right now, built only from what the app knows.
    private var chompSuggestion: some View {
        let next = notch.calendar.nextEvent.flatMap { Calendar.current.isDateInToday($0.startDate) && $0.startDate > Date() ? $0 : nil }
        let line: String
        if assistant.hasActiveSession {
            line = en ? "Rita is holding your focus: \(assistant.pomodoroTimeLabel) left. I'll keep the rest quiet." : "A Rita está segurando o seu foco: faltam \(assistant.pomodoroTimeLabel). Eu deixo o resto quieto."
        } else if let next {
            let time = next.startDate.formatted(.dateTime.hour().minute().locale(locale))
            line = en ? "Your next event is \(next.title) at \(time). Want Rita to hold your focus until then?" : "Seu próximo compromisso é \(next.title), às \(time). Quer que a Rita segure o foco até lá?"
        } else {
            line = en ? "What shall we get done today? Type or talk, and I'll bring in the right teammate." : "O que vamos resolver hoje? Escreva ou fale, e eu chamo a pessoa certa da equipe."
        }
        return VStack(alignment: .leading, spacing: 10) {
            Text(en ? "Chomp · now" : "Chomp · agora").font(.system(size: 10, weight: .semibold)).foregroundStyle(CompanionStyle.muted)
            Text(verbatim: line).font(.system(size: 14)).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                if !assistant.hasActiveSession && next != nil {
                    Button { assistant.startFocusSession() } label: { Text(en ? "Start focus" : "Iniciar foco").modifier(ChompPill(primary: true)) }
                    Button { open(.sig) } label: { Text(en ? "Not now" : "Agora não").modifier(ChompPill()) }
                } else {
                    Button { open(.sig) } label: { Text(en ? "Chat" : "Conversar").modifier(ChompPill(primary: true)) }
                    Button(action: speak) { Text(en ? "Talk" : "Falar").modifier(ChompPill()) }
                }
            }.buttonStyle(.plain).focusEffectDisabled()
        }
        .heyCard()
        .perched(.sig, animates: animates, size: 40)
        .padding(.top, 34)
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
        case .rita: en ? "Focus and health" : "Foco e saúde"
        case .ada: en ? "Code" : "Código"
        case .gantt: en ? "Calendar and journal" : "Agenda e diário"
        case .elinor: en ? "Finances" : "Finanças"
        case .toni: en ? "Files and writing" : "Arquivos e escrita"
        }
    }
    static func long(_ person: LocalChatPersona, en: Bool) -> String {
        switch person {
        case .sig: en ? "Starts the conversation and brings in the others." : "Começa a conversa e chama os outros."
        case .rita: en ? "Looks after your focus and your body: time sitting, movement and breaks." : "Cuida do seu foco e do seu corpo: tempo sentado, movimento e pausas."
        case .ada: en ? "Reviews, explains and writes code with you." : "Revisa, explica e escreve código com você."
        case .gantt: en ? "Your calendar, what is booked and how the day went, like a bullet journal." : "Sua agenda, o que já está marcado e como foi o dia, como um bullet journal."
        case .elinor: en ? "Keeps an eye on your spending, so your money is organized." : "De olho nos seus gastos, para o seu dinheiro ficar organizado."
        case .toni: en ? "Finds, organizes and drafts your files and texts." : "Encontra, organiza e redige seus arquivos e textos."
        }
    }
}

/// Equipe as a character select screen: hover or arrow keys pick a member, who steps onto
/// the stage, introduces themself line by line and lists what they can do.
struct CompanionTeamPage: View {
    let language: String
    let animates: Bool
    var isWorking: (LocalChatPersona) -> Bool = { _ in false }
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
        // The iPhone's team grid and agent screen, side by side.
        HStack(alignment: .top, spacing: 20) {
            grid.frame(width: 420)
            agentScreen
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
            case .up: selected = team[(index + team.count - 3) % team.count]
            case .down: selected = team[(index + 3) % team.count]
            default: break
            }
        }
        .onKeyPress(.return) { open(selected); return .handled }
    }

    private func status(_ person: LocalChatPersona) -> (text: String, on: Bool) {
        if isWorking(person) && person != .sig { return (en ? "Working" : "Trabalhando", true) }
        if person == .sig { return (en ? "Active" : "Ativo", true) }
        return (en ? "Free" : "Livre", false)
    }

    private var grid: some View {
        VStack(alignment: .leading, spacing: 10) {
            let busy = team.filter { $0 != .sig && isWorking($0) }.count + 1
            Text(en ? "\(busy) working now" : "\(busy) trabalhando agora").font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(team, id: \.self) { card($0) }
            }
        }
    }

    private func card(_ person: LocalChatPersona) -> some View {
        let isOn = person == selected, tint = CompanionStyle.agent(person), state = status(person)
        return Button { if isOn && showsChat { open(person) } else { selected = person } } label: {
            VStack(spacing: 6) {
                AgentDisc(persona: person, size: 62)
                    .overlay(alignment: .topLeading) { if state.on && person != .sig { TypingDot() } }
                Text(person.title).font(.system(size: 13, weight: .semibold))
                Text(CompanionTeamCopy.short(person, en: en)).font(.system(size: 10)).foregroundStyle(CompanionStyle.muted)
                    .lineLimit(2).multilineTextAlignment(.center).frame(minHeight: 26, alignment: .top)
                StatusPill(text: LocalizedStringKey(state.text), on: state.on)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12).padding(.horizontal, 6)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [tint.opacity(0.18), tint.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                    .background(HeyCardSurface(radius: 16))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isOn ? tint : .clear, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(isOn && moving ? 1.02 : 1)
            .animation(moving ? .spring(duration: 0.25, bounce: 0.25) : nil, value: isOn)
        }
        .buttonStyle(.plain).focusEffectDisabled()
        .accessibilityLabel("\(person.title), \(CompanionTeamCopy.short(person, en: en)), \(state.text)")
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }

    /// The agent screen: a soft wash of their color, the character, who they are and what they can do.
    private var agentScreen: some View {
        let tint = CompanionStyle.agent(selected), state = status(selected)
        return VStack(spacing: 16) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [tint.opacity(0.35), tint.opacity(0.06), .clear], center: UnitPoint(x: 0.5, y: 0.6), startRadius: 0, endRadius: 70))
                        .overlay { Circle().strokeBorder(tint.opacity(0.4), lineWidth: 1) }
                        .frame(width: 118, height: 118)
                    ForEach([selected], id: \.self) { person in
                        CompanionCharacter(size: 100, avatar: person.avatar, animates: moving)
                            .offset(y: 6)
                            .transition(.asymmetric(insertion: .scale(scale: 0.85).combined(with: .opacity), removal: .opacity))
                    }
                }
                .frame(width: 118, height: 118).clipShape(Circle())
                .overlay(alignment: .topLeading) { if state.on { TypingDot().offset(x: 4, y: 4) } }
                .animation(moving ? .spring(duration: 0.4, bounce: 0.3) : nil, value: selected)
                Text(selected.title).font(.system(size: 26, weight: .bold))
                Text(String(profile.intro.prefix(typed)))
                    .font(.system(size: 14)).foregroundStyle(CompanionStyle.muted).multilineTextAlignment(.center)
                    .frame(maxWidth: 420, minHeight: 40, alignment: .top)
                    .accessibilityLabel(profile.intro)
                HStack(spacing: 6) {
                    StatusPill(text: LocalizedStringKey(state.text), on: state.on)
                    Text(CompanionTeamCopy.short(selected, en: en)).font(.system(size: 11)).foregroundStyle(CompanionStyle.muted)
                }
                if showsChat {
                    Button { open(selected) } label: {
                        Text(en ? "Chat with \(selected.title)" : "Conversar com \(selected.title)")
                            .font(.system(size: 12, weight: .semibold)).padding(.horizontal, 16).frame(height: 30)
                            .background(CompanionStyle.edge.opacity(0.08), in: Capsule()).contentShape(Capsule())
                    }.buttonStyle(.plain).focusEffectDisabled().padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity).padding(.top, 22).padding(.bottom, 18).padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [tint.opacity(0.20), tint.opacity(0.0)], startPoint: .top, endPoint: .center))
                    .background(HeyCardSurface(radius: 20))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(en ? "What \(selected.title) does" : "O que \(selected == .rita || selected == .ada || selected == .elinor ? "a" : "o") \(selected.title) faz")
                    .font(WorkspaceTypography.caption.weight(.semibold)).foregroundStyle(CompanionStyle.muted)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(profile.abilities.enumerated()), id: \.offset) { index, ability in
                        HStack(spacing: 12) {
                            Image(systemName: ability.symbol).font(.system(size: 13, weight: .medium)).foregroundStyle(CompanionStyle.ink)
                                .frame(width: 30, height: 30).background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            Text(ability.text).font(.system(size: 13))
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 8)
                        .opacity(typed >= profile.intro.count || reduceMotion ? 1 : 0)
                        .offset(x: typed >= profile.intro.count || !moving ? 0 : -6)
                        .animation(moving ? .spring(duration: 0.35, bounce: 0).delay(Double(index) * 0.06) : nil, value: typed >= profile.intro.count)
                        if index < profile.abilities.count - 1 { Divider().padding(.leading, 42) }
                    }
                }.heyCard(padding: 12)
                Text(profile.notices).font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
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
            return .init(intro: en ? "I'm Rita. I look after your focus and your health, and remind you to move." : "Eu sou a Rita. Cuido do seu foco e da sua saúde, e lembro você de se mexer.",
                abilities: [.init(symbol: "leaf", text: en ? "Focus sessions and breaks" : "Sessões de foco e pausas"),
                            .init(symbol: "figure.stand", text: en ? "Notices when you sit too long" : "Percebe quando você fica muito tempo sentado"),
                            .init(symbol: "heart", text: en ? "Apple Health: steps and exercise (coming)" : "Apple Saúde: passos e exercícios (em breve)")],
                notices: en ? "Today: continuous use on this Mac. Apple Health only when you connect it." : "Hoje: uso contínuo neste Mac. Apple Saúde só quando você conectar.")
        case .ada:
            return .init(intro: en ? "I'm Ada. Show me code and I'll explain, review or write it with you." : "Eu sou a Ada. Me mostre o código e eu explico, reviso ou escrevo com você.",
                abilities: [.init(symbol: "chevron.left.forwardslash.chevron.right", text: en ? "Explains and reviews code" : "Explica e revisa código"),
                            .init(symbol: "arrow.triangle.branch", text: en ? "Reads your GitHub repositories" : "Lê seus repositórios do GitHub"),
                            .init(symbol: "magnifyingglass", text: en ? "Researches in the background" : "Pesquisa em segundo plano")],
                notices: en ? "Notices: repositories you allow her to read." : "Nota: os repositórios que você permitir.")
        case .gantt:
            return .init(intro: en ? "I'm Gantt. I keep your calendar and write down how your day went." : "Eu sou o Gantt. Cuido da sua agenda e anoto como foi o seu dia.",
                abilities: [.init(symbol: "calendar.badge.plus", text: en ? "Checks and adds to your calendar" : "Confere e cria eventos na agenda"),
                            .init(symbol: "list.bullet.clipboard", text: en ? "Daily journal, bullet style" : "Diário do dia, estilo bullet journal"),
                            .init(symbol: "envelope", text: en ? "Emails (coming)" : "E-mails (em breve)")],
                notices: en ? "Notices: calendars you share with HeyChomp." : "Nota: as agendas que você compartilhar.")
        case .elinor:
            return .init(intro: en ? "I'm Elinor. I keep your money organized, around the clock." : "Eu sou a Elinor. Deixo o seu dinheiro organizado, o dia todo.",
                abilities: [.init(symbol: "creditcard", text: en ? "Apple Pay purchases, by category (coming)" : "Compras no Apple Pay, por categoria (em breve)"),
                            .init(symbol: "chart.pie", text: en ? "Where your money goes" : "Para onde vai o seu dinheiro"),
                            .init(symbol: "sparkles", text: en ? "AI costs recorded in the app" : "Custos de IA registrados no app")],
                notices: en ? "Today: AI costs recorded here. Never invents balances or bank data." : "Hoje: custos de IA registrados aqui. Nunca inventa saldo ou dados do banco.")
        case .toni:
            return .init(intro: en ? "I'm Toni. I find, organize and draft your files and texts." : "Eu sou o Toni. Encontro, organizo e escrevo seus arquivos e textos.",
                abilities: [.init(symbol: "tray", text: en ? "Library and files" : "Biblioteca e arquivos"),
                            .init(symbol: "doc.on.clipboard", text: en ? "Clipboard history" : "Histórico da área de transferência"),
                            .init(symbol: "viewfinder", text: en ? "Screen capture" : "Captura de tela")],
                notices: en ? "Notices: files you drop on him and what you copy." : "Nota: arquivos que você soltar e o que você copiar.")
        }
    }
}

/// Gantt's view of today: a time column, a bar in his color for what comes next.
private struct HomeTodayCard: View {
    @ObservedObject var calendar: CalendarViewModel
    let en: Bool
    let locale: Locale
    let animates: Bool
    let openCalendar: () -> Void
    private var today: [CalendarEventSummary] {
        Array(calendar.events.filter { Calendar.current.isDateInToday($0.startDate) && !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }.prefix(4))
    }
    private var next: CalendarEventSummary? { today.first { $0.endDate > Date() } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(en ? "Today" : "Hoje").font(WorkspaceTypography.caption.weight(.semibold)).foregroundStyle(CompanionStyle.muted)
                Spacer()
                Button(en ? "See calendar" : "Ver agenda", action: openCalendar).buttonStyle(.plain)
                    .font(WorkspaceTypography.caption.weight(.semibold)).foregroundStyle(CompanionStyle.accent)
            }
            VStack(alignment: .leading, spacing: 9) {
                Text(verbatim: "Gantt").font(.system(size: 10, weight: .semibold)).foregroundStyle(CompanionStyle.muted)
                if today.isEmpty {
                    Text(calendar.accessState == .fullAccess
                         ? (en ? "Nothing else on your calendar today." : "Nada mais na sua agenda hoje.")
                         : (en ? "Share your calendar and Gantt shows your day here." : "Compartilhe sua agenda e o Gantt mostra o seu dia aqui."))
                        .font(.system(size: 13)).foregroundStyle(CompanionStyle.muted)
                } else {
                    ForEach(today) { event in row(event) }
                }
            }
            .heyCard()
            .perched(.gantt, animates: animates, size: 40)
            .padding(.top, 34)
        }
    }

    /// "em 1h20" / "in 1h20", like the iPhone app.
    static func until(_ date: Date, en: Bool, now: Date = Date()) -> String {
        let minutes = max(1, Int(ceil(date.timeIntervalSince(now) / 60)))
        let span = minutes < 60 ? "\(minutes) min" : minutes % 60 == 0 ? "\(minutes / 60)h" : String(format: "%dh%02d", minutes / 60, minutes % 60)
        return (en ? "in " : "em ") + span
    }

    private func row(_ event: CalendarEventSummary) -> some View {
        let isNext = event.id == next?.id
        return HStack(spacing: 10) {
            Text(event.startDate.formatted(.dateTime.hour().minute().locale(locale)))
                .font(.system(size: 13, weight: isNext ? .semibold : .regular).monospacedDigit())
                .foregroundStyle(isNext ? CompanionStyle.ink : CompanionStyle.muted).frame(width: 44, alignment: .leading)
            Capsule().fill(isNext ? CompanionStyle.agent(.gantt) : CompanionStyle.edge.opacity(0.15)).frame(width: 2.5, height: 16)
            Text(verbatim: event.title).font(.system(size: 13, weight: isNext ? .semibold : .regular)).lineLimit(1)
                .foregroundStyle(isNext ? CompanionStyle.ink : CompanionStyle.muted)
            Spacer(minLength: 8)
            if isNext, event.startDate > Date() {
                Text(verbatim: Self.until(event.startDate, en: en)).font(.system(size: 11).monospacedDigit()).foregroundStyle(CompanionStyle.muted)
            }
        }
    }
}

/// Mint "typing" badge: marks who is working right now (from the iPhone app).
struct TypingDot: View {
    var size: CGFloat = 20
    var body: some View {
        Circle().fill(CompanionStyle.accent)
            .overlay {
                HStack(spacing: size * 0.1) {
                    ForEach(0..<3, id: \.self) { _ in Circle().fill(CompanionStyle.accentOnFill).frame(width: size * 0.16, height: size * 0.16) }
                }
            }
            .frame(width: size, height: size)
            .overlay { Circle().stroke(CompanionStyle.surface, lineWidth: 2.5) }
            .accessibilityHidden(true)
    }
}
