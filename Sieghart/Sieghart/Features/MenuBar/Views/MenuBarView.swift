import SwiftUI

/// Menu bar popover: what is running now, with one or two actions. Settings forms live
/// in the main window; the other quick tools stay one menu away.
struct MenuBarView: View {
    @StateObject private var viewModel: MenuBarViewModel
    @EnvironmentObject private var assistant: AssistantViewModel
    @EnvironmentObject private var notch: NotchWidgetViewModel
    @EnvironmentObject private var activation: ActivationController
    @EnvironmentObject private var preferences: CompanionPreferences
    @Environment(\.openWindow) private var openWindow
    @Environment(\.islandPreview) private var preview
    init(initialPage: String = "Companion") { _viewModel = StateObject(wrappedValue: MenuBarViewModel(initialPage: initialPage)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Group {
                if viewModel.page == .companion { RunningNowSection(showsEmptyActions: true) }
                else { toolPage }
            }.fixedSize(horizontal: false, vertical: true)
            Divider()
            HStack {
                Button { openWindow(id: "main"); notch.focusMainWindow() } label: { Text("Open HeyChomp") }
                    .buttonStyle(.borderless).keyboardShortcut("o")
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }.buttonStyle(.borderless)
            }.font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
        }.padding(16).frame(width: 340).foregroundStyle(CompanionStyle.ink)
            .background { WorkspaceBackdrop() }.preferredColorScheme(preferences.appearance.colorScheme)
            .environment(\.workspaceGlass, true).environment(\.surfaceGlassEnabled, preferences.windowGlass).environment(\.islandReduceMotion, preferences.usesReducedMotion).focusEffectDisabled()
            .environment(\.companionMotionEnabled, preferences.characterMotion)
    }

    private var header: some View {
        HStack(spacing: 8) {
            if viewModel.page == .companion {
                AvatarView(persona: .sig, size: 22).padding(-6)
                Text("HeyChomp").font(WorkspaceTypography.section)
            } else {
                Button { viewModel.page = .companion } label: { Label("Running now", systemImage: "chevron.left") }
                    .buttonStyle(.borderless).font(WorkspaceTypography.section)
            }
            Spacer()
            Menu {
                ForEach(MenuPage.allCases.filter { $0 != .companion }, id: \.self) { item in
                    Button { viewModel.page = item } label: { Label(LocalizedStringKey(item.rawValue), systemImage: item.symbol) }
                }
            } label: { Image(systemName: "square.grid.2x2") }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                .help(Text("Tools")).accessibilityLabel(Text("Tools"))
        }
    }

    @ViewBuilder private var toolPage: some View {
        switch viewModel.page {
        case .companion: EmptyView()
        case .desktop: ScrollView { DesktopToolsView(model: notch.desktop, compact: true) }.frame(height: 480)
        case .calendar: CalendarView(model: notch.calendar, events: notch.events, compact: true)
        case .files: FilesView(model: notch.files, compact: true)
        case .capture: CaptureToolsView(model: notch.capture, compact: true)
        case .timers: TimerToolsView(compact: true, onStart: { notch.showIsland() })
        case .ai: AIUsageSummary(compact: true)
        case .audio: AudioControlsView(compact: true).environmentObject(notch.audio)
        case .clipboard: ClipboardHistoryView(clipboard: notch.clipboard, compact: true, dismiss: { notch.hide() })
        case .system: SystemMonitorView(monitor: notch.monitor, compact: true)
        case .keepAwake: KeepAwakeView(controller: notch.keepAwake, compact: true)
        case .displayPower: DisplayPowerView(controller: notch.displayPower)
        case .avatars: CompanionTeamGallery(animates: preferences.characterMotion && !preferences.usesReducedMotion, compact: true)
        }
    }
}

/// "Em andamento": the same running rows in the popover and on Hoje.
struct RunningNowSection: View {
    var showsEmptyActions = false
    var hidesWhenEmpty = false
    @EnvironmentObject private var assistant: AssistantViewModel
    @EnvironmentObject private var notch: NotchWidgetViewModel
    private var running: Bool { notch.keepAwake.enabled || assistant.hasTimerActivity }

    var body: some View {
        if hidesWhenEmpty && !running { EmptyView() } else { content }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsEmptyActions { RitaNudgeRow(nudges: notch.ritaNudges, compact: true) }
            Text("Running now").font(WorkspaceTypography.caption.weight(.semibold)).foregroundStyle(CompanionStyle.muted)
            if notch.keepAwake.enabled { KeepAwakeRunningRow(controller: notch.keepAwake) }
            if assistant.hasTimerActivity { timerRow }
            if !notch.keepAwake.enabled && !assistant.hasTimerActivity {
                Text("Nothing running.").font(WorkspaceTypography.body).foregroundStyle(CompanionStyle.muted)
                if showsEmptyActions {
                    HStack(spacing: 8) {
                        Button("Talk to Chomp") { notch.show() }.buttonStyle(CompanionButtonStyle(primary: true, compact: true)).lineLimit(1).fixedSize()
                        Button("Keep awake for 1 hour") {
                            notch.keepAwake.request.mode = .duration; notch.keepAwake.request.minutes = 60; notch.keepAwake.start()
                        }.buttonStyle(CompanionButtonStyle(compact: true)).lineLimit(1).fixedSize()
                    }.padding(.top, 2)
                }
            }
        }
    }

    private var timerRow: some View {
        HStack(spacing: 10) {
            Capsule().fill(CompanionStyle.agent(.rita)).frame(width: 3, height: 16).accessibilityHidden(true)
            Image(systemName: assistant.activeTimerMode.symbol).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(assistant.activityTitle)).font(WorkspaceTypography.body)
                Text("Rita").font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
            }
            Spacer()
            Text(assistant.compactTimeLabel).font(.system(size: 15, weight: .semibold).monospacedDigit())
            Button("Show") { notch.showIsland() }.buttonStyle(CompanionButtonStyle(compact: true))
        }
        .padding(12).background(CompanionStyle.edge.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct KeepAwakeRunningRow: View {
    @ObservedObject var controller: KeepAwakeViewModel
    private var fraction: Double? {
        guard controller.request.mode == .duration, let left = controller.remaining else { return nil }
        let total = Double(controller.request.minutes) * 60
        return total > 0 ? min(1, max(0, 1 - left / total)) : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(CompanionStyle.accent).frame(width: 6, height: 6).accessibilityHidden(true)
                Label("Keep Awake", systemImage: "cup.and.saucer.fill").font(WorkspaceTypography.body)
                Spacer()
                if let left = controller.remaining {
                    Text(Duration.seconds(left).formatted(.time(pattern: .hourMinuteSecond)))
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                        .contentTransition(.numericText(countsDown: true))
                } else { Text("No limit").font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted) }
            }
            if let fraction {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(CompanionStyle.edge.opacity(0.10))
                        Capsule().fill(CompanionStyle.accent).frame(width: proxy.size.width * fraction)
                    }
                }.frame(height: 4).accessibilityHidden(true)
            }
            Text(LocalizedStringKey(controller.status)).font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
            HStack(spacing: 8) {
                if controller.remaining != nil {
                    Button("Extend 30 min") { extend(30) }.buttonStyle(CompanionButtonStyle(primary: true, compact: true))
                }
                Spacer()
                Button("Stop") { controller.stop() }.buttonStyle(CompanionButtonStyle(compact: true))
            }
        }
        .padding(12).background(CompanionStyle.edge.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func extend(_ minutes: Int) {
        let left = Int(((controller.remaining ?? 0) / 60).rounded(.up))
        controller.request.mode = .duration
        controller.request.minutes = min(1440, left + minutes)
        controller.start()
    }
}

/// The nudge primitive at size L/M: who noticed, what, evidence, one action, dismissal.
struct RitaNudgeRow: View {
    @ObservedObject var nudges: RitaStandNudges
    var compact = false
    var body: some View {
        if let nudge = nudges.nudge {
            HStack(alignment: .top, spacing: 12) {
                AvatarView(persona: .rita, size: compact ? 24 : 28, speaking: true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("You've been sitting for \(nudge.minutes) min").font(WorkspaceTypography.body.weight(.semibold))
                    if !compact {
                        Text("No break since \(nudge.since.formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 12)).foregroundStyle(CompanionStyle.ink.opacity(0.8))
                    }
                    HStack(spacing: 8) {
                        Button("Stand up") { nudges.standUp() }.buttonStyle(CompanionButtonStyle(primary: true, compact: true))
                        Button("Later") { nudges.later() }.buttonStyle(CompanionButtonStyle(compact: true))
                    }.padding(.top, 4)
                }
                Spacer(minLength: 0)
                Button { nudges.later() } label: { Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)) }
                    .buttonStyle(.borderless).foregroundStyle(.secondary).accessibilityLabel(Text("Dismiss"))
            }
            .padding(12)
            .background(CompanionStyle.edge.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Rita"))
        }
    }
}
