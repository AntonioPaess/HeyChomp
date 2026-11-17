import AppKit
import Combine
import SwiftUI

final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

final class HoverZonePanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

final class HoverZoneView: FileDropTargetView {
    var onEnter: (() -> Void)?
    var onExit: (() -> Void)?
    var onClick: (() -> Void)?

    private var trackingArea: NSTrackingArea?
    override func hitTest(_ point: NSPoint) -> NSView? { bounds.contains(convert(point, from: superview)) ? self : nil }

    override func updateTrackingAreas() {
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
        super.updateTrackingAreas()
    }

    override func mouseDown(with event: NSEvent) { onClick?() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseEntered(with event: NSEvent) {
        onEnter?()
    }

    override func mouseExited(with event: NSEvent) {
        onExit?()
    }
}

// MARK: - Chomp's sparkle beside the pointer

/// Pure placement rules for the mint sparkle that keeps the pointer company.
/// The panel is larger than the sparkle so its glow is never clipped.
enum CursorCompanionLayout {
    static let size: CGFloat = 30
    static let sparkle: CGFloat = 14
    /// The gap between the pointer tip and the panel.
    static let gap = CGSize(width: 6, height: 8)
    /// Pointer stillness, in seconds, before the sparkle dims.
    static let sleepAfter: TimeInterval = 8
    /// Band below the top of a screen where the island lives; the sparkle steps aside there.
    static let islandBand: CGFloat = 70

    /// Bottom-left origin of the panel, in AppKit screen coordinates. The sparkle sits
    /// below and to the right of the pointer, and moves to its left near the right edge.
    static func origin(pointer: CGPoint, screen: CGRect) -> (origin: CGPoint, onLeft: Bool) {
        let onLeft = pointer.x + gap.width + size > screen.maxX
        let x = onLeft ? pointer.x - gap.width - size : pointer.x + gap.width
        let below = pointer.y - gap.height - size
        let y = below < screen.minY ? pointer.y + gap.height : below
        return (CGPoint(x: x, y: y), onLeft)
    }

    static func hidesNearIsland(pointer: CGPoint, screen: CGRect) -> Bool { pointer.y > screen.maxY - islandBand }

    /// Eases toward the target so the sparkle trails the pointer instead of being glued to it.
    static func follow(_ current: CGPoint, toward target: CGPoint, rate: CGFloat = 0.24) -> CGPoint {
        CGPoint(x: current.x + (target.x - current.x) * rate, y: current.y + (target.y - current.y) * rate)
    }
}

final class CursorCompanionPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

@MainActor final class CursorCompanionState: ObservableObject {
    @Published var resting = false
    /// Chomp is listening, thinking or working on something for the user.
    @Published var busy = false
}

/// Chomp's mint sparkle, the same one beside his eyes on the island. It is also the
/// tip of his pen when he draws or circles part of the screen.
private struct CursorSparkleView: View {
    @ObservedObject var state: CursorCompanionState
    let animates: Bool
    private static let mint = Color(red: 0.38, green: 0.98, blue: 0.73)
    private static let glow = Color(red: 0.24, green: 0.86, blue: 0.6)
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !(animates && state.busy))) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let pulse = animates && state.busy ? (sin(t * 5) + 1) / 2 : 0
            Image(systemName: "sparkle")
                .font(.system(size: CursorCompanionLayout.sparkle, weight: .semibold))
                .foregroundStyle(Self.mint)
                // A thin dark rim keeps the mint legible on white pages.
                .shadow(color: .black.opacity(0.28), radius: 0.6)
                .shadow(color: Self.glow.opacity(state.resting ? 0 : 0.55 + 0.4 * pulse), radius: 3 + 3 * pulse)
                .scaleEffect(state.resting ? 0.8 : 1 + 0.22 * pulse)
                .rotationEffect(.degrees(animates && state.busy ? t.truncatingRemainder(dividingBy: 4) * 90 : 0))
                .opacity(state.resting ? 0.45 : 1)
        }
        .frame(width: CursorCompanionLayout.size, height: CursorCompanionLayout.size)
        .animation(animates ? .easeOut(duration: 0.35) : nil, value: state.resting)
    }
}

/// Chomp's mint sparkle trailing the pointer across every app. The panel never takes
/// focus or clicks, joins every Space but not full-screen apps, steps aside under the
/// island, dims when the pointer rests and pulses while Chomp is busy.
@MainActor final class CursorCompanion {
    /// Read each frame; whatever Chomp is doing for the user right now.
    var phase: () -> CompanionVoicePhase = { .inactive }
    private var panel: CursorCompanionPanel?
    private let state = CursorCompanionState()
    private var timer: Timer?
    private var position: CGPoint?
    private var lastPointer: CGPoint?
    private var lastMove = Date()
    private var shown = false
    private var animates = true

    var isRunning: Bool { timer != nil }

    func start(animates: Bool) {
        let changed = self.animates != animates
        self.animates = animates
        guard timer == nil else { if changed { panel?.contentView = host() }; return }
        let panel = CursorCompanionPanel(contentRect: NSRect(x: 0, y: 0, width: CursorCompanionLayout.size, height: CursorCompanionLayout.size),
                                         styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.ignoresMouseEvents = true; panel.isReleasedWhenClosed = false
        panel.level = .statusBar; panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .transient]
        panel.alphaValue = 0
        self.panel = panel
        panel.contentView = host()
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in MainActor.assumeIsolated { self?.tick() } }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        lastMove = Date()
    }

    func stop() {
        timer?.invalidate(); timer = nil
        panel?.orderOut(nil); panel = nil
        position = nil; lastPointer = nil; shown = false
    }

    private func host() -> NSView {
        let view = NSHostingView(rootView: CursorSparkleView(state: state, animates: animates))
        view.frame = NSRect(x: 0, y: 0, width: CursorCompanionLayout.size, height: CursorCompanionLayout.size)
        return view
    }

    private func tick() {
        guard let panel else { return }
        let pointer = NSEvent.mouseLocation, now = Date()
        if pointer != lastPointer { lastPointer = pointer; lastMove = now }
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(pointer) })?.frame else { return }
        let busy = phase() != .inactive
        if state.busy != busy { state.busy = busy }
        let resting = !busy && now.timeIntervalSince(lastMove) > CursorCompanionLayout.sleepAfter
        if state.resting != resting { state.resting = resting }
        let target = CursorCompanionLayout.origin(pointer: pointer, screen: screen).origin
        // A jump between screens, or no motion allowed, places it at once.
        let next: CGPoint
        if let position, animates, screen.contains(position) { next = CursorCompanionLayout.follow(position, toward: target) }
        else { next = target }
        if position.map({ abs($0.x - next.x) > 0.25 || abs($0.y - next.y) > 0.25 }) ?? true {
            position = next
            panel.setFrameOrigin(next)
        }
        let visible = !CursorCompanionLayout.hidesNearIsland(pointer: pointer, screen: screen)
        if visible != shown {
            shown = visible
            if visible { panel.orderFrontRegardless() }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                panel.animator().alphaValue = visible ? 1 : 0
            }
        }
    }
}
