import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var viewModel: WorkspaceViewModel
    @Environment(\.accessibilityReduceMotion) private var systemReducedMotion
    @FocusState private var focusedSection: AppSection?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @AppStorage("workspace.toolsExpanded") private var toolsExpanded = false
    @State private var typeToChatMonitor: Any?
    @Environment(\.islandPreview) private var preview
    @EnvironmentObject private var sensor: SensorViewModel
    @EnvironmentObject private var assistant: AssistantViewModel
    @EnvironmentObject private var notch: NotchWidgetViewModel
    @EnvironmentObject private var gestures: ImpactGestureCoordinator
    @EnvironmentObject private var activation: ActivationController
    @EnvironmentObject private var preferences: CompanionPreferences
    var scrollable: Bool

    init(initialSection: AppSection = .overview, scrollable: Bool = true) {
        _viewModel = StateObject(wrappedValue: WorkspaceViewModel(section: initialSection))
        self.scrollable = scrollable
    }

    var body: some View {
        Group {
            if preferences.onboardingComplete { workspace }
            else { CompanionOnboardingView(clipboard: notch.clipboard, onFinish: { notch.showWelcome() }, prepareVoice: { await activation.prepareVoiceAccess() }, showCompanion: { notch.show() }) }
        }
        .frame(minWidth: 840, minHeight: 660)
        .preferredColorScheme(preferences.appearance.colorScheme)
        .environment(\.workspaceGlass, true)
        .environment(\.islandReduceMotion, preferences.usesReducedMotion)
        .environment(\.companionMotionEnabled, preferences.characterMotion)
        .environment(\.locale, Locale(identifier: activation.voiceLanguage))
        .background { WorkspaceBackdrop() }
        .environment(\.surfaceGlassEnabled, preferences.windowGlass)
    }

    private var workspace: some View {
        Group {
            // ImageRenderer has no native split-view host. The catalog keeps an
            // explicit pane map; the live window uses the system source list.
            if preview {
                HStack(spacing: 0) { sidebar; pageContent }
            } else {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    nativeSidebar
                        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
                } detail: {
                    pageContent
                        .navigationTitle(viewModel.section.title(english: en))
                        .toolbar {
                            ToolbarItemGroup(placement: .primaryAction) {
                                Button { notch.show() } label: {
                                    Label(en ? "Show companion" : "Mostrar companheiro", systemImage: "rectangle.topthird.inset.filled")
                                }.help(en ? "Show the floating companion" : "Mostrar o companheiro flutuante")
                                Button {
                                    Task {
                                        if await notch.agentRoom.localChat.create(.sig) != nil {
                                            notch.agentRoom.page = .chat; viewModel.section = .agentRoom
                                        }
                                    }
                                } label: {
                                    Label(en ? "New conversation" : "Nova conversa", systemImage: "square.and.pencil")
                                }.help(en ? "New conversation" : "Nova conversa")
                            }
                        }
                }.navigationSplitViewStyle(.balanced)
            }
        }
        .frame(minWidth: 840, minHeight: 580)
        .tint(CompanionStyle.accentInk)
        .font(WorkspaceTypography.body)
        .buttonStyle(.bordered)
        .onAppear { installTypeToChat() }
        .onDisappear { if let typeToChatMonitor { NSEvent.removeMonitor(typeToChatMonitor) }; typeToChatMonitor = nil }
        .onReceive(NotificationCenter.default.publisher(for: .openWorkspaceSettings)) { _ in
            toolsExpanded = true; viewModel.section = .settings
        }
        .onChange(of: preferences.impactsEnabled) { _, enabled in
            if enabled { sensor.startIfNeeded() }
            else { sensor.stop(); gestures.cancelPendingImpacts() }
        }
    }

    private var pageContent: some View {
        Group {
            if scrollable { ScrollView { page } }
            else { page }
        }
        .id(viewModel.section)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CompanionStyle.background)
    }

    private var nativeSidebar: some View {
        // Rows are plain buttons, not a selection-bound List, so macOS never paints a
        // second (system accent) selection next to our mint controls.
        List {
            HStack(spacing: 10) {
                CompanionCharacter(size: 34, avatar: preferences.avatar, animates: preferences.characterMotion && !preferences.usesReducedMotion)
                    .frame(width: 40, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("HeyChomp").font(WorkspaceTypography.section).foregroundStyle(CompanionStyle.ink)
                    Text(en ? "Your quiet companion" : "Seu companheiro de todos os dias")
                        .font(WorkspaceTypography.footnote).foregroundStyle(CompanionStyle.muted).lineLimit(2)
                }
            }
            .padding(.vertical, 6)
            .listRowBackground(Color.clear)
            .accessibilityElement(children: .combine)
            Section {
                ForEach(Array(AppSection.places.enumerated()), id: \.element) { index, item in
                    sidebarRow(item)
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
            }
            Section {
                DisclosureGroup(isExpanded: $toolsExpanded) {
                    ForEach(AppSection.tools) { item in sidebarRow(item) }
                } label: {
                    Label(en ? "Tools" : "Ferramentas", systemImage: "wrench.and.screwdriver")
                        .font(.system(size: 13)).foregroundStyle(CompanionStyle.muted)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("HeyChomp")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(en ? "Review introduction" : "Rever apresentação") { preferences.onboardingComplete = false }
                .buttonStyle(.borderless).font(WorkspaceTypography.caption)
                .frame(maxWidth: .infinity, alignment: .leading).padding(16)
        }
    }

    /// Type-to-chat: with no text field focused, a printable key in the main window starts a
    /// conversation with Chomp and carries the typed text into the composer.
    private func installTypeToChat() {
        guard !preview, typeToChatMonitor == nil else { return }
        let model = viewModel, room = notch.agentRoom
        typeToChatMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let window = event.window, window.isKeyWindow, !(window is NSPanel), window.attachedSheet == nil,
                  !(window.firstResponder is NSText), model.section != .agentRoom,
                  event.modifierFlags.intersection([.command, .control, .option, .function]).isEmpty,
                  let typed = event.characters, !typed.isEmpty,
                  typed.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) && $0.value < 0xF700 }),
                  !typed.trimmingCharacters(in: .whitespaces).isEmpty
            else { return event }
            Task { @MainActor in
                if await room.localChat.openPersona(.sig) != nil {
                    room.localChat.draft += typed
                    room.page = .chat
                    model.section = .agentRoom
                }
            }
            return nil
        }
    }

    private func sidebarRow(_ item: AppSection) -> some View {
        let selected = viewModel.section == item
        return Button { viewModel.section = item } label: {
            Label(item.title(english: en), systemImage: item.symbol)
                .symbolVariant(selected ? .fill : .none)
                .font(.system(size: 13, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? CompanionStyle.ink : CompanionStyle.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(selected ? CompanionStyle.edge.opacity(0.10) : Color.clear)
                .padding(.horizontal, 6)
        )
        .accessibilityLabel(item.title(english: en))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private var en: Bool { activation.voiceLanguage.hasPrefix("en") }

    private var page: some View {
        VStack(alignment: .leading, spacing: WorkspaceMetrics.sectionGap) {
            if let owner = viewModel.section.owner, ![.calendar, .capture, .files].contains(viewModel.section) {
                ToolPageHeading(title: viewModel.section.title(english: en), subtitle: viewModel.section.subtitle(english: en), owner: owner,
                                en: en, animates: preferences.characterMotion && !preferences.usesReducedMotion)
            } else if viewModel.section != .overview {
                WorkspacePageHeading(title: viewModel.section.title(english: en), subtitle: viewModel.section.subtitle(english: en))
            }
            switch viewModel.section {
            case .desktop:

                DesktopToolsView(model: notch.desktop).companionCard()
            case .overview:
                CompanionWorkspaceHome(room: notch.agentRoom, chat: notch.agentRoom.localChat, coordinator: notch.spatialAssistant,
                    language: activation.voiceLanguage, animates: preferences.characterMotion && !preferences.usesReducedMotion,
                    openChat: { viewModel.section = .agentRoom }, speak: { activation.toggleListening() }, settings: { viewModel.section = .settings })
            case .calendar:

                CalendarView(model: notch.calendar, events: notch.events).companionCard()
            case .files:
                LibraryPage(files: notch.files, artifacts: notch.spatialAssistant.artifacts, language: activation.voiceLanguage) { item in
                    if notch.agentRoom.localChat.revealSource(of: item) { notch.agentRoom.page = .chat; viewModel.section = .agentRoom; return true }
                    return false
                }
            case .capture:

                CaptureToolsView(model: notch.capture).companionCard()
            case .focus: focusSettings
            case .settings:
                RitaNudgeSettings(nudges: notch.ritaNudges)
                PreferenceRow("Open on the screen with the pointer", detail: "On external displays the companion opens at the top of the screen you are using, even without a notch.") {
                    Toggle("Open on the screen with the pointer", isOn: Binding(get: { notch.followsPointerScreen }, set: { notch.followsPointerScreen = $0 }))
                        .labelsHidden().toggleStyle(WorkspaceSwitchStyle())
                }.padding(.top, 8)
                Text(en ? "Activation" : "Ativação").font(WorkspaceTypography.section).padding(.top, 12)
                activationSettings
                Text(en ? "Appearance" : "Aparência").font(WorkspaceTypography.section).padding(.top, 12)
                appearanceSettings
                Text(en ? "File notifications" : "Notificações de arquivos").font(WorkspaceTypography.section).padding(.top, 12)
                TaskNotificationPreferences(events: notch.files.events, module: .files)
                TaskNotificationPreferences(events: notch.files.events, module: .downloads)
                Text(en ? "Widget" : "Widget").font(WorkspaceTypography.section).padding(.top, 12)
                IslandLayoutEditor(preferences: preferences, onPreview: { notch.show() })
            case .activation: activationSettings
            case .appearance: appearanceSettings
            case .dynamicIsland:
                IslandLayoutEditor(preferences: preferences, onPreview: { notch.show() })
            case .system:

                SystemMonitorView(monitor: notch.monitor).companionCard()
            case .keepAwake:

                KeepAwakeView(controller: notch.keepAwake).companionCard()
            case .displayPower:

                DisplayPowerView(controller: notch.displayPower).companionCard()
            case .clipboard:

                ClipboardHistoryView(clipboard: notch.clipboard, dismiss: { notch.hide() }).companionCard()
            case .audio:

                AudioControlsView().companionCard()
                VStack(alignment: .leading, spacing: 16) {
                    PreferenceRow("Switch output shortcut", detail: "Cycle through connected outputs from any app.") { ShortcutRecorder(action: .nextOutput) }
                    Text(LocalizedStringKey(activation.audioShortcutStatuses[.nextOutput] ?? "Shortcut off")).font(.caption).foregroundStyle(CompanionStyle.muted)
                    PreferenceRow("Microphone mute shortcut", detail: "Toggle hardware mute on your selected microphone when supported.") { ShortcutRecorder(action: .muteMicrophone) }
                    Text(LocalizedStringKey(activation.audioShortcutStatuses[.muteMicrophone] ?? "Shortcut off")).font(.caption).foregroundStyle(CompanionStyle.muted)
                }.companionCard()
            case .team:
                CompanionTeamPage(language: activation.voiceLanguage, animates: preferences.characterMotion && !preferences.usesReducedMotion, open: { person in
                    Task { if await notch.agentRoom.localChat.openPersona(person) != nil { notch.agentRoom.page = .chat; viewModel.section = .agentRoom } }
                })
            case .agentRoom:
                AgentRoomView(model: notch.agentRoom)
            case .aiLimits:

                AIUsageView(onOpenRoom: { viewModel.section = .agentRoom })
            }
        }
        .frame(maxWidth: [.overview, .files].contains(viewModel.section) ? WorkspaceMetrics.readableWidth : WorkspaceMetrics.contentWidth, alignment: .leading)
        .modifier(WorkspacePageArrival())
        .padding(WorkspaceMetrics.pageInset)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                CompanionCharacter(size: 36, avatar: preferences.avatar, animates: preferences.characterMotion && !preferences.usesReducedMotion)
                VStack(alignment: .leading, spacing: 3) {
                    Text("HeyChomp").font(.headline)
                    Text(activation.voiceLanguage.hasPrefix("en") ? "Your quiet companion" : "Seu companheiro de todos os dias").font(WorkspaceTypography.footnote).foregroundStyle(CompanionStyle.muted)
                }
            }.padding(.horizontal, 8).padding(.top, 12).padding(.bottom, 18)
            Text(en ? "Your space" : "Seu espaço").font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CompanionStyle.muted.opacity(0.7)).padding(.horizontal, 12).padding(.bottom, 4)
            Group {
                if preview { sidebarNavigation }
                else { ScrollView { sidebarNavigation }.scrollIndicators(.hidden) }
            }.frame(maxHeight: .infinity, alignment: .top)
            Button(en ? "Review introduction" : "Rever apresentação") { preferences.onboardingComplete = false }
                .buttonStyle(.plain).font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
                .padding(.horizontal, 12).padding(.vertical, 12)
        }
        .padding(12)
        .frame(width: 220)
        .frame(maxHeight: .infinity)
        .background(CompanionStyle.sidebar)
        .overlay(alignment: .trailing) { Rectangle().fill(CompanionStyle.edge.opacity(0.07)).frame(width: 0.7).allowsHitTesting(false) }
    }

    private var sidebarNavigation: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(AppSection.places) { item in
                sidebarButton(item.title(english: en), section: item, symbol: item.symbol, selected: viewModel.section == item) { viewModel.section = item }
            }
            Text(en ? "Tools" : "Ferramentas").font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CompanionStyle.muted.opacity(0.7)).padding(.horizontal, 12).padding(.top, 22).padding(.bottom, 8)
            ForEach(AppSection.tools) { item in
                sidebarButton(item.title(english: en), section: item, symbol: item.symbol, selected: viewModel.section == item) { viewModel.section = item }
            }
        }
    }

    private func sidebarButton(_ title: String, section: AppSection, symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: symbol).font(.system(size: 13, weight: selected ? .medium : .regular)).frame(width: 18)
                    .foregroundStyle(selected ? CompanionStyle.accentInk : CompanionStyle.muted)
                Text(title)
                Spacer()

            }
                .font(.system(size: 12, weight: selected ? .medium : .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 11).padding(.vertical, 9)
                .foregroundStyle(selected ? CompanionStyle.ink : CompanionStyle.muted)
                .background(selected ? CompanionStyle.edge.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .animation(systemReducedMotion || preferences.usesReducedMotion ? nil : InterfaceMotion.feedback, value: selected)
        }
        .buttonStyle(WorkspaceNavigationStyle())
        .focused($focusedSection, equals: section)
        .focusEffectDisabled()
        .overlay {
            RoundedRectangle(cornerRadius: 10).strokeBorder(focusedSection == section ? CompanionStyle.accentInk.opacity(0.85) : .clear, lineWidth: 1.5)
                .allowsHitTesting(false)
        }
        .accessibilityLabel(title)
        .accessibilityValue(selected ? (en ? "Selected" : "Selecionado") : "")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder private var focusSettings: some View {

        TimerToolsView(onStart: { notch.showIsland() }).companionCard()
        Text("Selecting a mode leaves your clock alone. Start, pause or reset when you choose.").font(.caption).foregroundStyle(CompanionStyle.muted)
    }

    @ViewBuilder private var activationSettings: some View {

        CompanionVoiceSettings().companionCard()
        ScrollInputSettings(controller: notch.scrollInput).companionCard()
        MouseButtonsSettingsView(controller: notch.mouseButtons).companionCard()
        InputGuardsSettingsView(controller: notch.inputGuards).companionCard()
        MiddleClickSettings(controller: notch.middleClick).companionCard()
        VStack(alignment: .leading, spacing: 18) {
            Label("Keyboard", systemImage: "keyboard").font(.headline)
            PreferenceRow("Companion shortcut", detail: "Record any key combination to reveal HeyChomp.") { ShortcutRecorder(action: .companion) }
            Text(activation.shortcutStatus).font(.caption).foregroundStyle(CompanionStyle.muted).frame(maxWidth: .infinity, alignment: .leading)
            Divider()
            PreferenceRow("Voice shortcut", detail: "Hold your shortcut to speak. Release it to send your request.") { ShortcutRecorder(action: .voice) }
            Text(activation.voiceShortcutStatus).font(.caption).foregroundStyle(CompanionStyle.muted).frame(maxWidth: .infinity, alignment: .leading)
            Divider()
            PreferenceRow("Clipboard shortcut", detail: "Find a saved copy from any app, even after closing this window.") { ShortcutRecorder(action: .clipboard) }
            Text(activation.clipboardShortcutStatus).font(.caption).foregroundStyle(CompanionStyle.muted).frame(maxWidth: .infinity, alignment: .leading)
            if activation.voiceShortcut?.isModifierOnly == true {
                Button("Use Control + Option + V") { activation.setShortcut(.voice, for: .voice) }
                    .buttonStyle(.plain).focusEffectDisabled().font(.caption)
                Text("A shortcut with a key works across apps without keyboard monitoring access.")
                    .font(.caption).foregroundStyle(CompanionStyle.muted)
            }
            Text("Close this window to keep HeyChomp and its shortcuts in the menu bar. Choose Quit to stop the app.")
                .font(.caption).foregroundStyle(CompanionStyle.muted)
            HStack {
                if let date = activation.lastShortcutActivation {
                    Text("Last received at \(date.formatted(date: .omitted, time: .shortened)) · \(activation.lastShortcutSource)").font(.caption).foregroundStyle(CompanionStyle.muted)
                }
                Spacer()
                Button("Restore shortcuts") { activation.recoverShortcuts() }.buttonStyle(.plain).focusEffectDisabled().font(.caption)
            }
            if activation.recordingShortcut != nil {
                Text("Press your combination. Release modifier-only keys to save. Escape cancels.").font(.caption).foregroundStyle(CompanionStyle.accentInk)
            }
            if activation.needsShortcutPermission {
                Button("Allow modifier shortcuts in other apps") { activation.enableModifierShortcuts() }.buttonStyle(CompanionButtonStyle()).focusEffectDisabled()
            }
        }.companionCard()
        VStack(alignment: .leading, spacing: 18) {
            Label("Finder file shortcuts", systemImage: "folder").font(.headline)
            Text("Optional, off by default. Active only while Finder is in front. Moves and renames still need your review and confirmation.").font(.caption).foregroundStyle(CompanionStyle.muted)
            ForEach(ShortcutAction.finderActions) { action in
                PreferenceRow(action.title, detail: action == .finderRename ? "Record F2 or your own keys. Select one file in Finder." : "Prepare the selected files, then review the current Finder destination.") { ShortcutRecorder(action: action) }
                Text(LocalizedStringKey(activation.fileShortcutStatuses[action] ?? "Shortcut off")).font(.caption).foregroundStyle(CompanionStyle.muted)
            }
        }.companionCard()
        VStack(alignment: .leading, spacing: 18) {
            Label("Island", systemImage: "rectangle.topthird.inset.filled").font(.headline)
            PreferenceRow("Island hover feedback", detail: "Your companion reacts on hover. Click to open the island.") {
                Toggle("Island hover feedback", isOn: $preferences.hoverEnabled).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
        }.companionCard()
        VStack(alignment: .leading, spacing: 18) {
            Label("Voice", systemImage: "waveform").font(.headline)
            PreferenceRow("Voice", detail: "Say “open Safari”, “search for Swift tutorials” or “pesquise receitas”. Hold the voice shortcut to speak, then release to send.") {
                Button(activation.isVoiceBusy ? "Cancel" : "Speak") {
                    if activation.isVoiceBusy { activation.cancelVoiceCommand() }
                    else { activation.toggleListening() }
                }.buttonStyle(CompanionButtonStyle()).focusEffectDisabled()
            }
            PreferenceRow("Speech language", detail: "Choose the language for your commands and Chomp’s replies.") {
                if preview { Text(activation.voiceLanguage == "pt_BR" ? "Português" : "English").font(.callout).padding(9).background(CompanionStyle.edge.opacity(0.08), in: RoundedRectangle(cornerRadius: 9)) }
                else { Picker("Speech language", selection: $activation.voiceLanguage) {
                    Text("English").tag("en_US")
                    Text("Português").tag("pt_BR")
                }.labelsHidden().frame(width: 140) }
            }
            PreferenceRow("Conversation", detail: "Keep the microphone on for a conversation. You can interrupt Chomp; Stop ends listening. Hold-to-talk remains available separately.") {
                Button(activation.isConversing ? "Stop conversation" : "Start conversation") { activation.toggleConversation() }
                    .buttonStyle(CompanionButtonStyle(primary: activation.isConversing))
            }
            if activation.isConversing {
                Label(LocalizedStringKey(activation.conversation.status), systemImage: "mic.fill").font(.caption).foregroundStyle(.green)
            } else if !activation.conversation.status.isEmpty {
                Text(LocalizedStringKey(activation.conversation.status)).font(.caption).foregroundStyle(CompanionStyle.muted)
            }
            Text(LocalizedStringKey(activation.voiceStatus)).font(.caption).foregroundStyle(CompanionStyle.muted).frame(maxWidth: .infinity, alignment: .leading)
            if let settings = activation.voicePermissionSettingsURL {
                Button("Open voice permission") { NSWorkspace.shared.open(settings) }
                    .buttonStyle(CompanionButtonStyle(compact: true))
            }
            if !activation.transcript.isEmpty {
                Text("“\(activation.transcript)”").frame(maxWidth: .infinity, alignment: .leading)
            }
        }.companionCard()
        VStack(alignment: .leading, spacing: 18) {
            Label("Impact gestures", systemImage: "hand.tap").font(.headline)
            PreferenceRow("Impact gestures", detail: "An optional physical way to open or control focus.") {
                Toggle("Impact gestures", isOn: $preferences.impactsEnabled).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            if preferences.impactsEnabled {
                ImpactActionPicker(title: "One impact", selection: $gestures.singleImpactAction)
                ImpactActionPicker(title: "Two impacts", selection: $gestures.doubleImpactAction)
                ImpactActionPicker(title: "Three impacts", selection: $gestures.tripleImpactAction)
                Text(sensor.isRunning ? "Impact gestures are active" : "Impact gestures are unavailable on this Mac")
                    .font(.caption).foregroundStyle(CompanionStyle.muted)
            }
        }.companionCard()
        Text("You can always open HeyChomp from the menu bar.").font(.caption).foregroundStyle(CompanionStyle.muted)
    }

    @ViewBuilder private var appearanceSettings: some View {

        VStack(alignment: .leading, spacing: 18) {
            Text("Appearance").font(.headline)
            HStack(spacing: 14) {
                ForEach(AppAppearance.allCases) { choice in
                    Button { preferences.appearance = choice } label: {
                        VStack(spacing: 9) {
                            AppearanceThumbnail(appearance: choice)
                                .overlay { RoundedRectangle(cornerRadius: 11).strokeBorder(preferences.appearance == choice ? CompanionStyle.accent : CompanionStyle.edge.opacity(0.1), lineWidth: preferences.appearance == choice ? 2 : 0.7) }
                            Text(LocalizedStringKey(choice.rawValue)).font(.callout.weight(.medium)).foregroundStyle(CompanionStyle.ink)
                        }.padding(10).frame(maxWidth: .infinity)
                            .background(preferences.appearance == choice ? CompanionStyle.edge.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }.buttonStyle(.plain).focusEffectDisabled().accessibilityLabel(Text(LocalizedStringKey(choice.rawValue)))
                        .accessibilityAddTraits(preferences.appearance == choice ? .isSelected : [])
                }
            }
            Text("Applies to HeyChomp’s windows and panels. Your Mac’s appearance stays unchanged.").font(.caption).foregroundStyle(CompanionStyle.muted)
            Divider()
            Label("Liquid Glass", systemImage: "sparkles").font(.headline)
            Text("Optional translucent panels. Reduce Transparency always takes priority.").font(.caption).foregroundStyle(CompanionStyle.muted)
            PreferenceRow("Other windows and panels", detail: "Main app, menu-bar panel and data sheets.") {
                Toggle("Glass in other windows and panels", isOn: $preferences.windowGlass).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            PreferenceRow("Dynamic Island", detail: "Expanded island only; the compact notch always stays black.") {
                Toggle("Glass in Dynamic Island", isOn: $preferences.islandGlass).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
        }.companionCard()
        HStack(spacing: 14) {
            Image(systemName: "rectangle.topthird.inset.filled").font(.title2).foregroundStyle(CompanionStyle.accentInk)
            VStack(alignment: .leading, spacing: 4) {
                Text("Dynamic Island").font(.headline)
                Text("Arrange buttons around a visual preview and choose your widget size.").font(.caption).foregroundStyle(CompanionStyle.muted)
            }
            Spacer()
            Button("Edit layout") { viewModel.section = .settings }.buttonStyle(CompanionButtonStyle(compact: true))
        }.companionCard()
        HStack(spacing: 18) {
            CompanionCharacter(size: 86, avatar: preferences.avatar, animates: preferences.characterMotion && !preferences.usesReducedMotion)
            VStack(alignment: .leading, spacing: 4) {
                Text(preferences.avatar.name).font(.headline)
                Text(LocalizedStringKey(preferences.avatar.detail)).font(.caption).foregroundStyle(CompanionStyle.muted)
            }
            Spacer()
            Button("Preview") { notch.show() }.buttonStyle(CompanionButtonStyle())
        }
        .companionCard()
        CompanionTeamGallery(animates: preferences.characterMotion && !preferences.usesReducedMotion, onAda: { viewModel.section = .agentRoom })
        Text("Chomp is always your main companion. Tap a team member to explore their movements.")
            .font(.caption).foregroundStyle(CompanionStyle.muted)
        VStack(spacing: 20) {
            PreferenceRow("Compact active timer", detail: "Keep remaining time and controls close together.") {
                Toggle("Compact active timer", isOn: $preferences.compactTimer).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            Divider()
            PreferenceRow("Launch greeting", detail: "Your companion drops in, waves hello and settles into the island.") {
                Toggle("Launch greeting", isOn: $preferences.launchGreeting).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            PreferenceRow("Introduction language", detail: "English by default. Choose Portuguese for the team's introduction.") {
                Picker("Introduction language", selection: $preferences.introductionLanguage) {
                    ForEach(CompanionIntroductionLanguage.allCases) { language in Text(language.name).tag(language) }
                }.labelsHidden().frame(width: 190)
            }
            PreferenceRow("Character motion", detail: "Use restrained expressions during focus and voice.") {
                Toggle("Character motion", isOn: $preferences.characterMotion).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            Divider()
            PreferenceRow("Reduce Motion", detail: "Limit animation. macOS Reduce Motion is always respected.") {
                Toggle("Reduce Motion", isOn: $preferences.reduceMotion).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
        }.companionCard()
    }
}

private struct CompanionVoiceSettings: View {
    @EnvironmentObject private var preferences: CompanionPreferences
    @EnvironmentObject private var activation: ActivationController
    @Environment(\.islandPreview) private var isPreview
    @StateObject private var previewVoice = SigVoiceSynthesizer(playsHardwareAudio: true)
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Voz do Chomp", systemImage: "speaker.wave.2").font(.headline)
            PreferenceRow("Respostas em áudio", detail: "Ouça as respostas do seu companheiro.") {
                Toggle("Respostas em áudio", isOn: $preferences.speechConfiguration.enabled)
                    .labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            voiceSlider("Velocidade", value: $preferences.speechConfiguration.rate, range: 0.30...0.65,
                        detail: "\(Int(preferences.speechConfiguration.rate / AVSpeechUtteranceDefaultSpeechRate * 100))%")
            voiceSlider("Volume da voz", value: $preferences.speechConfiguration.volume, range: 0...1,
                        detail: "\(Int(preferences.speechConfiguration.volume * 100))%")
            HStack(spacing: 12) {
                Button(previewVoice.isSpeaking ? "Parar prévia" : "Ouvir prévia") {
                    if previewVoice.isSpeaking { previewVoice.stop() }
                    else if !isPreview {
                        previewVoice.configuration = preferences.speechConfiguration.normalized
                        previewVoice.speak(activation.voiceLanguage.hasPrefix("en")
                            ? "Leave it with me. I'll explain things calmly and help with your tasks. We can leave the panicking to the bugs."
                            : "Pode deixar comigo. Vou explicar com calma e cuidar das tarefas do app. A parte de entrar em pânico, a gente deixa para os bugs.", language: activation.voiceLanguage.hasPrefix("en") ? "en-US" : "pt-BR")
                    }
                }.buttonStyle(CompanionButtonStyle()).disabled(!preferences.speechConfiguration.enabled)
                Button("Restaurar padrão") {
                    previewVoice.stop()
                    preferences.speechConfiguration = .sieg
                }.buttonStyle(CompanionButtonStyle(compact: true))
            }
            if preferences.speechConfiguration.voiceIdentifier == SigVoiceCatalog.antonio {
                Text("A voz do Chomp acompanha o idioma selecionado. Requer conexão; sem ela, uma voz local assume a resposta.")
                    .font(.caption).foregroundStyle(CompanionStyle.muted)
            }
            if let issue = previewVoice.lastPlaybackIssue {
                Text(issue).font(.caption).foregroundStyle(CompanionStyle.muted)
            }
            Text("A voz faz parte da identidade do Chomp. Velocidade e volume são salvos automaticamente.")
                .font(.caption).foregroundStyle(CompanionStyle.muted)
        }
        .onChange(of: preferences.speechConfiguration.enabled) { _, enabled in
            if !enabled { previewVoice.stop() }
        }
        .onDisappear { previewVoice.stop() }
    }

    private func voiceSlider(_ title: String, value: Binding<Float>, range: ClosedRange<Float>, detail: String) -> some View {
        HStack(spacing: 16) {
            Text(LocalizedStringKey(title)).font(.callout.weight(.semibold)).frame(width: 115, alignment: .leading)
            Slider(value: value, in: range).accessibilityLabel(title)
            Text(LocalizedStringKey(detail)).font(.caption).monospacedDigit().foregroundStyle(CompanionStyle.muted)
                .frame(width: 82, alignment: .trailing)
        }
    }
}

private struct AppearanceThumbnail: View {
    var appearance: AppAppearance
    var body: some View {
        ZStack {
            window(light: appearance != .dark)
            if appearance == .system { window(light: false).mask {
                GeometryReader { geometry in
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                        path.closeSubpath()
                    }.fill(.white)
                }
            } }
        }.frame(height: 82).clipShape(RoundedRectangle(cornerRadius: 11)).accessibilityHidden(true)
    }
    private func window(light: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) { ForEach([Color.red, .yellow, .green], id: \.self) { Circle().fill($0).frame(width: 5, height: 5) }; Spacer() }
                .padding(8).background(light ? Color(white: 0.91) : Color(white: 0.18))
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) { ForEach(0..<3) { _ in Capsule().fill(light ? Color(white: 0.75) : Color(white: 0.38)).frame(height: 3) } }.frame(width: 28)
                VStack(alignment: .leading, spacing: 5) { ForEach(0..<3) { row in Capsule().fill(light ? Color(white: 0.75) : Color(white: 0.38)).frame(width: CGFloat(46 - row * 8), height: 3) } }
                Spacer(minLength: 0)
            }.padding(10).frame(maxWidth: .infinity, maxHeight: .infinity).background(light ? Color.white : Color(white: 0.12))
        }
    }
}



private struct PreferenceRow<Control: View>: View {
    let title: String
    let detail: String
    let control: Control
    init(_ title: String, detail: String, @ViewBuilder control: () -> Control) {
        self.title = title; self.detail = detail; self.control = control()
    }
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 24) {
                copy.frame(minWidth: 220, maxWidth: .infinity, alignment: .leading)
                control.fixedSize(horizontal: true, vertical: false)
            }
            VStack(alignment: .leading, spacing: 14) {
                copy
                control.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }.frame(minHeight: 40)

    }
    private var copy: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(LocalizedStringKey(title)).font(.system(size: 13, weight: .medium))
            Text(LocalizedStringKey(detail)).font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
        }
    }

}

private struct ImpactActionPicker: View {
    let title: String
    @Binding var selection: ImpactAction
    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(ImpactAction.allCases) { action in Text(action.title).tag(action) }
        }.pickerStyle(.menu)
    }
}

struct MiddleClickSettings: View {
    @ObservedObject var controller: MiddleClickController
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Three-finger middle click", systemImage: "hand.point.up.left").font(.headline)
                Spacer()
                Toggle("Three-finger middle click", isOn: $controller.isEnabled).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            Text("Tap the trackpad with three fingers to press the mouse wheel button. Apps decide what that button does, such as opening a link in a new tab.").font(.caption).foregroundStyle(CompanionStyle.muted)
            if controller.isEnabled {
                Text(controller.status).font(.caption)
                HStack {
                    Button("Allow Accessibility") { controller.allowAccess() }.buttonStyle(CompanionButtonStyle(compact: true))
                    Button("Retry") { controller.configure() }.buttonStyle(CompanionButtonStyle(compact: true))
                }
                Text("Disable conflicting three-finger Look Up or Drag gestures in macOS settings. This optional gesture depends on trackpad support.").font(.caption2).foregroundStyle(CompanionStyle.muted)
            }
        }
    }
}


private struct ScrollInputSettings: View {
    @ObservedObject var controller: ScrollInputController
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scrolling & Pointer").font(.headline)
            PreferenceRow("Invert scrolling", detail: "Reverse both scroll axes.") {
                Toggle("Invert scrolling", isOn: $controller.options.inverted).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            PreferenceRow("Horizontal scrolling", detail: "Hold a modifier to redirect vertical scrolling sideways.") {
                Toggle("Horizontal scrolling", isOn: $controller.options.horizontal).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            if controller.options.horizontal {
                Picker("Scroll modifier", selection: $controller.options.modifier) {
                    ForEach(ScrollModifier.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
            }
            PreferenceRow("Linear wheel scrolling", detail: "Use a constant step per wheel notch without OS scroll acceleration.") {
                Toggle("Linear wheel scrolling", isOn: $controller.options.linear).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            PreferenceRow("Smooth wheel scrolling", detail: "Add proportional sub-line pixel steps to discrete mouse wheels.") {
                Toggle("Smooth wheel scrolling", isOn: $controller.options.smooth).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            if controller.options.wheelCurveEnabled {
                Stepper("Wheel step: \(controller.options.clampedStepPixels) px", value: $controller.options.stepPixels, in: ScrollOptions.stepRange, step: 4)
                    .font(.caption)
            }
            if controller.options.enabled {
                PreferenceRow("Include trackpad and smooth-scroll mice", detail: "Turn this on to apply inversion and horizontal scrolling to your MacBook trackpad or a smooth-scroll mouse.") {
                    Toggle("Include trackpad and smooth-scroll mice", isOn: $controller.options.affectsContinuous).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
                }
                Text(controller.status).font(.caption).foregroundStyle(CompanionStyle.muted)
                if let hint = controller.inputHint { Text(hint).font(.caption).foregroundStyle(CompanionStyle.accentInk) }
                HStack {
                    Button("Open Accessibility settings") { controller.allowAccess() }.buttonStyle(CompanionButtonStyle(compact: true))
                    Button("Retry") { controller.configure() }.buttonStyle(CompanionButtonStyle(compact: true))
                }
                Button("Locate this copy of HeyChomp") { AccessibilityAccess.revealRunningApp() }.font(.caption)
                Text("Enable this copy of HeyChomp in macOS Privacy & Security, then return and click Retry.").font(.caption).foregroundStyle(CompanionStyle.muted)
            }
            Divider()
            PreferenceRow("Mouse acceleration", detail: "Customize or flatten macOS mouse pointer acceleration with automatic restore.") {
                Toggle("Mouse acceleration", isOn: $controller.pointerAcceleration.enabled).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            if controller.pointerAcceleration.enabled {
                PreferenceRow("Flat 1:1 pointer curve", detail: "Disable pointer acceleration curve while keeping your original Mac value backed up.") {
                    Toggle("Flat 1:1 pointer curve", isOn: $controller.pointerAcceleration.flatCurve).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
                }
                if !controller.pointerAcceleration.flatCurve {
                    HStack {
                        Text(String(format: "Acceleration: %.2fx", controller.pointerAcceleration.clampedSpeed)).font(.caption)
                        Slider(value: $controller.pointerAcceleration.speed, in: PointerAccelerationOptions.speedRange, step: 0.25)
                    }
                }
            }
            Text(controller.accelerationStatus).font(.caption).foregroundStyle(CompanionStyle.muted)
            if controller.savedOriginalScaling != nil {
                Button("Restore original Mac acceleration") { controller.restoreOriginalAcceleration() }
                    .buttonStyle(CompanionButtonStyle(compact: true))
            }
        }
    }
}


private struct WorkspaceNavigationStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @State private var hovered = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .background(CompanionStyle.edge.opacity(hovered && enabled ? 0.035 : 0), in: RoundedRectangle(cornerRadius: 10))
            .opacity(configuration.isPressed ? 0.70 : 1)
            .animation(InterfaceMotion.feedback, value: hovered)
            .onHover { hovered = $0 }
    }
}

private struct RitaNudgeSettings: View {
    @ObservedObject var nudges: RitaStandNudges
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AvatarView(persona: .rita, size: 24).padding(-6)
                Text("Stand-up reminders").font(WorkspaceTypography.section)
                Spacer()
                Toggle("Stand-up reminders", isOn: $nudges.enabled).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
            }
            Stepper(value: $nudges.thresholdMinutes, in: 20...120, step: 5) {
                Text("Remind me after \(nudges.thresholdMinutes) min of continuous use")
            }.disabled(!nudges.enabled)
            Text("Rita reads only how long it has been since your last keyboard or mouse input on this Mac. A 5-minute pause counts as a break.")
                .font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
        }
    }
}

/// Biblioteca: one native tab bar (results, shelf, downloads, file helpers) over a calm,
/// Finder-like content area. Toni's character appears only in the empty state.
private struct LibraryPage: View {
    enum Tab: Hashable { case results, shelf, downloads, helpers }
    @ObservedObject var files: FilesViewModel
    @ObservedObject var artifacts: CompanionArtifactLibrary
    let language: String
    let openSource: (CompanionArtifact) -> Bool
    @AppStorage("library.tab") private var tabName = "results"
    @Environment(\.islandPreview) private var preview
    private var en: Bool { language.hasPrefix("en") }
    private var tab: Tab {
        switch tabName { case "shelf": .shelf; case "downloads": .downloads; case "helpers": .helpers; default: .results }
    }
    private func title(_ tab: Tab) -> String {
        switch tab {
        case .results: en ? "Results" : "Resultados"
        case .shelf: en ? "Shelf" : "Prateleira"
        case .downloads: en ? "Downloads" : "Downloads"
        case .helpers: en ? "Utilities" : "Utilitários"
        }
    }
    private func name(_ tab: Tab) -> String {
        switch tab { case .results: "results"; case .shelf: "shelf"; case .downloads: "downloads"; case .helpers: "helpers" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Picker(en ? "Library section" : "Seção da biblioteca", selection: Binding(get: { tab }, set: { select($0) })) {
                ForEach([Tab.results, .shelf, .downloads, .helpers], id: \.self) { Text(title($0)).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden().fixedSize()
            .frame(maxWidth: .infinity, alignment: .center)
            switch tab {
            case .results:
                CompanionArtifactShelf(library: artifacts, language: language, openSource: openSource, showsHeader: false)
            default:
                FilesView(model: files, showsChrome: false)
            }
        }
        .onAppear { select(tab) }
    }

    private func select(_ new: Tab) {
        tabName = name(new)
        switch new {
        case .shelf: files.page = .shelf
        case .downloads: files.page = .downloads
        case .helpers: files.page = .helpers
        case .results: break
        }
    }
}

/// Tool page header: the team member who looks after the tool, then title and subtitle.
private struct ToolPageHeading: View {
    let title: String
    let subtitle: String
    let owner: LocalChatPersona
    let en: Bool
    let animates: Bool
    @State private var hovered = false
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            CompanionCharacter(size: 58, avatar: owner.avatar, animates: animates && hovered)
                .frame(width: 66, height: 62)
                .onHover { hovered = $0 }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(WorkspaceTypography.title)
                Text(subtitle).font(WorkspaceTypography.body).foregroundStyle(CompanionStyle.muted).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Capsule().fill(CompanionStyle.agent(owner)).frame(width: 3, height: 12)
                    Text(en ? "With \(owner.title)" : "Com \(owner.title == "Rita" || owner.title == "Ada" || owner.title == "Elinor" ? "a" : "o") \(owner.title)")
                        .font(WorkspaceTypography.caption.weight(.medium)).foregroundStyle(CompanionStyle.muted)
                }.padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 4)
    }
}
