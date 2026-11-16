import AppKit
import SwiftUI

// HeyChomp visual system v5 ("quiet window, loud characters"); see
// Design/Workflow/handoff-design-2026-11-11/visual-system-v5-arena-2026-11-13.md.
// One accent per appearance, taken from Chomp's mint sparkle. Agent colors are
// marks only (rings and markers), never text or fills.
enum CompanionStyle {
    static let notchBlack = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
    static let background = adaptive(dark: (30, 30, 30), light: (255, 255, 255))
    static let surface = adaptive(dark: (37, 37, 37), light: (247, 247, 247))
    static let separator = adaptive(dark: (52, 52, 52), light: (230, 230, 230))
    /// Chomp's mint: #00945F light, #3EDC9A dark. Fills, switches, progress and rings only.
    static let accent = adaptive(dark: (62, 220, 154), light: (0, 148, 95), contrastDark: (111, 240, 184), contrastLight: (0, 88, 58))
    /// Label on an accent fill (4.85:1 light, 10.5:1 dark).
    static let accentOnFill = adaptive(dark: (4, 23, 15), light: (0, 21, 12), contrastDark: (4, 23, 15), contrastLight: (255, 255, 255))
    /// Text and glyphs that used to be tinted lavender are now plain primary content.
    static let accentInk = adaptive(dark: (221, 221, 221), light: (38, 38, 38))
    /// Small metadata: 7.0:1 on white and 6.4:1 on #1E1E1E.
    static let muted = adaptive(dark: (160, 160, 160), light: (89, 89, 89), contrastDark: (200, 200, 200), contrastLight: (60, 60, 60))
    static let sidebar = adaptive(dark: (40, 40, 40), light: (246, 246, 246))
    static let ink = Color.primary
    static let edge = adaptive(dark: (255, 255, 255), light: (0, 0, 0))
    /// Off-state outline and knob of switches (3:1 non-text on every floor).
    static let controlStroke = adaptive(dark: (138, 138, 138), light: (122, 122, 122), contrastDark: (170, 170, 170), contrastLight: (89, 89, 89))
    /// Light/dark pair, with optional Increase Contrast variants (spec §2.3 and §7).
    private static func adaptive(dark: (Double, Double, Double), light: (Double, Double, Double),
                                 contrastDark: (Double, Double, Double)? = nil, contrastLight: (Double, Double, Double)? = nil) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua]).map { $0 == .darkAqua || $0 == .accessibilityHighContrastDarkAqua } ?? false
            let increased = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
            let rgb = isDark ? (increased ? contrastDark ?? dark : dark) : (increased ? contrastLight ?? light : light)
            return NSColor(srgbRed: rgb.0 / 255, green: rgb.1 / 255, blue: rgb.2 / 255, alpha: 1)
        })
    }
    /// Agent mark colors (§3.2 of the spec). Never use for text.
    static func agent(_ persona: LocalChatPersona) -> Color {
        switch persona {
        case .sig: accent
        case .rita: adaptive(dark: (219, 156, 246), light: (97, 33, 109))
        case .ada: adaptive(dark: (20, 151, 165), light: (11, 106, 135))
        case .gantt: adaptive(dark: (243, 227, 52), light: (119, 81, 19))
        case .elinor: adaptive(dark: (207, 123, 3), light: (204, 95, 1))
        case .toni: adaptive(dark: (169, 110, 252), light: (40, 6, 191))
        }
    }
}

enum WorkspaceMetrics {
    static let pageInset: CGFloat = 20
    static let sectionGap: CGFloat = 20
    static let contentWidth: CGFloat = 1080
    /// Readable column for Hoje, Equipe and Biblioteca.
    static let readableWidth: CGFloat = 720
    static let cardInset: CGFloat = 12
    static let cardRadius: CGFloat = 8
}

enum WorkspaceTypography {
    static let title = Font.system(size: 17, weight: .bold)
    static let hero = Font.system(size: 17, weight: .bold)
    static let section = Font.system(size: 13, weight: .semibold)
    static let body = Font.system(size: 13)
    static let caption = Font.system(size: 11)
    static let footnote = Font.system(size: 10)
}

// One restrained cadence for navigation, control feedback and first appearance.
// Repeated interactions never wait for decorative character choreography.
enum InterfaceMotion {
    static let feedbackDuration = 0.14
    static let pageDuration = 0.22
    static let arrivalDuration = 0.30
    static let feedback = Animation.easeOut(duration: feedbackDuration)
    static let page = Animation.easeOut(duration: pageDuration)
    static let arrival = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: arrivalDuration)
}

struct WorkspacePageArrival: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReducedMotion
    @Environment(\.islandReduceMotion) private var reducedMotion
    @Environment(\.islandPreview) private var preview
    @State private var arrived = false
    private var visible: Bool { arrived || preview || reducedMotion || systemReducedMotion }
    func body(content: Content) -> some View {
        content.opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 6)
            .task {
                guard !arrived else { return }
                if reducedMotion || systemReducedMotion || preview { arrived = true }
                else { withAnimation(InterfaceMotion.arrival) { arrived = true } }
            }
    }
}

struct WorkspacePageHeading: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(WorkspaceTypography.title)
                .foregroundStyle(CompanionStyle.ink)
            Text(subtitle).font(WorkspaceTypography.body).foregroundStyle(CompanionStyle.muted)
                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 2)
    }
}

struct WorkspaceEmptyState: View {
    let title: String
    let detail: String
    let symbol: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 21, weight: .light))
                .foregroundStyle(.secondary).frame(width: 48, height: 48)
                .background(CompanionStyle.edge.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title).font(WorkspaceTypography.section)
            Text(detail).font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted)
                .multilineTextAlignment(.center).frame(maxWidth: 340)
        }.padding(.vertical, 28).frame(maxWidth: .infinity)
    }
}

private struct WorkspaceGlassKey: EnvironmentKey { static let defaultValue = false }
private struct SurfaceGlassEnabledKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var workspaceGlass: Bool { get { self[WorkspaceGlassKey.self] } set { self[WorkspaceGlassKey.self] = newValue } }
    var surfaceGlassEnabled: Bool { get { self[SurfaceGlassEnabledKey.self] } set { self[SurfaceGlassEnabledKey.self] = newValue } }
}

struct WorkspaceBackdrop: View {
    var body: some View {
        CompanionStyle.background.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct WorkspaceSurface: ViewModifier {
    var selected = false
    var radius: CGFloat = WorkspaceMetrics.cardRadius
    @Environment(\.colorSchemeContrast) private var contrast
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        // Object cards stay opaque. Native navigation and toolbars own material.
        content.background(CompanionStyle.surface, in: shape)
            .overlay {
                shape.strokeBorder(selected ? CompanionStyle.accentInk.opacity(0.65) : CompanionStyle.edge.opacity(contrast == .increased ? 0.48 : 0.075), lineWidth: selected ? 1.5 : 0.7)
                    .allowsHitTesting(false)
            }
    }
}

struct CompanionButtonStyle: ButtonStyle {
    var primary = false
    var compact = false
    func makeBody(configuration: Configuration) -> some View {
        CompanionButtonBody(label: configuration.label, pressed: configuration.isPressed, primary: primary, compact: compact)
    }
}
private struct CompanionButtonBody<Label: View>: View {
    let label: Label
    let pressed: Bool
    let primary: Bool
    let compact: Bool
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.islandReduceMotion) private var preferenceReduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var hovered = false
    var body: some View {
        let still = reduceMotion || preferenceReduceMotion
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        label.font(.system(size: compact ? 12 : 13, weight: .medium))
            .padding(.horizontal, compact ? 10 : 14).padding(.vertical, compact ? 4 : 6)
            .frame(minHeight: compact ? 24 : 28)
            .foregroundStyle(primary ? CompanionStyle.accentOnFill : CompanionStyle.ink)
            .background(primary ? CompanionStyle.accent : CompanionStyle.edge.opacity(hovered ? 0.10 : 0.06), in: shape)
            .overlay { if contrast == .increased { shape.strokeBorder(CompanionStyle.edge.opacity(0.6), lineWidth: 1).allowsHitTesting(false) } }
            .opacity(enabled ? (pressed ? 0.85 : 1) : 0.42)
            .scaleEffect(pressed && !still ? 0.97 : 1)
            .animation(still ? .easeInOut(duration: 0.15) : .easeOut(duration: 0.12), value: hovered)
            .animation(still ? nil : .spring(duration: 0.18, bounce: 0), value: pressed)
            .onHover { hovered = $0 }
    }
}

struct WorkspaceSwitchStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            Capsule().fill(configuration.isOn ? CompanionStyle.accent : CompanionStyle.edge.opacity(0.06))
                .overlay { Capsule().stroke(configuration.isOn ? Color.clear : CompanionStyle.controlStroke, lineWidth: 1.5).padding(0.75) }
                .frame(width: 36, height: 22)
            .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                Circle().fill(configuration.isOn ? CompanionStyle.accentOnFill : CompanionStyle.controlStroke)
                    .frame(width: 14, height: 14).padding(4)
            }
        }.buttonStyle(.plain).focusEffectDisabled()
            .animation(reduceMotion ? nil : .spring(duration: 0.2, bounce: 0), value: configuration.isOn)
            .accessibilityRepresentation {
                Toggle(isOn: configuration.$isOn) { configuration.label }.toggleStyle(.switch)
            }
    }
}

// Custom interaction avoids AppKit's rectangular mouse focus ring. Keyboard
// navigation and VoiceOver keep a real action and a rounded focus indicator.
struct CompanionInteraction<Content: View>: View {
    var action: () -> Void
    var content: Content
    @FocusState private var keyboardFocused: Bool
    @State private var pointerActivated = false
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action; self.content = content()
    }
    var body: some View {
        content
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture { pointerActivated = true; action() }
            .focusable()
            .focused($keyboardFocused)
            .focusEffectDisabled()
            .background(keyboardFocused && !pointerActivated ? .white.opacity(0.045) : .clear, in: RoundedRectangle(cornerRadius: 16))
            .onChange(of: keyboardFocused) { _, focused in if !focused { pointerActivated = false } }
            .onKeyPress(keys: [.space, .return]) { _ in pointerActivated = false; action(); return .handled }
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
    }
}

extension View {
    @ViewBuilder
    func companionCard(height: CGFloat? = nil, padding: CGFloat? = nil) -> some View {
        modifier(CompanionCardModifier(height: height, inset: padding))
    }
}

private struct CompanionCardModifier: ViewModifier {
    var height: CGFloat?
    var inset: CGFloat?
    @Environment(\.islandGlass) private var glass
    @Environment(\.workspaceGlass) private var workspace
    func body(content: Content) -> some View {
        let padding: CGFloat = inset ?? (workspace ? WorkspaceMetrics.cardInset : !glass ? 22 : 16)
        let sized = content.frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: height.map { max(0, $0 - padding * 2) }, alignment: .topLeading).padding(padding)
        if workspace {
            content.frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: height, alignment: .topLeading)
                .padding(.vertical, inset ?? 18)
                .overlay(alignment: .bottom) { Divider().allowsHitTesting(false) }
        }
        else if glass { sized.modifier(IslandControlSurface()) }
        else { sized.background(CompanionStyle.surface, in: RoundedRectangle(cornerRadius: WorkspaceMetrics.cardRadius)) }
    }
}

/// A character on a quiet neutral plate with a 1 pt rim, so near-black bodies keep a
/// silhouette on dark surfaces. The agent-colored ring is drawn outside the plate with
/// a gap, and only while that agent is speaking (spec §3.4). The slot for the ring is
/// always reserved, so nothing shifts when it appears.
struct AvatarView: View {
    let persona: LocalChatPersona
    var size: CGFloat = 28
    var speaking = false
    var animates = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    private var plate: Color { scheme == .dark ? Color(red: 48 / 255, green: 48 / 255, blue: 48 / 255) : Color(red: 237 / 255, green: 237 / 255, blue: 240 / 255) }
    private var rim: Color { scheme == .dark ? Color.white.opacity(0.45) : Color.black.opacity(0.5) }
    private var ringWidth: CGFloat { contrast == .increased ? 3.5 : 2.5 }
    var body: some View {
        let slot: CGFloat = 6
        ZStack {
            Circle().strokeBorder(CompanionStyle.agent(persona), lineWidth: ringWidth)
                .opacity(speaking ? 1 : 0)
                .frame(width: size + 3 + ringWidth * 2, height: size + 3 + ringWidth * 2)
            Circle().fill(plate).frame(width: size, height: size)
                .overlay { Circle().strokeBorder(rim, lineWidth: 1) }
                .overlay { CompanionCharacter(size: size * 0.92, avatar: persona.avatar, animates: animates) }
        }
        .frame(width: size + slot * 2, height: size + slot * 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(persona.title)
        .help(persona.title)
    }
}

extension View {
    /// The agent who owns a card peeks over its top edge: head and eyes above the line,
    /// two little hands gripping the border, a few motion ticks in their colour.
    /// One component for the app, the menu bar widget and the island (a HeyChomp signature).
    func perched(_ persona: LocalChatPersona, animates: Bool = false, size: CGFloat = 48, enabled: Bool = true) -> some View {
        overlay(alignment: .topTrailing) {
            if enabled {
                PeekingCharacter(persona: persona, animates: animates, size: size)
                    // The peek's bottom (the hands' line) sits on the card's top edge.
                    .offset(x: -16, y: -PeekingCharacter.edge(size))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// A teammate peeking over an edge (illustrated assets `Peek-<persona>`).
/// Every asset shares one geometry: 480×340 at 2x, the edge at row 250, body width 330.
struct PeekingCharacter: View {
    let persona: LocalChatPersona
    var animates = false
    /// Roughly the width of the head, in points.
    var size: CGFloat = 48
    @State private var popped = false
    static func width(_ size: CGFloat) -> CGFloat { size * 1.6 }
    static func height(_ size: CGFloat) -> CGFloat { width(size) * 340 / 480 }
    /// Distance from the view's top to the edge the hands hold on to.
    static func edge(_ size: CGFloat) -> CGFloat { height(size) * 250 / 340 }
    var body: some View {
        Image("Peek-\(persona.rawValue)")
            .resizable().interpolation(.high)
            .frame(width: Self.width(size), height: Self.height(size))
            .offset(y: popped ? 0 : size * 0.18)
            .opacity(popped ? 1 : 0)
            .onAppear {
                guard animates else { popped = true; return }
                withAnimation(.spring(duration: 0.45, bounce: 0.35)) { popped = true }
            }
    }
}

/// A teammate says something in a speech bubble: used for empty states and hints, so
/// quiet screens still feel like the team is there.
struct OwnerSays: View {
    let persona: LocalChatPersona
    let text: LocalizedStringKey
    var compact = false
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            CompanionCharacter(size: compact ? 26 : 34, avatar: persona.avatar, animates: false)
                .frame(width: compact ? 30 : 40, height: compact ? 26 : 34)
                .accessibilityHidden(true)
            Text(text).font(.system(size: compact ? 11 : 12.5)).foregroundStyle(CompanionStyle.ink.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12).padding(.vertical, compact ? 6 : 9)
                .background { ChompSpeechBubble().fill(CompanionStyle.agent(persona).opacity(0.10)) }
                .overlay { ChompSpeechBubble().stroke(CompanionStyle.agent(persona).opacity(0.22), lineWidth: 0.75) }
        }
        .padding(.vertical, 4)
    }
}

/// A titled group on a tool page: quiet card, generous spacing (Things-like), our neutrals.
struct ToolGroup<Content: View>: View {
    let title: LocalizedStringKey
    var detail: LocalizedStringKey? = nil
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 8)
                if let detail { Text(detail).font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted) }
            }
            VStack(alignment: .leading, spacing: 10) { content }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CompanionStyle.edge.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(CompanionStyle.edge.opacity(0.08), lineWidth: 0.75) }
        }
    }
}

/// A switch row with its status line underneath, for tool settings.
struct ToolToggleRow: View {
    let title: LocalizedStringKey
    var status: LocalizedStringKey? = nil
    @Binding var isOn: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .medium))
                if let status { Text(status).font(WorkspaceTypography.caption).foregroundStyle(CompanionStyle.muted).fixedSize(horizontal: false, vertical: true) }
            }
            Spacer(minLength: 8)
            Toggle(title, isOn: $isOn).labelsHidden().toggleStyle(WorkspaceSwitchStyle())
        }
    }
}

