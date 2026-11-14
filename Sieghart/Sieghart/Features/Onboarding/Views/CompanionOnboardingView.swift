import SwiftUI

struct CompanionOnboardingView: View {
    @State private var tutorial = false
    @State private var arrivalStarted = Date()
    @StateObject private var viewModel: OnboardingViewModel
    @EnvironmentObject private var preferences: CompanionPreferences
    @EnvironmentObject private var codex: CodexUsageViewModel
    @EnvironmentObject private var usage: AIUsageViewModel
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    var scrollable: Bool
    var clipboard: ClipboardViewModel?
    var prepareVoice: (() async -> String)?
    var onFinish: () -> Void
    var arrivalPreviewTime: Double?
    var showCompanion: (() -> Void)?
    @State private var hello = ""
    @State private var greeted = false
    @State private var greetReplay = 0
    @State private var calledCompanion = false
    private var en: Bool { preferences.introductionLanguage == .english }
    init(scrollable: Bool = true, clipboard: ClipboardViewModel? = nil, initialStep: Int = 0, arrivalPreviewTime: Double? = nil, onFinish: @escaping () -> Void = {}, prepareVoice: (() async -> String)? = nil, showCompanion: (() -> Void)? = nil) {
        self.scrollable = scrollable; self.clipboard = clipboard; self.arrivalPreviewTime = arrivalPreviewTime; self.onFinish = onFinish; self.prepareVoice = prepareVoice; self.showCompanion = showCompanion
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(initialStep: initialStep))
    }
    private var chosen: CompanionAvatar { .sig }
    private var moves: Bool { preferences.characterMotion && !preferences.usesReducedMotion && !reducedMotion }
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // HeyClicky-style: you learn by doing. Four short missions, checked off as you go.
            missionStrip
            Group {
                if scrollable { ScrollView { page }.scrollIndicators(.hidden) }
                else { page; Spacer(minLength: 0) }
            }
            HStack {
                if viewModel.step > 0 { Button("Back") { viewModel.step -= 1 }.buttonStyle(CompanionButtonStyle()) }
                Spacer()
                VStack(spacing: 6) {
                    HStack(spacing: 6) { ForEach(0..<4) { index in Capsule().fill(viewModel.step == index ? CompanionStyle.accent : CompanionStyle.edge.opacity(0.15)).frame(width: viewModel.step == index ? 20 : 6, height: 6) } }
                    Text("\(viewModel.step + 1) of 4").font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
                }.accessibilityElement(children: .ignore).accessibilityLabel("Step \(viewModel.step + 1) of 4")
                Spacer()
                Button(LocalizedStringKey(viewModel.step == 3 ? "Start using Chomp" : (viewModel.step == 0 && !greeted) || (viewModel.step == 2 && !calledCompanion) ? "Skip" : "Continue")) {
                    if viewModel.step < 3 { viewModel.step += 1 }
                    else {
                        viewModel.complete(preferences: preferences, usage: usage, codex: codex, clipboard: clipboard)
                        onFinish()
                    }
                }.buttonStyle(CompanionButtonStyle(primary: true)).disabled(viewModel.preparingAccess)
            }
        }.padding(40).frame(maxWidth: 860, maxHeight: .infinity, alignment: .top).frame(maxWidth: .infinity)
            .foregroundStyle(CompanionStyle.ink).background { WorkspaceBackdrop() }.preferredColorScheme(preferences.appearance.colorScheme)
            .environment(\.workspaceGlass, true).environment(\.surfaceGlassEnabled, preferences.windowGlass)
            .environment(\.islandReduceMotion, preferences.usesReducedMotion)
            .animation(moves ? .spring(response: 0.55, dampingFraction: 0.86) : nil, value: viewModel.step)
            .sheet(isPresented: $tutorial) { CompanionVoiceTutorial(language: preferences.introductionLanguage == .english ? "en" : "pt") }
            .onAppear { viewModel.loadTools(usage: usage, clipboard: clipboard) }
            .onChange(of: viewModel.step) { _, step in if step == 0 { arrivalStarted = Date() } }
            .onChange(of: moves) { _, enabled in if enabled { arrivalStarted = Date() } }
    }
    private var page: some View {
        VStack(alignment: .leading, spacing: 18) {
            if viewModel.step == 0 { helloMission }
            else if viewModel.step == 1 { teamMission }
            else if viewModel.step == 2 { anywhereMission }
            else {
                HStack(alignment: .center, spacing: 36) {
                    // Larger and lower, so the team sits level with the copy instead of above it.
                    OnboardingTeamCluster(animates: moves).scaleEffect(1.12).offset(y: 44).frame(width: 340, height: 440)
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bring your tools along").font(.system(size: 30, weight: .bold))
                            Text("Give Chomp optional access to this Mac for a more complete, useful experience.")
                                .font(.system(size: 15)).foregroundStyle(CompanionStyle.muted).fixedSize(horizontal: false, vertical: true)
                        }
                        HStack(spacing: 10) {
                            ForEach(AIProvider.allCases) { provider in
                                HStack(spacing: 6) {
                                    ProviderMark(provider: provider, size: 18)
                                    Text(provider.title).font(WorkspaceTypography.caption.weight(.medium))
                                    if viewModel.detected.contains(provider) { Image(systemName: "checkmark").font(.caption2.weight(.bold)).foregroundStyle(.secondary) }
                                }
                                .help(viewModel.detected.contains(provider) ? "Detected on this Mac" : "Available when installed")
                            }
                        }
                        optionCard(symbol: "cpu", title: "Follow local AI usage",
                                   detail: "Lets Chomp read, on this Mac, token counts and work status of your AI tools. Conversation text is not saved.",
                                   isOn: $viewModel.allowUsage)
                        optionCard(symbol: "doc.on.clipboard", title: "Save clipboard history",
                                   detail: "Lets Chomp keep, on this Mac, a history of what you copy so you can find, pin and reuse it. Password managers are skipped.",
                                   isOn: $viewModel.allowClipboard)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 10) {
                    if let prepareVoice {
                        Button(viewModel.preparingAccess ? "Preparing voice…" : "Set up voice access") {
                            viewModel.prepareVoice(using: prepareVoice)
                        }.buttonStyle(CompanionButtonStyle(compact: true)).disabled(viewModel.preparingAccess)
                    }
                    if viewModel.allowClipboard, let clipboard { Button("Set up direct paste") { clipboard.requestPasteAccess(); viewModel.accessStatus = clipboard.status }.buttonStyle(CompanionButtonStyle(compact: true)) }
                }
                if !viewModel.accessStatus.isEmpty { Text(viewModel.accessStatus).font(.caption).foregroundStyle(CompanionStyle.accentInk) }
                Text("Your companion and timers work offline with both options off. Access setup is optional; you can also grant it when using voice or direct paste later.")
                    .font(.caption).foregroundStyle(CompanionStyle.muted)
            }
        }.id(viewModel.step).transition(.opacity.combined(with: .offset(x: moves ? 14 : 0)))
    }

    private var missionStrip: some View {
        let titles: [LocalizedStringKey] = ["Say hi", "Meet the team", "Call me anywhere", "Your tools"]
        let done = [greeted, viewModel.step > 1, calledCompanion, false]
        return HStack(spacing: 8) {
            ForEach(0..<4) { index in
                let current = viewModel.step == index
                HStack(spacing: 7) {
                    ZStack {
                        Circle().fill(done[index] ? CompanionStyle.accent : current ? CompanionStyle.edge.opacity(0.12) : CompanionStyle.edge.opacity(0.05))
                        if done[index] { Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(CompanionStyle.accentOnFill) }
                        else { Text("\(index + 1)").font(.system(size: 11, weight: .semibold)).foregroundStyle(current ? CompanionStyle.ink : CompanionStyle.muted) }
                    }.frame(width: 22, height: 22)
                    Text(titles[index]).font(.system(size: 13, weight: current ? .semibold : .regular))
                        .foregroundStyle(current ? CompanionStyle.ink : CompanionStyle.muted).lineLimit(1)
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(current ? CompanionStyle.edge.opacity(0.06) : .clear, in: Capsule())
                if index < 3 { Rectangle().fill(CompanionStyle.edge.opacity(0.12)).frame(height: 1).frame(maxWidth: 28) }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(moves ? .spring(duration: 0.3, bounce: 0.2) : nil, value: done)
    }

    /// Mission 1: watch Chomp arrive, then say hi. He answers with a wave.
    private var helloMission: some View {
        VStack(spacing: 16) {
            if greeted {
                CompanionCharacter(size: 170, avatar: .sig, animates: moves, animation: .hello, replay: greetReplay)
                    .frame(height: 190).transition(.scale(scale: 0.8).combined(with: .opacity))
                Text("Nice to meet you! That's all it takes.").font(.system(size: 26, weight: .bold))
                Text("Type or speak to Chomp whenever you need. Next, meet the team that works with him.")
                    .font(.system(size: 15)).foregroundStyle(CompanionStyle.muted).multilineTextAlignment(.center).frame(maxWidth: 520)
            } else {
                CompanionTeamArrival(animates: moves, previewTime: arrivalPreviewTime, started: arrivalStarted,
                                     language: preferences.introductionLanguage)
                    .id(arrivalStarted).frame(height: 280)
                Text("Say hi to Chomp.").font(.system(size: 26, weight: .bold))
                HStack(spacing: 8) {
                    TextField(en ? "Write hi…" : "Escreva oi…", text: $hello)
                        .textFieldStyle(.plain).font(.system(size: 15)).onSubmit(greet)
                    Button { greet() } label: { Image(systemName: "arrow.up").font(.system(size: 13, weight: .bold)) }
                        .buttonStyle(AgentChatSendStyle()).disabled(hello.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityLabel(en ? "Send" : "Enviar")
                }
                .padding(.leading, 16).padding(.trailing, 6).padding(.vertical, 6)
                .background(CompanionStyle.edge.opacity(0.05), in: Capsule())
                .overlay { Capsule().strokeBorder(CompanionStyle.edge.opacity(0.12), lineWidth: 0.75) }
                .frame(maxWidth: 420)
            }
        }
        .frame(maxWidth: .infinity).padding(.top, 8)
    }
    private func greet() {
        guard !hello.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(moves ? .spring(duration: 0.45, bounce: 0.3) : nil) { greeted = true }
        greetReplay += 1
    }

    /// Mission 2: the character select, so each specialist introduces themself.
    private var teamMission: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Meet your team.").font(.system(size: 30, weight: .bold))
                Text("Hover over each one. They'll tell you what they do.").font(.system(size: 15)).foregroundStyle(CompanionStyle.muted)
            }
            CompanionTeamPage(language: en ? "en" : "pt", animates: moves, showsChat: false)
        }
    }

    /// Mission 3: bring Chomp up for real, at the top of the screen.
    private var anywhereMission: some View {
        HStack(alignment: .center, spacing: 36) {
            CompanionCharacter(size: 170, avatar: .sig, animates: moves, animation: calledCompanion ? .proud : .wink, replay: calledCompanion ? 1 : 0)
                .frame(width: 260, height: 260)
            VStack(alignment: .leading, spacing: 14) {
                Text("Call me from anywhere.").font(.system(size: 30, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                Text("Chomp lives at the top of your screen, in any app. Click him there, or use your shortcut and just talk.")
                    .font(.system(size: 15)).foregroundStyle(CompanionStyle.muted).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    Button { showCompanion?(); withAnimation { calledCompanion = true } } label: { Label("Show Chomp now", systemImage: "arrow.up.to.line") }
                        .buttonStyle(CompanionButtonStyle())
                    Button(en ? "Rehearse voice and selection" : "Ensaiar voz e seleção") { tutorial = true }.buttonStyle(.borderless)
                }
                if calledCompanion {
                    Label("There he is, at the top of the screen.", systemImage: "checkmark.circle.fill")
                        .font(WorkspaceTypography.body).foregroundStyle(CompanionStyle.ink)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.top, 16)
    }

    private func featureRow(_ symbol: String, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 15)).frame(width: 34, height: 34)
                .background(CompanionStyle.edge.opacity(0.06), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(text).font(.system(size: 14, weight: .medium))
        }
    }

    private func optionCard(symbol: String, title: LocalizedStringKey, detail: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol).font(.system(size: 18)).foregroundStyle(CompanionStyle.ink)
                .frame(width: 40, height: 40)
                .background(CompanionStyle.edge.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold)).fixedSize(horizontal: false, vertical: true)
                Text(detail).font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle(title, isOn: isOn).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
        }
        .padding(16)
        .background(CompanionStyle.edge.opacity(0.03), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(CompanionStyle.edge.opacity(0.08), lineWidth: 0.5) }
    }
}

/// The whole team gathered around Chomp's sparkle, for the last onboarding step.
private struct OnboardingTeamCluster: View {
    let animates: Bool
    var body: some View {
        ZStack {
            Ellipse().fill(CompanionStyle.edge.opacity(0.06)).frame(width: 280, height: 60).blur(radius: 10).offset(y: 140)
            Image(systemName: "sparkle").font(.system(size: 26, weight: .semibold)).foregroundStyle(Color(red: 0.16, green: 0.82, blue: 0.56)).offset(x: 6, y: -4)
            CompanionCharacter(size: 112, avatar: .gantt, animates: animates).offset(x: -70, y: -96)
            CompanionCharacter(size: 108, avatar: .toni, animates: animates).offset(x: 62, y: -100)
            CompanionCharacter(size: 118, avatar: .rita, animates: animates).offset(x: -96, y: 8)
            CompanionCharacter(size: 108, avatar: .elinor, animates: animates).offset(x: 92, y: 0)
            CompanionCharacter(size: 132, avatar: .sig, animates: animates).offset(x: -24, y: 92)
            CompanionCharacter(size: 112, avatar: .ada, animates: animates).offset(x: 92, y: 100)
        }
        .accessibilityHidden(true)
    }
}
