import AppKit
import SwiftUI

@MainActor private final class ReviewVoice: VoiceCapturing {
    func prepareAccess() async throws { throw VoiceCaptureFailure.unavailable }
    func start(language: String, receive: @escaping @MainActor (VoiceCaptureEvent) -> Void) throws { throw VoiceCaptureFailure.unavailable }
    func finish() {}
    func cancel() {}
}
private actor ReviewStore: LocalChatStoring {
    var items: [LocalChatConversation]
    init() {
        items = [
            .init(persona: .sig, title: "Organizar as ideias do projeto", messages: [.init(role: .assistant, text: "Começamos pelo que importa hoje. O próximo passo ficou salvo para você retomar.")]),
            .init(persona: .ada, title: "Uma função em Swift, passo a passo", messages: [.init(role: .assistant, text: "A função recebe os argumentos e devolve um resultado. Aqui está o exemplo que estávamos explorando.")]),
            .init(persona: .rita, title: "Uma pausa entre duas tarefas", messages: [.init(role: .assistant, text: "Um intervalo curto antes da próxima tarefa. Retome no seu ritmo.")])
        ]
    }
    func load() -> [LocalChatConversation] { items }
    func save(_ conversations: [LocalChatConversation]) { items = conversations }
}
@MainActor private final class ReviewDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    let suite: String
    init(suite:String) { self.suite=suite }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication)->Bool { true }
    func applicationWillTerminate(_ notification: Notification) { UserDefaults.standard.removePersistentDomain(forName:suite) }
}
private struct ReviewChrome<Content: View>: View {
    @ObservedObject var preferences: CompanionPreferences
    let content: Content
    var island: (Int) -> Void = { _ in }
    var body: some View {
        VStack(spacing:0) {
            content
            Divider()
            HStack {
                Text("Prévia de design · dados de exemplo · áudio e microfone desativados").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Menu("Ilha") {
                    Button("Ilha aberta (companheiro)") { island(1) }
                    Button("Ilha aberta com aviso da Rita") { island(3) }
                    Button("Ilha fechada") { island(2) }
                    Button("Widget da barra de menus") { island(4) }
                    Divider()
                    Button("Esconder ilha") { island(0) }
                }.fixedSize()
                Toggle("Reduzir movimento",isOn:$preferences.reduceMotion).toggleStyle(.checkbox)
                Picker("Tema",selection:$preferences.appearance) {
                    Text("Claro").tag(AppAppearance.light);Text("Escuro").tag(AppAppearance.dark)
                }.pickerStyle(.segmented).labelsHidden().fixedSize().accessibilityLabel("Tema")
            }.padding(10)
        }.preferredColorScheme(preferences.appearance.colorScheme)
    }
}
@main enum WorkspaceReview {
    @MainActor static func main() throws {
        let app=NSApplication.shared
        let exporting=CommandLine.arguments.contains("--render-states") || CommandLine.arguments.contains("--render-onboarding")
        app.setActivationPolicy(exporting ? .prohibited : .regular)
        let suite="com.sieghart.workspace-review."+UUID().uuidString
        let defaults=UserDefaults(suiteName:suite)!
        let preferences=CompanionPreferences(defaults:defaults)
        preferences.onboardingComplete=true;preferences.characterMotion=true
        preferences.introductionLanguage = .portuguese
        preferences.appearance = .dark;preferences.windowGlass=true;preferences.impactsEnabled=false
        let assistant=AssistantViewModel(defaults:defaults,schedulesTimer:false)
        let audio=AudioViewModel(backend:CatalogAudio(),defaults:defaults)
        let monitor=SystemMonitorViewModel(backend:CatalogSystem())
        let awake=KeepAwakeViewModel(backend:CatalogAwake(),defaults:defaults)
        let display=DisplayPowerViewModel(backend:CatalogDisplay(),defaults:defaults)
        let chat=LocalChatViewModel(generator:UnavailableLocalChatEngine(),store:ReviewStore())
        var ready=false
        Task { await chat.prepare(); ready=true }
        let deadline=Date().addingTimeInterval(15)
        while !ready && Date() < deadline { RunLoop.current.run(until:Date().addingTimeInterval(0.01)) }
        precondition(ready, "Fixture conversations did not load")
        let room=AgentRoomViewModel(services:[:],defaults:defaults,localChat:chat)
        let notch=NotchWidgetViewModel(assistant:assistant,preferences:preferences,audio:audio,monitor:monitor,keepAwake:awake,displayPower:display,calendar:IsolatedCalendarFixture.make(defaults:defaults),agentRoom:room,managesWindows:false)
        let activation=ActivationController(assistant:assistant,notch:notch,defaults:defaults,registersShortcuts:false,voiceCapture:ReviewVoice());activation.voiceLanguage="pt-BR"
        let sensor=SensorViewModel(reader:CatalogSensor()),gestures=ImpactGestureCoordinator(assistant:assistant,notch:notch)
        let codex=CodexUsageViewModel(defaults:defaults,load:{throw CocoaError(.fileReadNoSuchFile)})
        let usage=AIUsageViewModel(defaults:defaults,readClaude:{nil},readAntigravity:{nil},read:{_ in nil})
        func root(scrollable:Bool)->some View {
            ContentView(scrollable:scrollable)
                .environmentObject(assistant).environmentObject(notch).environmentObject(preferences)
                .environmentObject(activation).environmentObject(sensor).environmentObject(gestures)
                .environmentObject(codex).environmentObject(usage).environmentObject(audio)
        }
        if CommandLine.arguments.contains("--render-tools") {
            let out=URL(fileURLWithPath:CommandLine.arguments.last!,isDirectory:true)
            try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
            preferences.appearance = .dark
            for section in AppSection.tools {
                let window=NSWindow(contentRect:NSRect(x:0,y:0,width:1180,height:1100),styleMask:[.borderless],backing:.buffered,defer:false)
                window.appearance=NSAppearance(named:.darkAqua)
                let host=NSHostingView(rootView:ContentView(initialSection:section,scrollable:false)
                    .environmentObject(assistant).environmentObject(notch).environmentObject(preferences)
                    .environmentObject(activation).environmentObject(sensor).environmentObject(gestures)
                    .environmentObject(codex).environmentObject(usage).environmentObject(audio)
                    .environment(\.locale,Locale(identifier:"pt-BR")).frame(width:1180,height:1100,alignment:.top))
                host.frame=NSRect(x:0,y:0,width:1180,height:1100); window.contentView=host
                window.orderFrontRegardless(); host.layoutSubtreeIfNeeded()
                RunLoop.current.run(until:Date().addingTimeInterval(1.5))
                let rep=host.bitmapImageRepForCachingDisplay(in:host.bounds)!
                host.cacheDisplay(in:host.bounds,to:rep); window.orderOut(nil)
                try rep.representation(using:.png,properties:[:])!.write(to:out.appendingPathComponent("\(section.rawValue).png"))
                print("PASS: \(section.rawValue)")
            }
            defaults.removePersistentDomain(forName:suite)
        } else if CommandLine.arguments.contains("--render-surfaces") {
            // Live AppKit-hosted snapshots (ImageRenderer cannot draw native controls).
            let out=URL(fileURLWithPath:CommandLine.arguments.last!,isDirectory:true)
            try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
            func shot<V: View>(_ view:V,_ size:NSSize,_ name:String) throws {
                for theme in [AppAppearance.light,.dark] {
                    preferences.appearance=theme
                    let window=NSWindow(contentRect:NSRect(origin:.zero,size:size),styleMask:[.borderless],backing:.buffered,defer:false)
                    window.appearance=NSAppearance(named:theme == .dark ? .darkAqua : .aqua)
                    let host=NSHostingView(rootView:view
                        .environmentObject(assistant).environmentObject(notch).environmentObject(preferences)
                        .environmentObject(activation).environmentObject(sensor).environmentObject(gestures)
                        .environmentObject(codex).environmentObject(usage).environmentObject(audio)
                        .environment(\.locale,Locale(identifier:"pt-BR")).frame(width:size.width,height:size.height))
                    host.frame=NSRect(origin:.zero,size:size); window.contentView=host
                    window.orderFrontRegardless(); host.layoutSubtreeIfNeeded()
                    RunLoop.current.run(until:Date().addingTimeInterval(2))
                    let rep=host.bitmapImageRepForCachingDisplay(in:host.bounds)!
                    host.cacheDisplay(in:host.bounds,to:rep); window.orderOut(nil)
                    try rep.representation(using:.png,properties:[:])!.write(to:out.appendingPathComponent("\(name)-\(theme.rawValue).png"))
                    print("PASS: \(name) \(theme.rawValue)")
                }
            }
            for step in 0..<4 {
                try shot(CompanionOnboardingView(scrollable:false,initialStep:step,arrivalPreviewTime:30).environment(\.islandPreview,true),NSSize(width:900,height:720),"onboarding-\(step)")
            }
            try shot(MenuBarView().background(Color(nsColor:.windowBackgroundColor)),NSSize(width:340,height:300),"popover")
            notch.keepAwake.request.mode = .duration; notch.keepAwake.request.minutes = 60
            try shot(KeepAwakeRunningRow(controller:notch.keepAwake).padding(16).background(Color(nsColor:.windowBackgroundColor)),NSSize(width:340,height:180),"keepawake-idle-row")
            try shot(ContentView(initialSection:.settings,scrollable:true),NSSize(width:1180,height:900),"settings")
            try shot(ContentView(initialSection:.team,scrollable:true),NSSize(width:1180,height:760),"team")
            try shot(ContentView(initialSection:.files,scrollable:true),NSSize(width:1180,height:760),"library")
            if let first = chat.conversations.first { chat.select(first.id) }
            room.page = .chat
            try shot(ContentView(initialSection:.agentRoom,scrollable:true),NSSize(width:1180,height:760),"chat")
            notch.ritaNudges.preview(minutes:52)
            try shot(ContentView(initialSection:.overview,scrollable:true),NSSize(width:1180,height:1000),"today")
            notch.show()
            try shot(NotchWidgetView(scrollable:false).environment(\.islandPreview,true),NSSize(width:notch.geometry.width+144,height:notch.geometry.height+64),"island-home")
            notch.showIsland()
            try shot(NotchWidgetView(scrollable:false).environment(\.islandPreview,true),NSSize(width:notch.geometry.width+40,height:notch.geometry.height+10),"island-compact")
            defaults.removePersistentDomain(forName:suite)
        } else if CommandLine.arguments.contains("--render-onboarding") {
            try OnboardingSurfaceQA.render(to: URL(fileURLWithPath:CommandLine.arguments.last!,isDirectory:true))
        } else if exporting {
            let out=URL(fileURLWithPath:CommandLine.arguments.last!,isDirectory:true)
            try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
            for theme in [AppAppearance.light,.dark] {
                preferences.appearance=theme
                for width in [840.0,1180,1480] {
                    let view=root(scrollable:false).frame(width:width).fixedSize(horizontal:false,vertical:true)
                        .environment(\.islandPreview,true).environment(\.colorScheme,theme == .dark ? .dark : .light)
                    let renderer=ImageRenderer(content:view);renderer.scale=2
                    let image=renderer.cgImage!
                    try NSBitmapImageRep(cgImage:image).representation(using:.png,properties:[:])!.write(to:out.appendingPathComponent("\(theme.rawValue)-\(Int(width)).png"))
                    print("PASS: \(theme.rawValue) \(width), \(image.width)×\(image.height)")
                }
            }
            defaults.removePersistentDomain(forName:suite)
        } else {
            let delegate=ReviewDelegate(suite:suite);app.delegate=delegate
            let window=NSWindow(contentRect:NSRect(x:0,y:0,width:1180,height:840),styleMask:[.titled,.closable,.miniaturizable,.resizable],backing:.buffered,defer:false)
            window.title="HeyChomp · Início e navegação";window.isReleasedWhenClosed=false
            window.toolbarStyle = .unifiedCompact;window.contentMinSize=NSSize(width:840,height:700)
            // Island preview: a real panel at the top of the screen with the live island view.
            var islandPanel: NSPanel?
            func presentIsland(_ mode:Int) {
                islandPanel?.orderOut(nil)
                guard mode != 0 else { return }
                if mode == 4 {
                    let screen = NSScreen.main ?? NSScreen.screens[0]
                    let size = NSSize(width: 340, height: 330)
                    let panel = NSPanel(contentRect: NSRect(x: screen.visibleFrame.maxX - size.width - 120, y: screen.visibleFrame.maxY - size.height - 6, width: size.width, height: size.height),
                                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
                    panel.level = .statusBar; panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
                    panel.contentView = NSHostingView(rootView: MenuBarView()
                        .environmentObject(assistant).environmentObject(notch).environmentObject(preferences)
                        .environmentObject(activation).environmentObject(usage).environmentObject(codex).environmentObject(audio)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)))
                    panel.orderFrontRegardless(); islandPanel = panel
                    return
                }
                if mode == 3 { notch.ritaNudges.preview(minutes:52) } else if mode == 1 { notch.ritaNudges.standUp() }
                if mode == 2 { notch.showIsland() } else { notch.show() }
                let compact = mode == 2
                let size = NSSize(width: notch.geometry.width + (compact ? 0 : 144), height: notch.geometry.height + (compact ? 0 : 64))
                let screen = NSScreen.main ?? NSScreen.screens[0]
                let panel = NSPanel(contentRect: NSRect(x: screen.frame.midX - size.width / 2, y: screen.frame.maxY - size.height, width: size.width, height: size.height),
                                    styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
                panel.level = .statusBar; panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
                panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                panel.contentView = NSHostingView(rootView: NotchWidgetView(scrollable: false)
                    .environmentObject(assistant).environmentObject(notch).environmentObject(preferences)
                    .environmentObject(activation).environmentObject(usage).environmentObject(codex)
                    .environmentObject(sensor).environmentObject(gestures).environmentObject(audio)
                    .frame(width: size.width, height: size.height, alignment: .top))
                panel.orderFrontRegardless()
                islandPanel = panel
            }
            window.contentView=NSHostingView(rootView:ReviewChrome(preferences:preferences,content:root(scrollable:true),island:presentIsland))
            delegate.window=window;window.center();window.makeKeyAndOrderFront(nil);app.activate()
            run(app)
            withExtendedLifetime(delegate){}
        }
    }
    @MainActor static func run(_ app:NSApplication) { app.run() }
}
