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

    @State private var showsAllTools = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if viewModel.page == .companion {
                HStack(spacing: 8) {
                    AvatarView(persona: .sig, size: 26).padding(-6)
                    Text("Chomp").font(.system(size: 15, weight: .semibold))
                    Spacer()
                }.padding(.horizontal, 6).padding(.bottom, 4)
                RitaNudgeRow(nudges: notch.ritaNudges, compact: true)
                RunningNowSection(hidesWhenEmpty: true).padding(.bottom, 4)
                MenuRow(symbol: "timer", title: "Timers") { viewModel.page = .timers }
                MenuRow(symbol: "square.grid.2x2", title: "All tools", trailing: showsAllTools ? "chevron.down" : "chevron.right") {
                    withAnimation(.spring(duration: 0.25, bounce: 0)) { showsAllTools.toggle() }
                }
                if showsAllTools {
                    VStack(spacing: 0) {
                        ForEach(MenuPage.allCases.filter { $0 != .companion && $0 != .timers }, id: \.self) { item in
                            MenuRow(symbol: item.symbol, title: LocalizedStringKey(item.rawValue), indent: true) { viewModel.page = item }
                        }
                    }.transition(.opacity)
                }
                Divider().padding(.vertical, 4)
                MenuRow(symbol: "bubble.left", title: "Talk to Chomp") { notch.show() }
                MenuRow(symbol: "arrow.up.forward.square", title: "Open HeyChomp") { openWindow(id: "main"); notch.focusMainWindow() }
                Divider().padding(.vertical, 4)
                MenuRow(symbol: "power", title: "Quit") { NSApp.terminate(nil) }
            } else {
                Button { viewModel.page = .companion } label: { Label("Chomp", systemImage: "chevron.left") }
                    .buttonStyle(.borderless).font(WorkspaceTypography.section).padding(.bottom, 6)
                toolPage.fixedSize(horizontal: false, vertical: true)
            }
        }.padding(10).frame(width: 320).foregroundStyle(CompanionStyle.ink)
            .background { WorkspaceBackdrop() }.preferredColorScheme(preferences.appearance.colorScheme)
            .environment(\.workspaceGlass, true).environment(\.surfaceGlassEnabled, preferences.windowGlass).environment(\.islandReduceMotion, preferences.usesReducedMotion).focusEffectDisabled()
            .environment(\.companionMotionEnabled, preferences.characterMotion)
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
    var perches = false
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
            if notch.keepAwake.enabled { KeepAwakeRunningRow(controller: notch.keepAwake).perched(.elinor, enabled: perches).padding(.top, perches ? 40 : 0) }
            if assistant.hasTimerActivity { timerRow.perched(.rita, enabled: perches).padding(.top, perches ? 40 : 0) }
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
    /// Island style: Rita steps forward and says it in a speech bubble.
    var bubble = false
    var body: some View {
        if let nudge = nudges.nudge, bubble {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text("You've been sitting for \(nudge.minutes) min").font(.system(size: 12, weight: .semibold)).lineLimit(1)
                    Spacer(minLength: 4)
                    Button("Stand up") { nudges.standUp() }.buttonStyle(.plain).modifier(ChompPill(primary: true))
                    Button("Later") { nudges.later() }.buttonStyle(.plain).modifier(ChompPill())
                }
                .padding(.leading, 14).padding(.trailing, 8).padding(.vertical, 7)
                .background(CompanionStyle.agent(.rita).opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(CompanionStyle.agent(.rita).opacity(0.28), lineWidth: 0.75) }
                // Rita leaves the team row and peeks over her own card.
                .perched(.rita, animates: true, size: 42)
            }
            .padding(.top, 36)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Rita"))
        } else if let nudge = nudges.nudge {
            HStack(alignment: .top, spacing: 12) {
                // Rita peeks over the card in the full layout, so her avatar only shows when compact.
                if compact { AvatarView(persona: .rita, size: 24, speaking: true) }
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
            .perched(.rita, enabled: !compact)
            .padding(.top, compact ? 0 : 40)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Rita"))
        }
    }
}

/// A native-feeling menu row: icon, title, full-width hover highlight.
private struct MenuRow: View {
    let symbol: String
    let title: LocalizedStringKey
    var trailing: String? = nil
    var indent = false
    let action: () -> Void
    @State private var hovered = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 14)).frame(width: 20)
                Text(title).font(.system(size: 13))
                Spacer(minLength: 0)
                if let trailing { Image(systemName: trailing).font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary) }
            }
            .padding(.leading, indent ? 30 : 8).padding(.trailing, 8).padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(hovered ? CompanionStyle.edge.opacity(0.09) : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}
