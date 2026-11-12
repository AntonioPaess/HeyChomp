import AppKit
@preconcurrency import SceneKit
import SwiftUI
import Testing

extension MacContractsTests {
    @MainActor @Suite(.tags(.isolated, .companions)) struct CompanionPreferenceTests {
        @Test("G05.01 · Legacy Team rail becomes Companion and English is the initial introduction")
        func legacyRail() throws {
            let store = try TestDefaults(); defer { store.cleanup() }
            store.value.set(["All tools", "Avatars", "Clipboard", "Preferences", "Speak", "Audio"], forKey: "island.rails")
            let prefs = CompanionPreferences(defaults: store.value)
            #expect(prefs.avatar == .sig && prefs.railActions[1] == .companion && prefs.railActions[2] == .clipboard)
            #expect(prefs.introductionLanguage == .english)
            prefs.introductionLanguage = .portuguese
            #expect(CompanionPreferences(defaults: store.value).introductionLanguage == .portuguese)
        }
    }

    @MainActor @Suite(.tags(.companions, .nativeView)) struct CompanionSceneTests {
        @Test("G05.03 · File intake respects aperture, depth, final disappearance and held-open hover", arguments: CompanionAvatar.allCases)
        func intakeScene(_ member: CompanionAvatar) {
            let coordinator = CompanionScene.Coordinator(member), actor = coordinator.actor
            actor.update(id: CompanionAnimation.fileReceive.rawValue, t: 0.16, duration: 1.3, global: 0.16)
            #expect(actor.slot.position.y <= actor.bounds.maxY - 5)
            let earlyDepth = actor.file.position.z
            actor.update(id: CompanionAnimation.fileReceive.rawValue, t: 0.37, duration: 1.3, global: 0.37)
            #expect(actor.file.position.z < earlyDepth)
            actor.update(id: CompanionAnimation.fileReceive.rawValue, t: 1.3, duration: 1.3, global: 1.3)
            #expect(actor.file.opacity == 0 && actor.slot.opacity == 0 && actor.model.marker?.opacity == 0)
            coordinator.update(CompanionScene(avatar: member, animation: .fileOpen, time: 0, animates: true, gaze: nil, replay: 0))
            coordinator.update(CompanionScene(avatar: member, animation: .fileOpen, time: 2, animates: true, gaze: nil, replay: 0))
            #expect(actor.slot.opacity > 0.9 && actor.file.opacity == 0)
            #expect(actor.halo.renderingOrder < 0 && actor.halo.geometry?.firstMaterial?.readsFromDepthBuffer == false)
        }

        @Test("Ada faces the notebook, reaches its keys and settles after the result")
        func adaNotebookResult() throws {
            let actor = CompanionRigActor(.ada, 2)
            let notebook = try #require(actor.model.notebook)
            let lid = try #require(actor.model.notebookLid)
            let completion = CompanionAnimation.completed
            func update(_ time: Double, animates: Bool = true) {
                actor.update(id: completion.rawValue, t: time, duration: completion.duration,
                             global: 0, animates: animates)
            }

            update(1.02)
            let displayNormal = lid.convertVector(SCNVector3(0, 0, 1), to: actor.model.root)
            #expect(displayNormal.x < -0.5 && displayNormal.z < -0.15)
            #expect(actor.lastPose.yaw > 0.4 && actor.lastPose.gaze.height > 3)
            for hand in actor.hands {
                let contact = notebook.convertPosition(hand.position, from: actor.model.head)
                #expect(abs(contact.x) < 13 && contact.z > 3 && contact.z < 13)
                #expect(contact.y > 1 && contact.y < 5)
                #expect(hand.opacity > 0.95)
            }

            update(2.6)
            #expect(abs(actor.lastPose.yaw) < 0.15)
            #expect(actor.hands.allSatisfy { $0.opacity == 0 })
            update(1.02, animates: false)
            #expect(actor.lastPose.yaw == 0 && actor.lastPose.gaze == .zero)
            #expect(actor.hands.allSatisfy { $0.opacity == 0 })
        }

        @Test("G05.04 · Loading advances its contour on persistent meshes and cancels continuously", arguments: CompanionAvatar.allCases)
        func loadingContinuity(_ member: CompanionAvatar) throws {
            let coordinator = CompanionScene.Coordinator(member)
            func render(_ animation: CompanionAnimation, _ time: Double) {
                coordinator.update(CompanionScene(avatar: member, animation: animation, time: time, animates: true, gaze: nil, replay: 0))
            }
            render(.idle, 100); render(.idle, 101)
            #expect(coordinator.actor.model.marker?.opacity == 0)
            render(.thinking, 101); render(.thinking, 101.6)
            let before = coordinator.actor.lastPose
            #expect(before.loading > 0.9)
            let badge = try #require(coordinator.actor.model.marker)
            let progress = try #require(coordinator.actor.model.loadingProgress)
            let badgeMeshes = try badge.childNodes.map { ObjectIdentifier(try #require($0.geometry)) }
            let phase = try #require(progress.value(forKey: "phase") as? Float)
            render(.thinking, 101.8)
            #expect(badge.eulerAngles.z == 0 && badge.scale.x == 1)
            #expect((progress.value(forKey: "phase") as? Float) != phase)
            let laterMeshes = try badge.childNodes.map { ObjectIdentifier(try #require($0.geometry)) }
            #expect(laterMeshes == badgeMeshes)
            render(.thinking, 101.6); render(.idle, 101.6)
            #expect(coordinator.actor.lastPose.loading == before.loading)
            #expect(coordinator.actor.lastPose.gaze == before.gaze)
            render(.idle, 101.9)
            #expect(coordinator.actor.model.marker?.opacity == 0)
        }

        @Test("G05.04 · Sleep breathes, Reduce Motion freezes, gaze has no second cursor and eyes reuse geometry", arguments: CompanionAvatar.allCases)
        func sleepGazeAndEyes(_ member: CompanionAvatar) {
            let coordinator = CompanionScene.Coordinator(member)
            func render(_ animation: CompanionAnimation, _ time: Double, animates: Bool = true, gaze: CGSize? = nil) {
                coordinator.update(CompanionScene(avatar: member, animation: animation, time: time, animates: animates, gaze: gaze, replay: 0))
            }
            render(.sleeping, 102); render(.sleeping, 102.4)
            let sleeping = coordinator.actor.lastPose
            render(.sleeping, 103.7)
            #expect(sleeping.sy != coordinator.actor.lastPose.sy)
            #expect(coordinator.actor.lastPose.open < 0.06)
            render(.sleeping, 104, animates: false)
            let still = coordinator.actor.lastPose
            render(.sleeping, 108, animates: false)
            #expect(still.sy == coordinator.actor.lastPose.sy && still.open == coordinator.actor.lastPose.open)
            render(.cursor, 109)
            render(.cursor, 110, gaze: CGSize(width: -4, height: 0))
            #expect(coordinator.actor.lastPose.gaze.width == -4 && coordinator.actor.cursor.opacity == 0)
            render(.cursor, 110.1, gaze: CGSize(width: 4, height: 0))
            #expect(coordinator.actor.lastPose.gaze.width == 4 && coordinator.actor.cursor.opacity == 0)
            let rig = coordinator.actor.model
            rig.updateEyes(open: 1, joy: 0, gaze: .zero, wink: 0, anger: 0)
            let meshes = rig.eyeCache.count
            for i in 0..<360 {
                rig.updateEyes(open: Double(i % 61) / 60, joy: 0, gaze: CGSize(width: sin(Double(i)), height: 0), wink: Double(i % 41) / 40, anger: 0)
            }
            #expect(rig.eyeCache.count == meshes)
        }
    }

    @MainActor @Suite(.tags(.companions, .nativeView)) struct CompanionRigTests {
        @Test("Surface water grows, slides and disappears before each path restarts")
        func surfaceWaterContinuity() {
            for hot in [false,true] {
                for index in 0..<6 {
                    var previous=WeatherSurfaceMotion.drop(index:index,time:0,hot:hot,intensity:0.8)
                    for frame in 1...3600 {
                        let p=WeatherSurfaceMotion.drop(index:index,time:Double(frame)/120,hot:hot,intensity:0.8)
                        let finite=[p.x,p.y,p.size,p.stretch,p.opacity].allSatisfy { $0.isFinite }
                        #expect(finite)
                        if p.opacity>0.05 && previous.opacity>0.05 {
                            #expect(abs(p.y-previous.y)<1 && abs(p.x-previous.x)<1)
                        }
                        previous=p
                    }
                }
            }
            #expect(WeatherSurfaceMotion.snowLevel(time:0)==0)
            #expect(WeatherSurfaceMotion.snowLevel(time:12)>WeatherSurfaceMotion.snowLevel(time:3))
            let mild=CompanionWeatherIntensity(mood:.frozen,temperature:-2)
            let severe=CompanionWeatherIntensity(mood:.frozen,temperature:-16)
            #expect(WeatherSurfaceMotion.freezeDuration(severe)<WeatherSurfaceMotion.freezeDuration(mild))
        }
        @Test("Weather reactions retain temperature-dependent intensity and purposeful hand gestures")
        func weatherTemperatureGestures() {
            let mild=CompanionWeatherIntensity(mood:.cold,temperature:14)
            let severe=CompanionWeatherIntensity(mood:.frozen,temperature:-16)
            #expect(severe.cold>mild.cold)
            let cold=WeatherCharacterPose.sample(.cold,time:1.4,intensity:mild)
            let frozen=WeatherCharacterPose.sample(.frozen,time:1.4,intensity:severe)
            #expect(abs(frozen.x)>abs(cold.x))
            #expect(frozen.sy<cold.sy)
            #expect(frozen.hands==1 && cold.hands==1)
            let warm=WeatherCharacterPose.sample(.hot,time:1.4,intensity:.init(mood:.hot,temperature:29))
            let hot=WeatherCharacterPose.sample(.hot,time:1.4,intensity:.init(mood:.hot,temperature:42))
            #expect(hot.sy<warm.sy && hot.open<warm.open)
            let fanA=WeatherCharacterPose.sample(.hot,time:2)
            let fanB=WeatherCharacterPose.sample(.hot,time:2.2)
            #expect(abs(fanA.handRRoll-fanB.handRRoll)>0.1)
            #expect(WeatherCharacterPose.sample(.rain,time:1).handLY>8)
            #expect(WeatherCharacterPose.sample(.hail,time:1.5).handRY>17)
            #expect(WeatherCharacterPose.sample(.snow,time:3.9).handRY > -10)
        }
        @Test("Thunder anticipates the reaction and leaves a quiet recovery between impacts")
        func weatherSharedTiming() {
            let before=WeatherCharacterPose.sample(.storm,time:2.0)
            let flash=WeatherChoreography.sample(time:2.65)
            let recoil=WeatherCharacterPose.sample(.storm,time:2.65)
            let settled=WeatherCharacterPose.sample(.storm,time:6.5)
            #expect(flash.flash>0.5)
            #expect(recoil.sy<before.sy && recoil.open<before.open)
            #expect(settled.open>recoil.open && WeatherChoreography.sample(time:6.5).flash==0)
            #expect(WeatherChoreography.sample(time:11.99).startle==0)
        }
        @Test("Weather card clock pauses without catch-up and restarts each condition")
        func weatherClockContinuity() {
            var clock=WeatherPanelClock()
            #expect(clock.time(at:Date.distantFuture)==0)
            clock.restart(playing:true)
            clock.setPlaying(false)
            let a=clock.time(at:Date())
            #expect(a==clock.time(at:Date.distantFuture))
            clock.restart(playing:false)
            #expect(clock.time(at:Date.distantFuture)==0)
        }
        @Test("Every weather gesture remains continuous across its loop")
        func weatherLoopContinuity() {
            var failures:[String]=[]
            for mood in CompanionWeatherMood.allCases {
                var previous=WeatherCharacterPose.sample(mood,time:0)
                for frame in 1...1800 {
                    let t=Double(frame)/120,p=WeatherCharacterPose.sample(mood,time:t)
                    let values=[p.x,p.y,p.sx,p.sy,p.open,p.roll,p.handRX,p.handRY,p.handRRoll]
                    if !values.allSatisfy(\.isFinite) || p.open<0.06 || abs(p.x-previous.x)>1 || abs(p.handRY-previous.handRY)>2 || abs(p.handRRoll-previous.handRRoll)>0.2 {
                        failures.append("\(mood) at \(t)"); break
                    }
                    previous=p
                }
            }
            #expect(failures.isEmpty,"\(failures)")
        }
        @Test("Painted motion preserves silhouettes and stays continuous at every loop", arguments: CompanionAvatar.allCases)
        func paintedMotionContinuity(_ member: CompanionAvatar) {
            var invalid:[String]=[]
            for animation in CompanionAnimation.allCases {
                var previous=CompanionPaintedMotion.sample(member,id:animation.rawValue,time:0,global:0)
                for frame in 1...1440 {
                    let t=Double(frame)/120
                    let p=CompanionPaintedMotion.sample(member,id:animation.rawValue,time:t,global:t)
                    let values=[p.x,p.y,p.sx,p.sy,p.roll,p.open,p.joy,p.opacity,p.fold]
                    if !values.allSatisfy(\.isFinite) || p.sx<0.85 || p.sx>1.08 || p.sy<0.85 || p.sy>1.08 || abs(p.roll)>0.12 || p.open<0.04 {
                        invalid.append("\(animation): bounds at \(t)"); break
                    }
                    // At 120 Hz a teleport, flipped plane or abrupt loop reset
                    // exceeds these limits; normal anticipation and blinking do not.
                    if abs(p.x-previous.x)>1 || abs(p.y-previous.y)>1 || abs(p.roll-previous.roll)>0.025 || abs(p.open-previous.open)>0.2 {
                        invalid.append("\(animation): discontinuity at \(t)"); break
                    }
                    previous=p
                }
            }
            #expect(invalid.isEmpty, "\(member): \(invalid)")
        }
        @Test("Reference faces retain two eyes, Rita lens bounds and Elinor closed curves")
        func paintedFaceLimits() {
            var invalid=false
            for member in [CompanionAvatar.rita,.elinor] {
                for animation in CompanionAnimation.allCases {
                    for frame in 0...180 {
                        let t=Double(frame)/60
                        let p=CompanionPaintedMotion.sample(member,id:animation.rawValue,time:t,global:t)
                        if member == .rita { invalid = invalid || p.gaze.width<0 || p.gaze.width>0.4 || abs(p.gaze.height)>0.51 }
                        else { invalid = invalid || p.wink != 0 || p.joy>0.18 }
                    }
                }
            }
            #expect(!invalid)
        }

        @Test("G05.05 · All 294 character/animation pairs retain finite, coherent scales", arguments: CompanionAvatar.allCases)
        func allAnimationPoses(_ member: CompanionAvatar) {
            let coordinator = CompanionScene.Coordinator(member)
            for animation in CompanionAnimation.allCases {
                for t in [0.0, 0.7, 1.8, animation.duration] {
                    coordinator.actor.update(id: animation.rawValue, t: t, duration: animation.duration, global: t, continuous: animation.continuous)
                    let p = coordinator.actor.lastPose
                    #expect([p.x, p.y, p.sx, p.sy, p.sz, p.roll, p.yaw, p.open, p.opacity, p.loading].allSatisfy { $0.isFinite }, "\(member) / \(animation) / \(t)")
                    #expect(p.opacity <= 0 ? (p.sx >= 0 && p.sy >= 0) : (p.sx > 0 && p.sy > 0), "\(member) / \(animation) / \(t)")
                    if member == .ada || member == .gantt { #expect(abs(p.sx - p.sy) < 0.00001, "\(member) / \(animation) / \(t)") }
                }
            }
        }
    }

    @MainActor @Suite(.tags(.companions, .nativeView)) struct TeamSceneTests {
        @Test("G05.06 · Approved full fall/greeting/light precedes specialist emergence") func approvedOpening() throws {
            let layout = CompanionHomeLayout(), team = CompanionTeamScene.Coordinator()
            team.update(time: 2.2, animates: true)
            #expect(team.agents.allSatisfy { $0.root.isHidden })
            let reference = rigGreetPose(2.2, compact: CompanionGreetingLayout())
            let sigRoot = try #require(team.greeting.model.root.parent)
            #expect(abs(Double(sigRoot.scale.x) - Double(layout.size.width / 640)) < 0.00001)
            #expect(abs(Double(team.greeting.halo.scale.x) - reference.hb * rigGASP * 4.2) < 0.001)
            team.update(time: 4.4, animates: true)
            #expect(team.agents.allSatisfy { $0.root.isHidden })
            team.update(time: 6, animates: true)
            #expect(team.agents.allSatisfy { !$0.root.isHidden })
            team.update(time: 8.2, animates: true); team.update(time: 9.1, animates: true); team.update(time: 9.7, animates: true)
            #expect(team.greeting.halo.renderingOrder < team.greeting.model.head.renderingOrder)
            #expect(team.greeting.halo.geometry?.firstMaterial?.readsFromDepthBuffer == false)
            let color = try #require(team.greeting.halo.geometry?.firstMaterial?.multiply.contents as? NSColor)
            let blue = try #require(color.usingColorSpace(.sRGB))
            #expect(blue.blueComponent > blue.redComponent)
        }
        @Test("G05.07 · Settled dock avoids frame mutations") func stableDock() {
            let team = CompanionTeamScene.Coordinator(), layout = CompanionHomeLayout()
            team.update(time: CompanionTeamFormation.dockTime + 2, animates: true)
            for (index, agent) in team.agents.enumerated() {
                let target = layout.scene(layout.dock(index))
                #expect(abs(agent.root.position.x - target.x) < 0.001 && abs(agent.root.position.y - target.y) < 0.001)
            }
            let updates = team.agentPoseUpdates
            team.update(time: CompanionTeamFormation.dockTime + 2.3, animates: true)
            #expect(team.agentPoseUpdates == updates)
        }
        @Test("G05.07 · Spotlight advances each queue member, keeps Sig and five specialists visible", arguments: Array(0..<5))
        func spotlight(_ index: Int) throws {
            let layout = CompanionHomeLayout(), team = CompanionTeamScene.Coordinator()
            let member = CompanionAvatar.specialists[index]
            let time = CompanionTeamFormation.specialistStart + 0.7 + Double(index) * 3
            team.update(time: time, animates: true)
            #expect(CompanionTeamFormation.activeMember(at: time) == member)
            let hero = layout.scene(layout.hero)
            #expect(team.agents.filter { abs($0.root.position.x - hero.x) < 0.001 && abs($0.root.position.y - hero.y) < 0.001 }.count == 1)
            #expect(team.agents.filter { !$0.root.isHidden }.count == 5)
            let sigRoot = try #require(team.greeting.model.root.parent)
            #expect(!sigRoot.isHidden && sigRoot.opacity == 1)
            for (memberIndex, character) in CompanionAvatar.allCases.enumerated() {
                let root = memberIndex == 0 ? sigRoot : team.agents[memberIndex - 1].root
                let slot = CompanionTeamFormation.dockSlot(member: character, turn: index + 1)
                let expected = layout.scene(slot.map(layout.dock) ?? layout.hero)
                #expect(abs(root.position.x - expected.x) < 0.001 && abs(root.position.y - expected.y) < 0.001)
            }
        }
        @Test("G05.07 · Final rest and Reduce Motion show the full team") func reducedMotion() {
            let team = CompanionTeamScene.Coordinator(), layout = CompanionHomeLayout()
            for t in [0.0, 1.8, 5.4, 6.8, 10.3, 14, 20, 26, 30] { team.update(time: t, animates: true) }
            for (index, member) in team.agents.enumerated() {
                let target = layout.scene(layout.dock(index))
                #expect(abs(member.root.position.x - target.x) < 0.001 && abs(member.root.position.y - target.y) < 0.001)
                #expect(member.root.opacity == 1 && member.activity.isHidden)
            }
            team.update(time: 0, animates: false)
            #expect(team.agents.allSatisfy { $0.root.opacity == 1 && !$0.root.isHidden })
        }
    }

    @MainActor @Suite(.tags(.companions, .nativeView)) struct CompanionRasterLifecycleTests {
        @Test("G05.08 · Lifecycle timer survives window changes and releases detached or stopped views")
        func renderViewWindowLifecycle() async throws {
            let first = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 80, height: 80), styleMask: [.borderless], backing: .buffered, defer: false)
            let second = NSWindow(contentRect: first.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            first.isReleasedWhenClosed = false; second.isReleasedWhenClosed = false
            defer { first.close(); second.close() }
            var view: CompanionRenderView? = CompanionRenderView(frame: first.frame)
            weak var releasedView = view
            first.contentView = view
            view?.animationEnabled = true
            // Fire the real 2 Hz timer, then queue an old-window notification
            // before reparenting. That callback must not stop the new lifecycle.
            try await Task.sleep(for: .milliseconds(650))
            NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: first)
            first.contentView = NSView(frame: first.frame)
            second.contentView?.addSubview(try #require(view))
            try await Task.sleep(for: .milliseconds(650))
            #expect(view?.window === second && view?.animationEnabled == true)
            view?.stopRendering()
            #expect(view?.isPlaying == false && view?.rendersContinuously == false && view?.scene == nil)
            view?.removeFromSuperview()
            view = nil
            try await Task.sleep(for: .milliseconds(650))
            #expect(releasedView == nil)

            // Teardown also works without an explicit stopRendering() call.
            autoreleasepool {
                let transient = CompanionRenderView(frame: first.frame)
                releasedView = transient
                first.contentView?.addSubview(transient)
                transient.removeFromSuperview()
            }
            try await Task.sleep(for: .milliseconds(650))
            #expect(releasedView == nil)
        }

        @Test("G05.08 · Accessory is one mesh and detached views stop rendering/input") func detachedViews() {
            let circle = rigStroke(Path(ellipseIn: CGRect(x: 20, y: 20, width: 40, height: 40)), color: .white)
            #expect(circle.childNodes.isEmpty && circle.geometry != nil)
            let view = CompanionRenderView(frame: .zero); defer { view.stopRendering() }
            view.animationEnabled = true
            #expect(!view.isPlaying && !view.rendersContinuously)
            #expect(!view.acceptsFirstResponder && view.hitTest(.zero) == nil && view.acceptsFirstMouse(for: nil))
        }
        @Test("G05.08 · Full Retina source downsamples once to exact display backing size") func retinaRaster() throws {
            try CompanionArtwork.withIsolatedCaches {
                let portrait = CompanionPortraitView(frame: CGRect(x: 0, y: 0, width: 38, height: 38)); defer { portrait.stop() }
                let artwork = NSImage(size: CGSize(width: 512, height: 512))
                for pixels in [512, 1024] {
                    let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                        colorSpaceName: .deviceRGB, bytesPerRow: pixels * 4, bitsPerPixel: 32))
                    bitmap.size = artwork.size; artwork.addRepresentation(bitmap)
                }
                portrait.configure(image: artwork, animates: true); portrait.layout()
                let imageLayer = try #require(portrait.layer?.sublayers?.first)
                #expect(CompanionArtwork.fullResolutionPixels(in: artwork)?.width == 1024)
                let displayContents = try #require(imageLayer.contents)
                try #require(CFGetTypeID(displayContents as CFTypeRef) == CGImage.typeID)
                let display = displayContents as! CGImage // Type checked above; failure stays in this case.
                #expect(display.width == 76 && display.height == 76)
                portrait.layout()
                let sameContents = try #require(imageLayer.contents)
                try #require(CFGetTypeID(sameContents as CFTypeRef) == CGImage.typeID)
                let same = sameContents as! CGImage
                #expect(same === display)
                #expect(imageLayer.contentsScale == 2 && imageLayer.minificationFilter == .linear)
                #expect(imageLayer.animation(forKey: "breath") == nil)
            }
        }
    }

    @MainActor @Suite(.tags(.interactions, .nativeView)) struct CompanionMenuImageTests {
        @Test("G04.15 · Six menu images are 22-point non-template copies with isolated artwork", arguments: CompanionAvatar.allCases)
        func menuImage(_ member: CompanionAvatar) throws {
            try CompanionArtwork.withIsolatedCaches {
                let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 44, pixelsHigh: 44,
                    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                    colorSpaceName: .deviceRGB, bytesPerRow: 44 * 4, bitsPerPixel: 32))
                let artwork = NSImage(size: CGSize(width: 22, height: 22)); artwork.addRepresentation(bitmap)
                try #require(artwork.setName("Companion-\(member.rawValue)"))
                let image = try #require(CompanionArtwork.menuBarImage(for: member))
                #expect(image.size == NSSize(width: 22, height: 22) && !image.isTemplate)
                #expect(image !== artwork)
                #expect(CompanionArtwork.menuBarImage(for: member) === image)
            }
        }
    }
}
