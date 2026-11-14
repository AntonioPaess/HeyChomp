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
    init(scrollable: Bool = true, clipboard: ClipboardViewModel? = nil, initialStep: Int = 0, arrivalPreviewTime: Double? = nil, onFinish: @escaping () -> Void = {}, prepareVoice: (() async -> String)? = nil) {
        self.scrollable = scrollable; self.clipboard = clipboard; self.arrivalPreviewTime = arrivalPreviewTime; self.onFinish = onFinish; self.prepareVoice = prepareVoice
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(initialStep: initialStep))
    }
    private var chosen: CompanionAvatar { .sig }
    private var moves: Bool { preferences.characterMotion && !preferences.usesReducedMotion && !reducedMotion }
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // The one display-size moment in the app: a centered, quiet header per step.
            if viewModel.step < 2 { VStack(spacing: 8) {
                if viewModel.step > 0 { AvatarView(persona: .sig, size: 40, animates: moves) }
                Text(LocalizedStringKey(viewModel.step == 0 ? "A little companion. A quieter day." : viewModel.step == 1 ? "Meet your team." : "Bring your tools along."))
                    .font(.system(size: 22, weight: .bold))
                Text(LocalizedStringKey(viewModel.step == 0 ? "Meet Chomp. A familiar face for your time and your tools." : viewModel.step == 1 ? "Chomp leads. Five specialists bring their own personality." : "Choose what stays nearby. You can change this anytime."))
                    .font(WorkspaceTypography.body).foregroundStyle(CompanionStyle.muted)
            }.multilineTextAlignment(.center).frame(maxWidth: .infinity) }
            Group {
                if scrollable { ScrollView { page }.scrollIndicators(.hidden) }
                else { page; Spacer(minLength: 0) }
            }
            HStack {
                if viewModel.step > 0 { Button("Back") { viewModel.step -= 1 }.buttonStyle(CompanionButtonStyle()) }
                Spacer()
                VStack(spacing: 6) {
                    HStack(spacing: 6) { ForEach(0..<3) { index in Capsule().fill(viewModel.step == index ? CompanionStyle.accent : CompanionStyle.edge.opacity(0.15)).frame(width: viewModel.step == index ? 20 : 6, height: 6) } }
                    Text("\(viewModel.step + 1) of 3").font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
                }.accessibilityElement(children: .ignore).accessibilityLabel("Step \(viewModel.step + 1) of 3")
                Spacer()
                Button(LocalizedStringKey(viewModel.step == 0 ? "Meet the companions" : viewModel.step == 1 ? "Continue with Chomp" : "Start using Chomp")) {
                    if viewModel.step < 2 { viewModel.step += 1 }
                    else {
                        viewModel.complete(preferences: preferences, usage: usage, codex: codex, clipboard: clipboard)
                        onFinish()
                    }
                }.buttonStyle(CompanionButtonStyle(primary: true)).disabled(viewModel.preparingAccess)
            }
        }.padding(40).frame(maxWidth: 760, maxHeight: .infinity, alignment: .top).frame(maxWidth: .infinity)
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
            if viewModel.step == 0 {
                VStack(spacing: 12) {
                    CompanionTeamArrival(animates: moves, previewTime: arrivalPreviewTime, started: arrivalStarted,
                                         language: preferences.introductionLanguage)
                        .id(arrivalStarted).frame(height: 300)
                    if moves {
                        Button(preferences.introductionLanguage == .english ? "Replay introduction" : "Repetir apresentação", systemImage: "arrow.counterclockwise") {
                            arrivalStarted = Date()
                        }.buttonStyle(.borderless)
                    }
                    Text("Ready when you are.").font(.system(size: 15, weight: .semibold))
                    Text("Keep a timer nearby, find something you copied, or speak a command. Your companion stays with you — without taking over your day.")
                        .font(.callout).foregroundStyle(CompanionStyle.muted).multilineTextAlignment(.center).frame(maxWidth: 470)
                    Text("Chomp is your main companion. Meet Rita, Ada, Gantt, Elinor and Toni.").font(.caption).foregroundStyle(CompanionStyle.muted)
                }.frame(maxWidth: .infinity).padding(.vertical, 8)
            } else if viewModel.step == 1 {
                Button(preferences.introductionLanguage == .english ? "Rehearse voice and selection" : "Ensaiar voz e seleção") { tutorial = true }.buttonStyle(CompanionButtonStyle())
                CompanionTeamGallery(animates: moves)
                Text(chosen.detail).font(.callout).foregroundStyle(CompanionStyle.muted)
                Text("Tap any companion to explore their movements. Chomp stays with you in the island, voice and focus sessions.")
                    .font(.caption).foregroundStyle(CompanionStyle.muted)
            } else {
                HStack(alignment: .center, spacing: 36) {
                    OnboardingTeamCluster(animates: moves).frame(width: 320, height: 340)
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
