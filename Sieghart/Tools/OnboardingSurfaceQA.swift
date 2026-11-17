import AppKit
import Metal
import SceneKit

/// Exercise the new artwork, rather than the hostless tests' legacy fallback.
@MainActor enum OnboardingSurfaceQA {
    static func render(to output: URL) throws {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let team = CompanionTeamScene.Coordinator()
        precondition(([team.greeting.model] + team.agents).allSatisfy(\.usesIllustration), "Onboarding requires production artwork")
        precondition(team.greeting.handL.geometry is SCNPlane && team.greeting.handR.geometry is SCNPlane, "Opening must use the painted hands")
        let size = CGSize(width: 640, height: 360)
        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        renderer.scene = team.greeting.scene; renderer.pointOfView = team.camera
        renderer.autoenablesDefaultLighting = false
        for time in [0.0, 0.35, 0.6, 0.73, 1.4, 1.9, 2.2, 2.7, 3.3, 4.4] {
            team.update(time: time, animates: true, size: size)
            let reference = rigGreetPose(time, compact: CompanionGreetingLayout())
            precondition(abs(Double(team.greeting.halo.scale.x) - reference.hb * rigGASP * 4.2) < 0.001)
            precondition(team.agents.allSatisfy { $0.root.isHidden })
        }
        team.update(time: 0.35, animates: true, size: size)
        precondition(team.greeting.warps.contains { $0.opacity > 0 }, "Fall streaks missing")
        team.update(time: 0.8, animates: true, size: size)
        precondition(team.greeting.ring.contains { $0.opacity > 0 }, "Landing ring missing")
        team.update(time: 1.9, animates: true, size: size)
        precondition(team.greeting.handL.opacity > 0 && team.greeting.handR.opacity > 0, "Greeting wave missing")
        let stages = [0.35, 0.6, 1.9, 3.7, 6.0, 8.5, 11, 14.2, 17.2, 20.2, 23.2, 26.2, 30.9]
        for (theme, background) in [("claro", NSColor(calibratedWhite: 0.96, alpha: 1)), ("escuro", NSColor(calibratedWhite: 0.07, alpha: 1))] {
            team.greeting.scene.background.contents = background
            for (index, time) in stages.enumerated() {
                team.update(time: time, animates: true, size: size)
                try save(renderer.snapshot(atTime: time, with: size, antialiasingMode: .multisampling4X), to: output.appendingPathComponent("\(theme)-\(index).png"))
            }
        }
        let frames = output.appendingPathComponent("frames", isDirectory: true)
        try FileManager.default.createDirectory(at: frames, withIntermediateDirectories: true)
        team.greeting.scene.background.contents = NSColor(calibratedWhite: 0.07, alpha: 1)
        for frame in 0...372 {
            let time = Double(frame) / 12
            team.update(time: time, animates: true, size: size)
            try save(renderer.snapshot(atTime: time, with: size, antialiasingMode: .multisampling4X), to: frames.appendingPathComponent(String(format: "%03d.png", frame)))
        }
        // Replay must reset the assembled team and restore the landing effect.
        team.update(time: 0.8, animates: true, size: size)
        precondition(team.agents.allSatisfy { $0.root.isHidden })
        precondition(team.greeting.ring.contains { !$0.isHidden && $0.opacity > 0 })
        team.update(time: 0, animates: false, size: size)
        precondition(team.agents.allSatisfy { !$0.root.isHidden && $0.root.opacity == 1 })
        let record: [String: Any] = ["productionArtwork": true, "originalOpeningRestored": true, "paintedHands": true, "replay": true, "reduceMotion": true, "sequenceSeconds": 31, "frames": 373, "exportFPS": 12, "measuredLiveFPS": false]
        try JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("verification.json"))
        print("PASS: original opening with production artwork; painted hands; replay; Reduce Motion; 373 frames")
    }
    private static func save(_ image: NSImage, to url: URL) throws {
        let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        try NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!.write(to: url)
    }
}
