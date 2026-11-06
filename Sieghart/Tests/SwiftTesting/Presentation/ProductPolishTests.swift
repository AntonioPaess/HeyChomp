import AppKit
import ApplicationServices
import Foundation
import Testing

extension LogicTests {
    @Suite(.tags(.logic, .interactions)) struct ProductPolishLogicTests {
        @Test("G30.02 · Toulouse retains its city and country and Lisboa is a weather follow-up")
        func weatherPhrasing() {
            #expect(VoiceWeatherQuery.parse("Qual a temperatura de Toulouse na França?")?.city == "toulouse na franca")
            #expect(VoiceWeatherQuery.parse("E Lisboa?", previousCity: "Bragança em Portugal")?.city == "lisboa")
            #expect(VoiceWeatherQuery.parse("E em Lisboa?", previousCity: "Bragança em Portugal")?.city == "lisboa")
            #expect(VoiceWeatherQuery.parse("pode continuar", previousCity: "Lisboa") == nil)
        }
        @Test("G30.02 · Weather context cannot consume a new explanation or drawing", arguments: [
            "explicar sobre circunferência", "explique os ângulos", "explain circumference",
            "draw a triangle", "read this text", "Você consegue desenhar um círculo na minha tela e me explicar sobre circunferência?"
        ])
        func newIntentAfterWeather(_ request: String) {
            #expect(VoiceWeatherQuery.parse(request, previousCity: "Lisboa") == nil)
            #expect(VoiceWeatherQuery.parse(request, previousCity: "Lisboa", expectsLocation: true) == nil)
        }
        @Test("G30.02 · Location ellipses require a continuation or an explicit pending question")
        func weatherLocationScope() {
            for city in ["Lisboa", "Zermmat", "Toulouse na França"] {
                #expect(VoiceWeatherQuery.parse(city, previousCity: "Recife") == nil)
                #expect(VoiceWeatherQuery.parse("E " + city, previousCity: "Recife")?.city != nil)
                #expect(VoiceWeatherQuery.parse(city, expectsLocation: true)?.city != nil)
            }
        }
        @Test("G30.02 · A provider cannot replace Toulouse in France with Franca in Brazil")
        func geographicIdentity() async throws {
            let service = VoiceWeatherService(transport: { request in
                let url = try #require(request.url), items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
                let json: String
                if url.host == "geocoding-api.open-meteo.com" {
                    let name = items.first { $0.name == "name" }?.value
                    json = name == "toulouse" ? #"{"results":[{"name":"Toulouse","latitude":43.6,"longitude":1.44,"country":"França","country_code":"FR","population":490000,"feature_code":"PPLA"}]}"# : #"{"results":[{"name":"Franca","latitude":-20.5,"longitude":-47.4,"country":"Brasil","country_code":"BR","feature_code":"PPLA"}]}"#
                } else {
                    #expect(items.first { $0.name == "latitude" }?.value == "43.6")
                    json = #"{"timezone":"Europe/Paris","current":{"time":1800000000,"temperature_2m":10,"apparent_temperature":9,"weather_code":2,"is_day":0}}"#
                }
                return (Data(json.utf8), try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)))
            }, now: { Date(timeIntervalSince1970: 1800000000) })
            let report = try await service.report(to: .init(city: "toulouse na franca", future: false), language: "pt-BR")
            #expect(report.observation?.location == "Toulouse, França")
            let paris = WeatherPlace(name: "Paris", latitude: 48, longitude: 2, admin1: "Île-de-France", country: "France", feature_code: "PPLC", country_code: "FR")
            #expect(!WeatherNameMatching.matches("Paris no Texas", place: paris))
            #expect(WeatherNameMatching.matches("Paris na França", place: paris))
        }
        @Test("G03.05 · Responsibilities route code and mathematics to Ada, utilities to Sieg")
        func responsibilities() {
            for text in ["Explique o Two Sum em Swift", "Explique pi e a circunferência", "Faça o diagrama dessa classe do CarPlay"] {
                #expect(CompanionConversationRouting.destination(for: text, current: .sig, history: []) == .ada)
            }
            for text in ["Qual a temperatura de Recife?", "Ativa o Keep Awake por 2 horas"] {
                #expect(CompanionConversationRouting.destination(for: text, current: .ada, history: []) == .sig)
            }
        }
        @Test("G30.03 · Selected source and accessible editor text take priority over noisy screen OCR")
        func sourcePriority() {
            var reading = ScreenSemanticReading(elementRole: "AXTextArea", elementTitle: "Source", elementValue: "class ExactName {}", ocrText: "Menus and broken OCR", elementFrame: .zero, cursorPoint: .zero, spokenExplanation: "")
            #expect(reading.readableText == "class ExactName {}")
            reading.selectedText = "func selectedMethod() {}"
            #expect(reading.readableText == "func selectedMethod() {}")
        }

        @Test("G30.03 · Natural visible-source references trigger inspection without needing a fixed phrase", arguments: [
            "Leia o texto anterior da tela", "Ada, explica essa classe", "Explique a função que tá aberta",
            "Traduza esse texto", "Resuma a página selecionada", "Ada, explain that method",
            "Explain the selected class", "Read the current document", "Summarize the text on the screen"
        ])
        func visibleSourceIntent(_ prompt: String) {
            #expect(ScreenSemanticInspector.isScreenInspectionIntent(prompt))
        }

        @Test("G30.03 · New code, general questions and weather do not require invented screen context", arguments: [
            "Escreva o código do Two Sum na minha tela", "Qual a temperatura dessa cidade?",
            "Explique uma classe em Swift", "Explain how classes work", "Create a diagram of the water cycle",
            "Write code on my screen", "Write the code for Two Sum on my screen", "Draw a diagram on my screen"
        ])
        func independentSourceIntent(_ prompt: String) {
            #expect(!ScreenSemanticInspector.referencesVisibleContent(prompt))
            #expect(CanvasRequest.parse(prompt)?.needsScreenContext != true)
        }

        @Test("G30.03 · Explicit search and negation do not request a screen capture", arguments: [
            "Pesquise esse código", "Search this class", "Não leia minha tela", "Don't read this text"
        ])
        func inertScreenIntent(_ prompt: String) {
            #expect(!ScreenSemanticInspector.isScreenInspectionIntent(prompt))
        }

        @Test("G30.03 · AX text owned by this app cannot override the external captured screen")
        func ownAccessibilityElement() {
            let ownApp = AXUIElementCreateApplication(ProcessInfo.processInfo.processIdentifier)
            #expect(!ScreenSemanticInspector.isExternalElement(ownApp))
            #expect(ScreenSemanticInspector.isExternalElement(AXUIElementCreateApplication(1)))
        }
    }
}

private actor PolishWeatherFixture: VoiceWeatherProviding {
    var requests: [VoiceWeatherQuery] = []
    func reply(to query: VoiceWeatherQuery) async throws -> String { "Weather fixture" }
    func report(to query: VoiceWeatherQuery, language: String) async throws -> VoiceWeatherReport {
        requests.append(query)
        return .init(reply: "Weather fixture", observation: .init(location: query.city ?? "Missing", temperature: 12, feelsLike: 11, date: Date(), timezone: "UTC", code: 0, isDay: true))
    }
}

private actor PolishSpecialistFixture: SpatialContentGenerating {
    var contexts: [String] = []
    var canvasRequests: [CanvasRequest] = []
    func canvas(for request: CanvasRequest, language: String) async throws -> GeneratedCanvas {
        canvasRequests.append(request)
        return .init(title: "Observed diagram fixture", spokenSummary: "Canvas fixture result", code: "", codeLanguage: "", elements: [
            .init(kind: .rectangle, points: [.init(x: 0.1, y: 0.1), .init(x: 0.8, y: 0.7)], text: "", ink: .cyan, filled: false)
        ])
    }
    func describeScreen(_ image: CapturedScreenImage, text: String, question: String, language: String) async throws -> String { throw SpatialContentError.noVision }
    func askSpecialist(_ persona: LocalChatPersona, question: String, context: String, language: String) async throws -> String {
        contexts.append(context); return "Observed source explanation"
    }
}
@MainActor private final class PolishScreenFixture: ScreenSemanticInspecting {
    var requests = 0
    let failure: ScreenInspectionFailure?
    let source: String
    var holdsReading = false
    private var pending: CheckedContinuation<ScreenSemanticReading, Never>?
    init(failure: ScreenInspectionFailure? = nil, source: String = "final class ActualVisibleClass {}") { self.failure = failure; self.source = source }
    func inspectAtCursor(query: String) async -> ScreenSemanticReading {
        requests += 1
        if holdsReading { return await withCheckedContinuation { pending = $0 } }
        return reading
    }
    private var reading: ScreenSemanticReading { .init(elementRole: "AXTextArea", elementTitle: "Source", elementValue: source, ocrText: source.isEmpty ? "" : "Menu noise", elementFrame: .zero, cursorPoint: .zero, spokenExplanation: "", failure: failure) }
    func finish() { holdsReading = false; let continuation = pending; pending = nil; continuation?.resume(returning: reading) }
    func recognizeText(in cgImage: CGImage) throws -> String { "" }
}

@MainActor private final class RetryScreenFixture: ScreenSemanticInspecting {
    var denied = true
    var holds = false
    var requests = 0
    var selections: [ScreenSelection?] = []
    private var pending: [CheckedContinuation<ScreenSemanticReading, Never>] = []
    private var reading: ScreenSemanticReading {
        .init(elementRole: "AXTextArea", elementTitle: "Fixture source", elementValue: "RETRY_SOURCE_BODY", ocrText: "", elementFrame: .zero,
              cursorPoint: .zero, spokenExplanation: "", failure: denied ? .permission : nil)
    }
    func inspectAtCursor(query: String) async -> ScreenSemanticReading { await inspect(query: query, selection: nil) }
    func inspect(query: String, selection: ScreenSelection?) async -> ScreenSemanticReading {
        requests += 1; selections.append(selection)
        if holds { return await withCheckedContinuation { pending.append($0) } }
        return reading
    }
    func finish() {
        holds = false; let continuations = pending; pending = []
        for continuation in continuations { continuation.resume(returning: reading) }
    }
    func recognizeText(in image: CGImage) throws -> String { "" }
}

@MainActor private final class ScreenRoutingChatFixture: LocalChatGenerating {
    weak var coordinator: SpatialAssistantCoordinator?
    var readiness: LocalChatReadiness { .available }
    var completedCalls = 0
    func generate(history: [LocalChatMessage], persona: LocalChatPersona, onSnapshot: @escaping @MainActor (String) -> Void) async throws -> String {
        defer { completedCalls += 1 }
        guard let question = history.last?.text, let result = await coordinator?.executeFromChatIfApplicable(question) else { throw CancellationError() }
        return result
    }
}

extension MacContractsTests {
    @MainActor @Suite(.tags(.isolated, .voiceIntegration)) struct ProductPolishStateTests {
        @Test("G30.03 · Retrying a screen read stays in its original chat after focus changes")
        func screenRetryOrigin() async throws {
            let question = "Leia minha tela e transcreva o texto"
            let source = LocalChatConversation(persona: .sig, title: "Origin", messages: [
                .init(role: .user, text: question), .init(role: .assistant, text: ScreenInspectionFailure.permission.message(english: false))
            ])
            let other = LocalChatConversation(persona: .sig, title: "Other")
            let chat = LocalChatViewModel(generator: PresentationVoiceGenerator(), store: MemoryLocalChatStore([source, other]))
            await chat.prepare()
            let inspector = RetryScreenFixture()
            let speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, managesWindows: false)
            defer { inspector.finish(); chat.shutdown(); coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            coordinator.registerResearchChat(chat, id: source.id)
            _ = await coordinator.executeFromChatIfApplicable(question)
            chat.select(other.id); chat.drafts[source.id] = "Unsent draft"; chat.drafts[other.id] = "Other draft"
            coordinator.registerResearchChat(chat, id: other.id)
            inspector.denied = false; inspector.holds = true
            coordinator.retryScreenReading()
            try await PresentationWait.until { inspector.requests == 2 }
            coordinator.registerResearchChat(chat, id: other.id)
            inspector.finish()
            try await PresentationWait.until { chat.conversations.contains { $0.messages.last?.text.contains("RETRY_SOURCE_BODY") == true } }
            try await PresentationWait.until { chat.generatingID == nil }
            let origin = try #require(chat.conversations.first { $0.id == source.id })
            #expect(origin.messages.last?.text.contains("RETRY_SOURCE_BODY") == true)
            #expect(origin.messages.count == 2 && origin.messages.first?.id == source.messages.first?.id)
            #expect(chat.conversations.first { $0.id == other.id }?.messages.isEmpty == true)
            #expect(chat.selectedID == other.id && chat.drafts[source.id] == "Unsent draft" && chat.drafts[other.id] == "Other draft")
            #expect(coordinator.response == nil && speech.lastSpokenText == nil)
        }
        @Test("G30.03 · Screen retry preserves drafts and attachments and coalesces repeated clicks")
        func screenRetryDraftAndSelection() async throws {
            let question = "Leia minha tela e transcreva o texto"
            let source = LocalChatConversation(persona: .sig, title: "Origin", messages: [
                .init(role: .user, text: question), .init(role: .assistant, text: ScreenInspectionFailure.permission.message(english: false))
            ])
            let engine = PresentationVoiceGenerator()
            let chat = LocalChatViewModel(generator: engine, store: MemoryLocalChatStore([source]))
            await chat.prepare()
            let inspector = RetryScreenFixture()
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, managesWindows: false)
            let file = FileManager.default.temporaryDirectory.appendingPathComponent("retry-draft-" + UUID().uuidString + ".txt")
            defer { inspector.finish(); chat.shutdown(); coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss(); try? FileManager.default.removeItem(at: file) }
            try "Private draft attachment, not screen input".write(to: file, atomically: true, encoding: .utf8)
            await chat.attach(file, to: source.id)
            chat.drafts[source.id] = "Keep this new draft"
            let files = chat.attachments[source.id]?.map(\.name)
            try #require(files?.count == 1)
            let region = ScreenSelection(screenFrame: .init(x: 0, y: 0, width: 1440, height: 900), bounds: .init(x: 30, y: 40, width: 200, height: 160), trace: [])
            coordinator.registerResearchChat(chat, id: source.id)
            _ = await coordinator.executeFromChatIfApplicable(question, selection: region)
            inspector.denied = false; inspector.holds = true
            chat.retryScreenRequest(in: source.id); chat.retryScreenRequest(in: source.id); chat.retryScreenRequest(in: source.id)
            try await PresentationWait.until { inspector.requests == 2 }
            #expect(chat.generatingID == source.id && chat.drafts[source.id] == "Keep this new draft")
            inspector.finish()
            try await PresentationWait.until { chat.generatingID == nil }
            #expect(inspector.requests == 2 && inspector.selections == [region, region])
            #expect(chat.attachments[source.id]?.map(\.name) == files && chat.drafts[source.id] == "Keep this new draft")
            #expect(chat.selected?.messages.count == 2 && chat.selected?.messages.last?.attachedFiles == nil)
            #expect(engine.requests.isEmpty && coordinator.response == nil && overlay.voiceSynthesizer.lastSpokenText == nil)
        }
        @Test("G30.03 · Timeout or deletion during a noncooperative screen retry never delivers a late result", arguments: [false, true])
        func screenRetryDeadline(_ deletes: Bool) async throws {
            let question = "Faça um diagrama dessa classe na tela"
            let source = LocalChatConversation(persona: .sig, title: "Origin", messages: [
                .init(role: .user, text: question), .init(role: .assistant, text: ScreenInspectionFailure.permission.message(english: false))
            ])
            let other = LocalChatConversation(persona: .sig, title: "Other")
            let chat = LocalChatViewModel(generator: PresentationVoiceGenerator(), store: MemoryLocalChatStore([source, other]), responseTimeout: .milliseconds(100))
            await chat.prepare()
            let inspector = RetryScreenFixture()
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, managesWindows: false)
            defer { inspector.finish(); chat.shutdown(); coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            coordinator.registerResearchChat(chat, id: source.id)
            _ = await coordinator.executeFromChatIfApplicable(question)
            let handler = try #require(chat.screenRetryHandler)
            var returned = false
            chat.screenRetryHandler = { question, id, selection in
                let result = await handler(question, id, selection); returned = true; return result
            }
            chat.drafts[source.id] = "Keep my draft"; chat.select(other.id)
            inspector.denied = false; inspector.holds = true
            chat.retryScreenRequest(in: source.id)
            try await PresentationWait.until { inspector.requests == 2 }
            if deletes { await chat.delete(source.id) }
            else { try await PresentationWait.until { chat.states[source.id] == .failed && chat.generatingID == nil } }
            #expect(!coordinator.taskJournal.tasks.contains { $0.state == .running })
            let before = chat.conversations
            inspector.finish()
            try await PresentationWait.until { returned }
            #expect(chat.conversations == before && chat.selectedID == other.id)
            #expect(chat.conversations.first { $0.id == other.id }?.messages.isEmpty == true)
            if !deletes {
                #expect(chat.conversations.first { $0.id == source.id }?.messages == source.messages)
                #expect(chat.drafts[source.id] == "Keep my draft")
            }
            #expect(coordinator.response == nil && overlay.voiceSynthesizer.lastSpokenText == nil)
        }
        @Test("G30.03 · A typed spatial deadline pauses its task without cancelling a newer drawing", arguments: [false, true])
        func typedSpatialDeadline(_ replaces: Bool) async throws {
            let engine = ScreenRoutingChatFixture(), inspector = RetryScreenFixture()
            inspector.denied = false; inspector.holds = true
            let chat = LocalChatViewModel(generator: engine, responseTimeout: .milliseconds(100))
            await chat.prepare(); let id = try #require(await chat.create(.ada))
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, managesWindows: false)
            engine.coordinator = coordinator
            defer { inspector.finish(); chat.shutdown(); coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            coordinator.registerResearchChat(chat, id: id)
            let question = "Faça um diagrama dessa classe na tela"
            chat.draft = question; chat.send(to: id)
            try await PresentationWait.until { inspector.requests == 1 }
            if replaces { _ = await coordinator.executeFromChatIfApplicable("Desenha um círculo na tela") }
            let drawingID = overlay.activeDrawing?.id
            try await PresentationWait.until { chat.states[id] == .failed && chat.generatingID == nil }
            #expect(!coordinator.taskJournal.tasks.contains { $0.state == .running })
            #expect(overlay.activeDrawing?.id == drawingID && overlay.generatedCanvas == nil)
            inspector.finish()
            try await PresentationWait.until { engine.completedCalls == 1 }
            #expect(chat.selected?.messages.isEmpty == true && chat.draft == question)
            #expect(overlay.activeDrawing?.id == drawingID && overlay.generatedCanvas == nil)
        }
        @Test("G30.03 · Retry replaces a failed reply even at the saved history limit")
        func screenRetryFullHistory() async throws {
            let question = "Leia minha tela e transcreva o texto"
            let earlier = (0..<58).map { LocalChatMessage(role: $0.isMultiple(of: 2) ? .user : .assistant, text: "Earlier message \($0)") }
            let source = LocalChatConversation(persona: .sig, title: "Full", messages: earlier + [
                .init(role: .user, text: question), .init(role: .assistant, text: ScreenInspectionFailure.permission.message(english: false))
            ])
            let chat = LocalChatViewModel(generator: PresentationVoiceGenerator(), store: MemoryLocalChatStore([source]))
            await chat.prepare()
            let inspector = RetryScreenFixture()
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, managesWindows: false)
            defer { inspector.finish(); chat.shutdown(); coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            coordinator.registerResearchChat(chat, id: source.id)
            _ = await coordinator.executeFromChatIfApplicable(question)
            inspector.denied = false
            chat.retryScreenRequest(in: source.id)
            try await PresentationWait.until { chat.generatingID == nil && chat.selected?.messages.last?.text.contains("RETRY_SOURCE_BODY") == true }
            #expect(chat.selected?.messages.count == 60)
            let selected = try #require(chat.selected)
            #expect(Array(selected.messages.dropLast()) == Array(source.messages.dropLast()))
        }
        @Test("G30.02 · A second voice turn E Lisboa reuses weather intent without invoking a generic model")
        func voiceWeatherContinuation() async throws {
            let weather = PolishWeatherFixture(), speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, weather: weather, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork() }
            #expect(coordinator.tryHandleVoiceCommand("Qual a temperatura de Bragança em Portugal?") == .handledAsync)
            try await PresentationWait.until { coordinator.weatherObservation != nil }
            #expect(coordinator.tryHandleVoiceCommand("E Lisboa?") == .handledAsync)
            try await PresentationWait.until { coordinator.weatherObservation?.location == "lisboa" }
            #expect(await weather.requests.map(\.city) == ["braganca em portugal", "lisboa"])
        }
        @Test("G30.02 · Draw and explain remains a compound action after weather", arguments: [
            "Você consegue desenhar um círculo na minha tela e me explicar sobre circunferência?",
            "Desenha um triângulo na tela e explica os ângulos",
            "Draw a circle on my screen and explain circumference",
            "Desenha uma estrela e me fale sobre astronomia"
        ])
        func drawingExplanationAfterWeather(_ command: String) async throws {
            let weather = PolishWeatherFixture(), inspector = PolishScreenFixture()
            let engine = PresentationVoiceGenerator(); engine.reply = "A fresh explanation from the model"
            let speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, voiceEngine: engine, weather: weather, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            #expect(coordinator.tryHandleVoiceCommand("Qual a temperatura de Lisboa?") == .handledAsync)
            try await PresentationWait.until { coordinator.weatherObservation != nil }
            #expect(coordinator.tryHandleVoiceCommand(command) == .handledAsync)
            try await PresentationWait.until { coordinator.lastStatus == engine.reply }
            let shape = try #require(VectorDrawingInterpreter.parseShape(from: command))
            #expect(overlay.activeDrawing?.shape == shape)
            #expect(coordinator.weatherObservation == nil && inspector.requests == 0)
            #expect(await weather.requests.count == 1)
            let prompt = try #require(engine.requests.last?.last?.text)
            #expect(prompt.contains(command) && prompt.contains(shape.rawValue))
            #expect(engine.requests.count == 1)
        }
        @Test("G30.02 · Typed draw and explain completes both effects after weather without audio", arguments: [
            "Você consegue desenhar um círculo na minha tela e me explicar sobre circunferência?",
            "Desenha um triângulo na tela e explica os ângulos",
            "Draw a circle on my screen and explain circumference",
            "Desenha uma estrela e me fale sobre astronomia"
        ])
        func typedDrawingExplanationAfterWeather(_ command: String) async throws {
            let weather = PolishWeatherFixture(), inspector = PolishScreenFixture()
            let engine = PresentationVoiceGenerator(); engine.reply = "Explanation from the injected model"
            let speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, voiceEngine: engine, weather: weather, managesWindows: false)
            coordinator.responseLanguage = command.hasPrefix("Draw") ? "en-US" : "pt-BR"
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            _ = await coordinator.executeFromChatIfApplicable("Qual a temperatura de Lisboa?")
            let reply = try #require(await coordinator.executeFromChatIfApplicable(command))
            let shape = try #require(VectorDrawingInterpreter.parseShape(from: command))
            #expect(overlay.activeDrawing?.shape == shape && overlay.uiLanguage == coordinator.responseLanguage)
            #expect(reply.contains(engine.reply) && !reply.contains("<think>"))
            #expect(coordinator.lastStatus == reply && speech.lastSpokenText == nil && coordinator.response == nil)
            #expect(inspector.requests == 0 && coordinator.weatherObservation == nil)
            #expect(await weather.requests.count == 1)
            #expect(engine.requests.count == 1 && engine.languages == [coordinator.responseLanguage])
            let prompt = try #require(engine.requests.last?.last?.text)
            #expect(prompt.contains(command) && prompt.contains(shape.rawValue))
        }

        @Test("G30.02 · A typed drawing remains real when its model explanation is unavailable")
        func typedDrawingUnavailableModel() async throws {
            let speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); overlay.dismiss() }
            let reply = try #require(await coordinator.executeFromChatIfApplicable("Desenha um círculo na tela e explique pi"))
            #expect(overlay.activeDrawing?.shape == .circle)
            #expect(reply.contains("Não consegui preparar a explicação") && !reply.contains("3,14"))
            #expect(speech.lastSpokenText == nil)
        }

        @Test("G30.02 · Typed shape acknowledgement uses the selected language without invoking a model")
        func typedDrawingLanguage() async throws {
            let engine = PresentationVoiceGenerator()
            let overlay = SpatialOverlayViewModel(managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, voiceEngine: engine, managesWindows: false)
            coordinator.responseLanguage = "en-US"
            defer { coordinator.cancelVoiceResponse(); overlay.dismiss() }
            let reply = try #require(await coordinator.executeFromChatIfApplicable("Draw a circle on my screen"))
            #expect(reply.contains("drawn") && !reply.contains("Desenhei") && !reply.contains("<think>"))
            #expect(engine.requests.isEmpty && overlay.uiLanguage == "en-US")
        }

        @Test("G30.02 · Cancelled or superseded typed explanation cannot overwrite a newer drawing", arguments: [false, true])
        func typedDrawingStaleReply(_ superseded: Bool) async throws {
            let engine = PresentationVoiceGenerator(); engine.holdsReplies = true
            let speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, voiceEngine: engine, managesWindows: false)
            let pending = Task { await coordinator.executeFromChatIfApplicable("Desenha um círculo na tela e explique pi") }
            defer { pending.cancel(); engine.finishAll(); coordinator.cancelVoiceResponse(); overlay.dismiss() }
            try await PresentationWait.until { engine.requests.count == 1 }
            #expect(overlay.activeDrawing?.shape == .circle && overlay.activeDrawing?.holdDuration == 60)
            if superseded { _ = await coordinator.executeFromChatIfApplicable("Desenha um coração na tela") }
            else { pending.cancel() }
            let currentStatus = coordinator.lastStatus
            let currentDrawing = overlay.activeDrawing?.id
            engine.finish(0, reply: "Late answer that must never be shown")
            #expect(await pending.value == nil)
            #expect(coordinator.lastStatus == currentStatus && overlay.activeDrawing?.id == currentDrawing)
            if superseded { #expect(overlay.activeDrawing?.shape == .heart) }
            #expect(speech.lastSpokenText == nil && coordinator.response == nil)
        }

        @Test("G30.01 · Model unavailability never produces a canned explanation", arguments: ["Explique pi", "Explique circunferência", "Explain π", "Explain gravity"], ["pt-BR", "en-US"])
        func unavailableModelDoesNotMock(_ request: String, _ language: String) async throws {
            let engine = OfflineFallbackChatEngine(forVoice: true)
            var snapshots: [String] = []
            do {
                _ = try await engine.generateVoice(history: [.init(role: .user, text: request)], language: language) { snapshots.append($0) }
                Issue.record("An unavailable model must not fabricate an answer")
            } catch let LocalChatError.unavailable(message) {
                #expect(message.contains(language.hasPrefix("en") ? "unavailable" : "não está disponível"))
            }
            #expect(snapshots.isEmpty)
        }
        @Test("G30.03 · Ada receives actual observed source before answering a voice screen question")
        func specialistScreenEvidence() async throws {
            let service = PolishSpecialistFixture(), inspector = PolishScreenFixture()
            let speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            #expect(coordinator.tryHandleVoiceCommand("Ada, explica o código na minha tela") == .handledAsync)
            try await PresentationWait.until { coordinator.lastStatus == "Observed source explanation" }
            #expect(inspector.requests == 1)
            let contexts = await service.contexts
            #expect(contexts.count == 1 && contexts[0].contains("final class ActualVisibleClass {}") && !contexts[0].contains("Menu noise"))
        }
        @Test("G30.03 · Explicit typed Ada screen requests receive observed source, not menu OCR", arguments: [
            "Ada, explica o código na minha tela", "Ada, explica essa classe", "Ada, explain the selected class"
        ])
        func typedSpecialistScreenEvidence(_ prompt: String) async throws {
            let service = PolishSpecialistFixture(), inspector = PolishScreenFixture()
            let speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); overlay.dismiss() }
            let reply = await coordinator.executeFromChatIfApplicable(prompt)
            #expect(reply == "Observed source explanation" && coordinator.lastStatus == reply)
            let contexts = await service.contexts
            #expect(inspector.requests == 1 && contexts.count == 1)
            #expect(contexts.first?.contains(inspector.source) == true && contexts.first?.contains("Menu noise") == false)
            #expect(speech.lastSpokenText == nil && coordinator.response == nil)
        }

        @Test("G30.03 · Failed or empty typed screen readings never reach a specialist model", arguments: [false, true])
        func typedSpecialistMissingScreen(_ denied: Bool) async throws {
            let service = PolishSpecialistFixture(), inspector = PolishScreenFixture(failure: denied ? .permission : nil, source: "")
            let overlay = SpatialOverlayViewModel(inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); overlay.dismiss() }
            let reply = try #require(await coordinator.executeFromChatIfApplicable("Ada, explica o código na minha tela"))
            #expect(!reply.isEmpty && inspector.requests == 1)
            #expect(await service.contexts.isEmpty)
            #expect(coordinator.screenAccessIssue == (denied ? .permission : nil))
        }

        @Test("G30.03 · Calling Ada by name preserves the requested canvas and visible source", arguments: [false, true])
        func namedSpecialistCanvas(_ usesAudio: Bool) async throws {
            let service = PolishSpecialistFixture(), inspector = PolishScreenFixture()
            let speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            let prompt = "Ada, faça um diagrama dessa classe na minha tela e explique"
            if usesAudio {
                #expect(coordinator.tryHandleVoiceCommand(prompt) == .handledAsync)
                try await PresentationWait.until { overlay.generatedCanvas != nil }
            } else {
                #expect(await coordinator.executeFromChatIfApplicable(prompt)?.contains("Canvas fixture result") == true)
                #expect(speech.lastSpokenText == nil && coordinator.response == nil)
            }
            let requests = await service.canvasRequests
            #expect(inspector.requests == 1 && requests.count == 1)
            #expect(requests.first?.screenContext == inspector.source && requests.first?.prompt == prompt)
            #expect(await service.contexts.isEmpty)
            #expect(overlay.generatedCanvas?.title == "Observed diagram fixture")
        }

        @Test("G30.03 · A superseded screen reading is neither explained nor reused as current context", arguments: [
            "Ada, explica o código na minha tela", "Explique o texto na minha tela"
        ])
        func cancelledScreenEvidence(_ prompt: String) async throws {
            let service = PolishSpecialistFixture(), inspector = PolishScreenFixture()
            let voice = PresentationVoiceGenerator()
            inspector.holdsReading = true
            let overlay = SpatialOverlayViewModel(inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, voiceEngine: voice, spatialContent: service, managesWindows: false)
            let pending = Task { await coordinator.executeFromChatIfApplicable(prompt) }
            defer { pending.cancel(); inspector.finish(); coordinator.cancelVoiceResponse(); overlay.dismiss() }
            try await PresentationWait.until { inspector.requests == 1 }
            _ = await coordinator.executeFromChatIfApplicable("Desenha um coração na tela")
            let drawingID = overlay.activeDrawing?.id
            inspector.finish()
            #expect(await pending.value == nil && overlay.activeDrawing?.id == drawingID)
            #expect(await service.contexts.isEmpty)
            #expect(voice.requests.isEmpty)
            _ = await coordinator.executeFromChatIfApplicable("Leia o texto anterior da tela")
            #expect(inspector.requests == 2)
        }

        @Test("G30.03 · A late typed screen explanation cannot overwrite the replacement turn")
        func supersededScreenExplanation() async throws {
            let inspector = PolishScreenFixture(), voice = PresentationVoiceGenerator()
            voice.holdsReplies = true
            let speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, voiceEngine: voice, managesWindows: false)
            let pending = Task { await coordinator.executeFromChatIfApplicable("Explique o texto na minha tela") }
            defer { pending.cancel(); voice.finishAll(); coordinator.cancelVoiceResponse(); overlay.dismiss() }
            try await PresentationWait.until { voice.requests.count == 1 }
            _ = await coordinator.executeFromChatIfApplicable("Desenha um coração na tela")
            let drawing = overlay.activeDrawing?.id, status = coordinator.lastStatus
            voice.finish(0, reply: "Obsolete screen explanation")
            #expect(await pending.value == nil)
            #expect(overlay.activeDrawing?.id == drawing && coordinator.lastStatus == status)
            #expect(speech.lastSpokenText == nil && coordinator.response == nil)
        }

        @Test("G03.05 · Handoff opens Ada's conversation and preserves the originating Sieg chat")
        func chatHandoff() async throws {
            let engine = PresentationVoiceGenerator(); engine.reply = "Code explanation fixture"
            let chat = LocalChatViewModel(generator: engine)
            await chat.prepare(); let source = try #require(await chat.create(.sig))
            chat.draft = "Explique o Two Sum em Swift"; chat.send(to: source)
            try await PresentationWait.until { chat.generatingID == nil && chat.selected?.messages.last?.role == .assistant }
            #expect(chat.selected?.persona == .ada && chat.selectedID != source)
            let original = try #require(chat.conversations.first { $0.id == source })
            #expect(original.persona == .sig && original.messages.last?.handoff?.conversationID == chat.selectedID)
            chat.shutdown()
        }
        @Test("G03.05 · Legacy utility conversations are reclassified without losing their contents")
        func legacyOwnership() async throws {
            let original = LocalChatConversation(persona: .ada, title: "Recife", messages: [.init(role: .user, text: "Qual a temperatura de Recife?"), .init(role: .assistant, text: "27 graus"), .init(role: .user, text: "Agora explique o Two Sum em Swift")])
            let chat = LocalChatViewModel(generator: PresentationVoiceGenerator(), store: MemoryLocalChatStore([original]))
            await chat.prepare()
            #expect(chat.selected?.persona == .sig && chat.selected?.messages == original.messages && chat.selected?.id == original.id)
        }
        @Test("G03.05 · A backend ignoring cancellation cannot leave chat thinking forever or publish a late reply")
        func chatDeadline() async throws {
            let engine = PresentationVoiceGenerator(); engine.holdsReplies = true
            defer { engine.finishAll() }
            let chat = LocalChatViewModel(generator: engine, responseTimeout: .milliseconds(100))
            await chat.prepare(); let id = try #require(await chat.create(.sig))
            chat.draft = "Hello"; chat.send(to: id)
            try await PresentationWait.until { chat.generatingID == nil && chat.states[id] == .failed }
            #expect(chat.draft == "Hello" && chat.selected?.messages.isEmpty == true)
            engine.finish(0, reply: "Late reply must not appear")
            await Task.yield(); await Task.yield()
            #expect(chat.selected?.messages.isEmpty == true && chat.generationStartedAt == nil)
            chat.shutdown()
        }
        @Test("G30.01 · The compact weather receipt expires and opening it preserves the detailed result")
        func pointerReceipt() async throws {
            let pointer = ScreenInteractionController(managesWindows: false)
            let weather = VoiceWeatherObservation(location: "Lisboa", temperature: 12, feelsLike: 11, date: Date(), timezone: "UTC", code: 0, isDay: true)
            var opened = 0, finished = 0
            pointer.onOpenWeather = { observed in #expect(observed == weather); opened += 1 }; pointer.onWeatherFinished = { finished += 1 }
            pointer.setPhase(.speaking); pointer.setWeatherReceipt(weather); pointer.finishResponse(receiptDuration: .milliseconds(50))
            #expect(pointer.phase == .idle && pointer.weatherReceipt == weather && finished == 1)
            try await PresentationWait.until { pointer.weatherReceipt == nil }
            pointer.setWeatherReceipt(weather); pointer.openWeather()
            #expect(opened == 1 && pointer.weatherReceipt == nil)
            pointer.cancel()
        }
        @Test("G30.01 · Weather leaves Home after completion even while hovered; its cursor receipt restores details")
        func weatherSurfaceLifecycle() async throws {
            let weather = PolishWeatherFixture()
            let fixture = try PresentationFixture(voiceWeather: weather)
            defer { fixture.cleanup() }
            var speech = fixture.notch.spatialAssistant.overlay.voiceSynthesizer.configuration
            speech.enabled = false
            fixture.notch.spatialAssistant.overlay.voiceSynthesizer.configuration = speech
            let activation = try fixture.activation()
            fixture.notch.setPointerInsidePanel(true)
            activation.executeVoiceCommand("Qual a temperatura de Lisboa?")
            try await PresentationWait.until { fixture.notch.spatialAssistant.weatherObservation != nil && !activation.isVoiceBusy }
            fixture.notch.setPointerInsidePanel(false)
            fixture.notch.setPointerInsidePanel(true)
            try await PresentationWait.until({ fixture.notch.spatialAssistant.weatherObservation == nil }, timeout: .seconds(8))
            #expect(fixture.notch.isVisible && fixture.notch.presentation == .home)
            #expect(fixture.notch.spatialAssistant.resultCardHeight == 0)
            #expect(fixture.notch.spatialAssistant.screenInteraction.weatherReceipt != nil)
            fixture.notch.spatialAssistant.screenInteraction.openWeather()
            try await PresentationWait.until { fixture.notch.presentation == .home && fixture.notch.spatialAssistant.weatherObservation?.location == "lisboa" }
            activation.cancelVoiceCommand(keepCompanionVisible: true)
            try await PresentationWait.until { fixture.notch.spatialAssistant.weatherObservation == nil }
            #expect(fixture.notch.spatialAssistant.screenInteraction.weatherReceipt == nil)
        }
    }
}
