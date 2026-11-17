import AppKit
import SwiftUI

// Time-based choreography keeps dropped frames from changing the trajectory.
// Opening starts at zero velocity; the damped arrival settles rather than
// snapping between PNGs or replaying an idle loop as a welcome gesture.
struct CompanionEntranceMotion: Equatable {
    var opacity: Double = 1
    var offset: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    var rotation: Double = 0
    var eyeOpen: CGFloat = 1
    var offsetX: CGFloat = 0
    var wave: CGFloat = 0
    var waveAngle: Double = 0
    var joy = false
    static func sample(elapsed: Double, reducedMotion: Bool = false) -> Self {
        guard !reducedMotion else { return Self() }
        let t = max(0, elapsed)
        func smooth(_ value: Double) -> Double { let x = min(1, max(0, value)); return x * x * (3 - 2 * x) }
        let fall = smooth((t - 0.12) / 0.42)
        let landing = t > 0.54 ? exp(-7 * (t - 0.54)) * sin(15 * (t - 0.54)) : 0
        let slide = smooth((t - 0.95) / 0.5) * (1 - smooth((t - 2.6) / 0.7))
        let wave = smooth((t - 1.4) / 0.2) * (1 - smooth((t - 2.45) / 0.25))
        return Self(opacity: smooth((t - 0.06) / 0.2), offset: CGFloat(-1.1 * (1 - fall) + 0.22 * landing),
                    scaleX: CGFloat(0.8 + 0.2 * fall + 0.14 * landing), scaleY: CGFloat(0.8 + 0.2 * fall - 0.17 * landing),
                    rotation: -5 * (1 - fall) - 7 * slide + 3 * landing, eyeOpen: CGFloat(0.08 + 0.92 * smooth((t - 0.42) / 0.3)),
                    offsetX: CGFloat(-0.32 * slide), wave: CGFloat(wave), waveAngle: sin((t - 1.4) * 14) * 23 * wave, joy: wave > 0.5)
    }
}

struct CompanionArrivalView: View {
    var avatar: CompanionAvatar
    var animates = true
    var previewElapsed: Double? = nil
    var size: CGFloat = 154
    @State private var started = Date()
    @State private var gaze = CGSize.zero
    @Environment(\.accessibilityReduceMotion) private var systemReducedMotion
    @Environment(\.islandReduceMotion) private var reducedMotion
    private var moves: Bool { animates && !systemReducedMotion && !reducedMotion }
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !moves || previewElapsed != nil)) { context in
            let elapsed = previewElapsed ?? context.date.timeIntervalSince(started)
            let pose = CompanionEntranceMotion.sample(elapsed: elapsed, reducedMotion: !moves)
            GeometryReader { geometry in
              ZStack {
                Ellipse().fill(avatar.tint.opacity(0.1)).frame(width: size * 0.62, height: 13).blur(radius: 10).offset(y: size * 0.42)
                FollowingPointer(enabled: moves && previewElapsed == nil) { pointer in
                    CompanionCharacter(size: size, avatar: avatar, animates: moves, gaze: gaze == .zero ? pointer : gaze, previewTime: previewElapsed == nil ? nil : 20 + elapsed, entrance: pose)
                }.frame(width: size, height: size)
              }.frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let point): gaze = CompanionGaze.sample(point: point, in: geometry.size)
                    case .ended: gaze = .zero
                    }
                }
            }.frame(height: 220)
        }
        .onAppear { started = Date() }
        .onChange(of: avatar) { _, _ in started = Date() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(avatar.name), your companion")
    }
}

// Center in the actual layout: a fixed x-coordinate biased wide views to the right.
enum CompanionGaze {
    static func sample(point: CGPoint, in size: CGSize) -> CGSize {
        CGSize(width: min(4, max(-4, (point.x - size.width / 2) / max(1, size.width / 8))),
               height: min(3, max(-3, (point.y - size.height / 2) / max(1, size.height / 6))))
    }

    /// Gaze toward a pointer anywhere on screen. Both points use AppKit screen
    /// coordinates (y grows upward); a positive height looks down, as in `sample`.
    static func screen(pointer: CGPoint, center: CGPoint, reach: CGFloat = 260) -> CGSize {
        CGSize(width: min(4, max(-4, (pointer.x - center.x) / reach * 4)),
               height: min(3, max(-3, (center.y - pointer.y) / reach * 3)))
    }

    /// Eases the eyes toward their target so a fast pointer never makes them jump.
    /// A gaze that has settled near rest snaps to exactly zero, which hands the
    /// character back to its own idle glances.
    static func smoothed(_ current: CGSize, toward target: CGSize, rate: CGFloat = 0.28) -> CGSize {
        let next = CGSize(width: current.width + (target.width - current.width) * rate,
                          height: current.height + (target.height - current.height) * rate)
        if target == .zero && abs(next.width) < 0.08 && abs(next.height) < 0.08 { return .zero }
        return next
    }
}

/// Follows the real pointer anywhere on screen while a character is visible.
/// Reading `NSEvent.mouseLocation` needs no Accessibility permission. After a few
/// still seconds the gaze rests, so the character returns to its idle motion and
/// to the cheaper portrait renderer.
@MainActor final class PointerGazeTracker: ObservableObject {
    static let restAfter: TimeInterval = 4
    @Published private(set) var gaze = CGSize.zero
    weak var anchor: NSView?
    private var timer: Timer?
    private var lastPointer: CGPoint?
    private var lastMove = Date.distantPast
    private var current = CGSize.zero

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate(); timer = nil
        current = .zero; lastPointer = nil
        if gaze != .zero { gaze = .zero }
    }

    private func tick() {
        let pointer = NSEvent.mouseLocation, now = Date()
        if pointer != lastPointer { lastPointer = pointer; lastMove = now }
        var target = CGSize.zero
        if now.timeIntervalSince(lastMove) < Self.restAfter, let view = anchor, let window = view.window,
           window.isVisible, window.occlusionState.contains(.visible) {
            let frame = window.convertToScreen(view.convert(view.bounds, to: nil))
            target = CompanionGaze.screen(pointer: pointer, center: CGPoint(x: frame.midX, y: frame.midY))
        }
        current = CompanionGaze.smoothed(current, toward: target)
        let shown = CGSize(width: (current.width * 20).rounded() / 20, height: (current.height * 20).rounded() / 20)
        if shown != gaze { gaze = shown }
    }
}

/// Tells the tracker where the character sits on screen.
private struct PointerGazeAnchor: NSViewRepresentable {
    let tracker: PointerGazeTracker
    func makeNSView(context: Context) -> NSView { let view = NSView(); tracker.anchor = view; return view }
    func updateNSView(_ view: NSView, context: Context) { tracker.anchor = view }
}

/// Hands its content the gaze toward the pointer. Static snapshots get no tracker.
struct FollowingPointer<Content: View>: View {
    var enabled = true
    @ViewBuilder var content: (CGSize) -> Content
    @StateObject private var tracker = PointerGazeTracker()
    @Environment(\.islandPreview) private var staticPreview
    private var active: Bool { enabled && !staticPreview }
    var body: some View {
        if staticPreview {
            content(.zero)
        } else {
            content(active ? tracker.gaze : .zero)
                .background(PointerGazeAnchor(tracker: tracker).allowsHitTesting(false))
                .onAppear { if active { tracker.start() } }
                .onDisappear { tracker.stop() }
                .onChange(of: active) { _, on in if on { tracker.start() } else { tracker.stop() } }
        }
    }
}

struct WelcomeContentPhase: ViewModifier {
    var started: Date?
    var animates: Bool
    @State private var visible = false
    func body(content: Content) -> some View {
        content.opacity(animates && started != nil && !visible ? 0 : 1)
            .task(id: started) {
                guard let started, animates else { visible = true; return }
                visible = false
                let delay = max(0, 9.4 - Date().timeIntervalSince(started))
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.8)) { visible = true }
            }
    }
    static func dock(_ time: Double) -> Double {
        let t = min(1, max(0, (time - 9.4) / 0.8))
        return t * t * (3 - 2 * t)
    }
}

struct CompanionIslandGreeting: View {
    var avatar: CompanionAvatar
    var started: Date
    var previewElapsed: Double? = nil
    var onTouch: () -> Void = {}
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: previewElapsed != nil)) { context in
            let time = previewElapsed ?? context.date.timeIntervalSince(started)
            let dock = WelcomeContentPhase.dock(time)
            GeometryReader { geometry in
                CompanionInteraction(action: onTouch) {
                    CompanionCharacter(size: 96, avatar: avatar, animates: true, previewTime: previewElapsed.map { 20 + $0 }, entrance: CompanionEntranceMotion.sample(elapsed: time))
                }
                .opacity(1 - dock)
                .position(x: geometry.size.width / 2 - (geometry.size.width / 2 - 62) * dock, y: geometry.size.height / 2)
                .accessibilityLabel("Your companion is saying hello")
            }
        }
    }
}
