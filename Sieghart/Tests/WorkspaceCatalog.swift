import AppKit
import CoreAudio
import SwiftUI

// Visual QA only. The resident app, hardware access, providers and voice flows
// are never started. Production views receive an isolated, empty workspace.
@main struct WorkspaceCatalog {
    @MainActor static func main() async throws {
        guard (3...4).contains(CommandLine.arguments.count),
              let bundle = Bundle(path: CommandLine.arguments[1]) else { throw CocoaError(.fileReadNoSuchFile) }
        let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        NSApplication.shared.setActivationPolicy(.prohibited)
        AIProviderResources.bundle = bundle
        if CommandLine.arguments.last == "artifacts" {
            try await artifactStates(output: output)
            return
        }
        if CommandLine.arguments.last == "chat-states" {
            try await chatStates(output: output)
            return
        }
        if CommandLine.arguments.last == "review" {
            let chatOutput = output.appendingPathComponent("chat", isDirectory: true)
            try FileManager.default.createDirectory(at: chatOutput, withIntermediateDirectories: true)
            try await chatStates(output: chatOutput)
        }
        let suite = "Sieghart.DesignCatalog.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = CompanionPreferences(defaults: defaults)
        preferences.onboardingComplete = true; preferences.characterMotion = false
        preferences.windowGlass = false; preferences.islandGlass = false
        let assistant = AssistantViewModel(defaults: defaults, schedulesTimer: false)
        let audio = AudioViewModel(backend: CatalogAudio(), defaults: defaults); audio.refresh()
        let monitor = SystemMonitorViewModel(backend: CatalogSystem()); monitor.refresh()
        let awake = KeepAwakeViewModel(backend: CatalogAwake(), defaults: defaults)
        let display = DisplayPowerViewModel(backend: CatalogDisplay(), defaults: defaults); display.refresh()
        let notch = NotchWidgetViewModel(assistant: assistant, preferences: preferences, audio: audio, monitor: monitor,
            keepAwake: awake, displayPower: display, calendar: IsolatedCalendarFixture.make(defaults: defaults), managesWindows: false)
        let activation = ActivationController(assistant: assistant, notch: notch, defaults: defaults, registersShortcuts: false)
        activation.voiceLanguage = "pt-BR"
        let sensor = SensorViewModel(reader: CatalogSensor()), gestures = ImpactGestureCoordinator(assistant: assistant, notch: notch)
        let codex = CodexUsageViewModel(defaults: defaults, load: { throw CocoaError(.fileReadNoSuchFile) })
        let usage = AIUsageViewModel(defaults: defaults, readClaude: { nil }, readAntigravity: { nil }, read: { _ in nil })
        var records: [[String: Any]] = []
        for theme in [AppAppearance.light, .dark] {
            preferences.appearance = theme
            let scheme: ColorScheme = theme == .light ? .light : .dark
            for section in AppSection.allCases where !["audio", "review"].contains(CommandLine.arguments.last ?? "") || section == .audio {
                let view = ContentView(initialSection: section, scrollable: false)
                    .frame(width: 1180).fixedSize(horizontal: false, vertical: true)
                    .environmentObject(sensor).environmentObject(assistant).environmentObject(notch)
                    .environmentObject(gestures).environmentObject(activation).environmentObject(preferences)
                    .environmentObject(codex).environmentObject(usage).environmentObject(audio)
                    .environment(\.islandPreview, true).environment(\.colorScheme, scheme)
                let renderer = ImageRenderer(content: view); renderer.scale = 2
                renderer.proposedSize = ProposedViewSize(width: 1180, height: nil)
                guard let image = renderer.cgImage,
                      let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
                let name = theme.rawValue.lowercased() + "-" + section.id.replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "’", with: "").lowercased() + ".png"
                try png.write(to: output.appendingPathComponent(name))
                records.append(["file": name, "section": section.id, "theme": theme.rawValue, "width": image.width, "height": image.height])
                print(name, image.width, image.height)
            }
        }
        let record: [String: Any] = ["language": "pt-BR", "sampleDataOnly": true, "hardwareAudio": false,
            "screenCapture": false, "residentLifecycle": false, "renders": records]
        try JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys])
            .write(to: output.appendingPathComponent("catalog.json"))
    }

    @MainActor private static func artifactStates(output: URL) async throws {
        var records: [[String: Any]] = []
        for language in ["pt-BR", "en-US"] {
            let en = language == "en-US"
            let reply = LocalChatMessage(role: .assistant, text: en ? "## A small next step\nUse a dictionary to find the missing value in one pass.\n```swift\nlet complement = target - value\n```" : "## Um próximo passo\nUse um dicionário para encontrar o complemento em uma passagem.\n```swift\nlet complemento = alvo - valor\n```")
            let conversation = LocalChatConversation(persona: .ada, title: "Two Sum · Swift", messages: [reply])
            let filled = CompanionArtifactLibrary()
            filled.saveReply(reply, in: conversation); filled.saveReply(reply, in: conversation, codeBlock: 0)
            filled.saveDocument(.init(name: en ? "Project notes.txt" : "Notas do projeto.txt", pages: [en ? "One task at a time." : "Uma tarefa de cada vez."], truncated: false))
            let chat = LocalChatViewModel(generator: CatalogChat(unavailable: false), store: CatalogChatStore(conversation: conversation, failsSave: false))
            chat.artifactLibrary = filled; await chat.prepare()
            for scheme in [ColorScheme.light, .dark] {
                for empty in [true, false] {
                    let shelf = CompanionArtifactShelf(library: empty ? CompanionArtifactLibrary() : filled, language: language)
                        .padding(28).frame(width: 920).fixedSize(horizontal: false, vertical: true)
                        .background(scheme == .dark ? Color(white: 0.065) : Color(white: 0.97))
                        .environment(\.islandPreview, true).environment(\.colorScheme, scheme).environment(\.locale, Locale(identifier: language))
                    let name = "\(language)-\(scheme == .dark ? "dark" : "light")-\(empty ? "empty" : "filled").png"
                    let renderer = ImageRenderer(content: shelf); renderer.scale = 2
                    guard let image = renderer.cgImage, let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
                    try png.write(to: output.appendingPathComponent(name))
                    records.append(["file": name, "width": image.width, "height": image.height]); print(name, image.width, image.height)
                }
                let view = LocalChatPrompt(chat: chat, conversation: conversation, compact: false, active: false)
                    .frame(width: 780, height: 500).environment(\.islandPreview, true).environment(\.islandReduceMotion, true)
                    .environment(\.colorScheme, scheme).environment(\.locale, Locale(identifier: language))
                let name = "\(language)-\(scheme == .dark ? "dark" : "light")-chat-save.png"
                let renderer = ImageRenderer(content: view); renderer.scale = 2
                guard let image = renderer.cgImage, let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
                try png.write(to: output.appendingPathComponent(name)); records.append(["file": name, "width": image.width, "height": image.height])
            }
            chat.shutdown()
        }
        let record: [String: Any] = ["sampleDataOnly": true, "hardwareAudio": false, "microphone": false, "screenCapture": false, "residentLifecycle": false, "renders": records]
        try JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("catalog.json"))
    }
    @MainActor private static func chatStates(output: URL) async throws {
        var records: [[String: Any]] = []
        let attachmentRoot = output.appendingPathComponent("temporary-documents", isDirectory: true)
        try FileManager.default.createDirectory(at: attachmentRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: attachmentRoot) }
        for language in ["pt-BR", "en-US"] {
            let en = language == "en-US"
            for unavailable in [false, true] {
                let question = en ? "Read my screen and explain this class." : "Leia minha tela e explique esta classe."
                let conversation = LocalChatConversation(persona: .sig, title: question, messages: [
                    .init(role: .user, text: question),
                    .init(role: .assistant, text: unavailable ? ScreenInspectionFailure.permission.message(english: en) : (en ? "The request was interrupted. You can continue from your draft." : "O pedido foi interrompido. Você pode continuar pelo rascunho."))
                ])
                let chat = LocalChatViewModel(generator: CatalogChat(unavailable: unavailable), store: CatalogChatStore(conversation: conversation, failsSave: unavailable))
                await chat.prepare()
                for name in ["A very long document name with notes about the project and its next steps.txt", "Another document with a long descriptive title and technical observations.txt"] {
                    let file = attachmentRoot.appendingPathComponent(name)
                    try "Catalog attachment only.".write(to: file, atomically: true, encoding: .utf8)
                    await chat.attach(file, to: conversation.id)
                }
                if unavailable { await chat.setPinned(conversation.id, true) }
                else { chat.notice = "The reply took too long. Your request has been preserved; you can try again." }
                chat.drafts[conversation.id] = en ? "Keep this draft for later." : "Guarde este rascunho para depois."
                for scheme in [ColorScheme.light, .dark] {
                    for width in [480.0, 780.0] {
                        let compact = width < 600
                        let view = LocalChatPrompt(chat: chat, conversation: conversation, compact: compact, active: false)
                            .frame(width: width, height: compact ? 300 : nil).fixedSize(horizontal: false, vertical: true)
                            .environment(\.islandPreview, true).environment(\.islandReduceMotion, true)
                            .environment(\.colorScheme, scheme).environment(\.locale, Locale(identifier: language))
                        let renderer = ImageRenderer(content: view); renderer.scale = 2
                        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
                        guard let image = renderer.cgImage,
                              let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
                        let name = "\(language)-\(scheme == .dark ? "dark" : "light")-\(Int(width))-\(unavailable ? "recovery" : "notice").png"
                        try png.write(to: output.appendingPathComponent(name))
                        records.append(["file": name, "width": image.width, "height": image.height])
                        print(name, image.width, image.height)
                    }
                }
                chat.shutdown()
            }
        }
        let record: [String: Any] = ["sampleDataOnly": true, "hardwareAudio": false, "screenCapture": false, "residentLifecycle": false, "renders": records]
        try JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("catalog.json"))
    }
}

@MainActor private final class CatalogChat: LocalChatGenerating {
    let unavailable: Bool
    init(unavailable: Bool) { self.unavailable = unavailable }
    var readiness: LocalChatReadiness { unavailable ? .unavailable("Enable Apple Intelligence in System Settings to use the new on-device model.") : .available }
    func generate(history: [LocalChatMessage], persona: LocalChatPersona, onSnapshot: @escaping @MainActor (String) -> Void) async throws -> String {
        preconditionFailure("Catalog must not run model requests")
    }
}

private actor CatalogChatStore: LocalChatStoring {
    let conversation: LocalChatConversation
    let failsSave: Bool
    init(conversation: LocalChatConversation, failsSave: Bool) { self.conversation = conversation; self.failsSave = failsSave }
    func load() -> [LocalChatConversation] { [conversation] }
    func save(_ conversations: [LocalChatConversation]) throws {
        if failsSave { throw CocoaError(.fileWriteNoPermission) }
    }
}

private final class CatalogSensor: AccelerometerProviding {
    var onSample: ((AccelerationSample) -> Void)?
    let isRunning = false
    func start() throws { preconditionFailure("Catalog must not start sensors") }
    func stop() {}
}
@MainActor private final class CatalogSystem: SystemSampling {
    func read() -> MonitorReading {
        var value = MonitorReading(); value.sampledAt = Date()
        value.memoryTotal = 16_000_000_000; value.memoryUsed = 7_000_000_000
        value.memoryPressure = "Normal"; value.thermalState = "Normal"
        value.battery = 0.8; value.batteryHealth = 0.95; value.onAC = true
        return value
    }
}
@MainActor private final class CatalogAwake: AwakeBackend {
    func context() -> AwakeContext { .init() }
    func acquire(display: Bool) throws -> UInt32 { preconditionFailure("Catalog must not acquire power assertions") }
    func isHeld(_ token: UInt32, display: Bool) -> Bool { preconditionFailure("Catalog must not inspect power assertions") }
    func release(_ token: UInt32) { preconditionFailure("Catalog must not release power assertions") }
}
@MainActor private final class CatalogDisplay: DisplayPowerBackend {
    func displays() -> [DisplayInfo] { [.init(id: 1, name: "Tela de exemplo", builtIn: true, brightness: 0.7, hdrHeadroom: 1)] }
    func brightness(_ value: Double, display: CGDirectDisplayID) throws { preconditionFailure("No brightness changes") }
    func dim(_ value: Double, display: CGDirectDisplayID) throws { preconditionFailure("No display changes") }
    func restore() {}
    func sleepDisplays() throws { preconditionFailure("No display sleep") }
    func connectedBluetooth() -> [String] { [] }
    func disconnectBluetooth(_ id: String) throws { preconditionFailure("No Bluetooth changes") }
    func reconnectBluetooth(_ id: String) throws { preconditionFailure("No Bluetooth changes") }
}
@MainActor private final class CatalogAudio: AudioBackend {
    func snapshot() -> AudioSnapshot { .init() }
    func prepareApplicationAudio() async throws { preconditionFailure("No audio capture") }
    func setVolume(_ volume: Float, device: UInt32, input: Bool) throws { preconditionFailure("No audio changes") }
    func setDefault(_ device: UInt32, input: Bool) throws { preconditionFailure("No audio changes") }
    func setInputMuted(_ muted: Bool, device: UInt32) throws { preconditionFailure("No audio changes") }
    func setApplication(_ app: AudioApplicationInfo, gain: Float, output: AudioDeviceInfo) throws { preconditionFailure("No audio routing") }
    func retainApplications(_ ids: Set<String>) {}
    func stopApplications() {}
}
