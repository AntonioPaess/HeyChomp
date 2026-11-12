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
    var body: some View {
        VStack(spacing:0) {
            content
            Divider()
            HStack {
                Text("Prévia de design · dados de exemplo · áudio e microfone desativados").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Toggle("Reduzir movimento",isOn:$preferences.reduceMotion).toggleStyle(.checkbox)
                Picker("Tema",selection:$preferences.appearance) {
                    Text("Claro").tag(AppAppearance.light);Text("Escuro").tag(AppAppearance.dark)
                }.pickerStyle(.segmented).frame(width:140)
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
        if CommandLine.arguments.contains("--render-onboarding") {
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
            window.contentView=NSHostingView(rootView:ReviewChrome(preferences:preferences,content:root(scrollable:true)))
            delegate.window=window;window.center();window.makeKeyAndOrderFront(nil);app.activate()
            run(app)
            withExtendedLifetime(delegate){}
        }
    }
    @MainActor static func run(_ app:NSApplication) { app.run() }
}
