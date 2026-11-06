import CoreGraphics
import Foundation
import Testing

private actor GeneratedCanvasFixture: SpatialContentGenerating {
    var requests: [CanvasRequest] = []
    var languages: [String] = []
    let document: GeneratedCanvas
    let holds: Bool
    var pending: CheckedContinuation<GeneratedCanvas, any Error>?
    init(document: GeneratedCanvas, holds: Bool = false) { self.document = document; self.holds = holds }
    func canvas(for request: CanvasRequest, language: String) async throws -> GeneratedCanvas {
        requests.append(request)
        languages.append(language)
        if holds { return try await withCheckedThrowingContinuation { pending = $0 } }
        return document
    }
    func describeScreen(_ image: CapturedScreenImage, text: String, question: String, language: String) async throws -> String { throw SpatialContentError.noVision }
    func finish() { pending?.resume(returning: document); pending = nil }
    var entered: Bool { !requests.isEmpty }
}

@MainActor private final class CanvasScreenFixture: ScreenSemanticInspecting {
    let reading: ScreenSemanticReading
    var requests: [String] = []
    var selections: [ScreenSelection?] = []
    var holdsReading = false
    private var pending: CheckedContinuation<ScreenSemanticReading, Never>?
    init(failure: ScreenInspectionFailure? = nil, source: String = "final class TripPreviewCoordinator { func showPreview() {} }", selectedText: String = "") {
        reading = .init(elementRole: "AXTextArea", elementTitle: "Selected source", elementValue: "",
            ocrText: source, elementFrame: .zero,
            cursorPoint: .zero, spokenExplanation: "", failure: failure, selectedText: selectedText)
    }
    func inspectAtCursor(query: String) async -> ScreenSemanticReading { await inspect(query: query, selection: nil) }
    func inspect(query: String, selection: ScreenSelection?) async -> ScreenSemanticReading {
        requests.append(query); selections.append(selection)
        if holdsReading { return await withCheckedContinuation { pending = $0 } }
        return reading
    }
    func finish() { holdsReading = false; let continuation = pending; pending = nil; continuation?.resume(returning: reading) }
    func recognizeText(in cgImage: CGImage) throws -> String { reading.ocrText }
}

private actor DelayedGuidanceFixture: SpatialContentGenerating {
    var entered = false
    var texts: [String] = []
    private var pending: CheckedContinuation<ScreenGuidancePlan, Never>?
    func canvas(for request: CanvasRequest, language: String) async throws -> GeneratedCanvas { throw SpatialContentError.unavailable }
    func describeScreen(_ image: CapturedScreenImage, text: String, question: String, language: String) async throws -> String { throw SpatialContentError.noVision }
    func guidance(text: String, question: String, language: String) async throws -> ScreenGuidancePlan {
        texts.append(text)
        entered = true
        return await withCheckedContinuation { pending = $0 }
    }
    func finish() {
        let continuation = pending; pending = nil
        continuation?.resume(returning: .init(title: "Delayed fixture guide", steps: [.init(instruction: "Inspect the source", targetText: "TripPreviewCoordinator", expectedText: "")]))
    }
}

private actor DelayedToolWeatherFixture: VoiceWeatherProviding {
    var entered = false
    private var pending: CheckedContinuation<VoiceWeatherReport, Never>?
    func reply(to query: VoiceWeatherQuery) async throws -> String { try await report(to: query, language: "en").reply }
    func report(to query: VoiceWeatherQuery, language: String) async throws -> VoiceWeatherReport {
        entered = true
        return await withCheckedContinuation { pending = $0 }
    }
    func finish() {
        let continuation = pending; pending = nil
        continuation?.resume(returning: .init(reply: "Delayed weather fixture", observation: .init(location: "Delayed fixture", temperature: 10,
            feelsLike: 10, date: .now, timezone: "UTC", code: 0, isDay: true)))
    }
}

extension LogicTests {
    @Suite(.tags(.logic, .interactions)) struct GeneratedCanvasLogicTests {
        @Test("G30.02 · Generic screen content requests preserve subject and code intent", arguments: [
            ("Escreva o código do Two Sum na minha tela e me explique", true),
            ("Desenha uma casa com uma árvore", false),
            ("Crie um diagrama do ciclo da água", false),
            ("Show the binary search code on my screen", true)
        ])
        func requestRouting(_ request: String, _ code: Bool) throws {
            let parsed = try #require(CanvasRequest.parse(request))
            #expect(parsed.prompt == request && parsed.wantsCode == code)
        }
        @Test("G30.02 · Search, negation and instructions about drawing do not create a canvas", arguments: [
            "Pesquise como desenhar uma casa", "Não desenhe uma casa", "How to draw a tree?", "Como desenhar um cachorro?",
            "Ada, explique como desenhar um diagrama", "Explain how to draw a class diagram",
            "Explique como essa classe funciona e não faça um diagrama", "Explain how this class works and don't draw it",
            "How to draw a diagram and write code?", "Ada, não desenhe esse código"
        ])
        func inertTopics(_ request: String) { #expect(CanvasRequest.parse(request) == nil) }

        @Test("G30.03 · Explaining first does not discard an explicit second drawing request", arguments: [
            "Explique como essa classe funciona e faça um diagrama",
            "Explica como esse código funciona e desenha um diagrama",
            "Ada, explique como esta função funciona e crie um fluxograma",
            "Explain how this class works and draw a diagram",
            "Ada, explain how that method works and please create a diagram",
            "Como funciona essa classe? Faça um diagrama",
            "What does this class do? Draw a diagram",
            "Faça um diagrama do código da tela e explique como funciona",
            "Make a diagram of the code on my screen and explain it"
        ])
        func compoundExplanation(_ prompt: String) throws {
            let request = try #require(CanvasRequest.parse(prompt))
            #expect(request.prompt == prompt && request.wantsDiagram && !request.wantsCode && request.needsScreenContext)
        }

        @Test("G30.02 · Generated graphics validate finite bounded coordinates and real geometry")
        @MainActor func graphicsValidation() throws {
            let line = CanvasElement(kind: .polyline, points: [.init(x: 0.1, y: 0.2), .init(x: 0.5, y: 0.8), .init(x: 0.9, y: 0.2)], text: "", ink: .gold, filled: false)
            let document = GeneratedCanvas(title: "Fixture", spokenSummary: "A generated diagram.", code: "", codeLanguage: "", elements: [line])
            #expect(try document.validated() == document)
            let path = GeneratedCanvasView.path(for: line, in: .init(x: 0, y: 0, width: 100, height: 100))
            #expect(!path.isEmpty && abs(path.boundingRect.width - 80) < 0.01)
            let invalid = CanvasElement(kind: .polyline, points: [.init(x: .nan, y: 0.2), .init(x: 2, y: 0.8)], text: "", ink: .cyan, filled: false)
            #expect(throws: SpatialContentError.self) {
                try GeneratedCanvas(title: "Invalid", spokenSummary: "Invalid.", code: "", codeLanguage: "", elements: [invalid]).validated()
            }
            #expect(throws: SpatialContentError.self) {
                try GeneratedCanvas(title: "Empty", spokenSummary: "Empty.", code: "", codeLanguage: "", elements: []).validated()
            }
        }
    }
}

extension MacContractsTests {
    @MainActor @Suite(.tags(.isolated, .voiceIntegration)) struct GeneratedCanvasTests {
        private func codeDocument() -> GeneratedCanvas {
            .init(title: "Generated code", spokenSummary: "Here is the requested function.", code: "func value() -> Int { 42 }", codeLanguage: "Swift", elements: [])
        }
        @Test("G30.03 · Model draw tools receive the observed source instead of inventing context", arguments: [false, true])
        func toolObservedClass(_ usesAudio: Bool) async throws {
            let service = GeneratedCanvasFixture(document: codeDocument()), inspector = CanvasScreenFixture()
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            let prompt = "Faça um diagrama dessa classe do CarPlay e explique"
            _ = await coordinator.executeModelTool("draw", query: "ignore this alternative subject", minutes: 0, original: prompt, usesAudio: usesAudio)
            #expect(inspector.requests == [prompt])
            #expect(await service.requests.first?.screenContext == inspector.reading.ocrText)
            #expect(overlay.generatedCanvas != nil)
            if !usesAudio { #expect(coordinator.response == nil && overlay.voiceSynthesizer.lastSpokenText == nil) }
        }
        @Test("G30.03 · Model draw tools stop before generation when permission or visible text is missing", arguments: [false, true])
        func toolWithoutEvidence(_ denied: Bool) async {
            let service = GeneratedCanvasFixture(document: codeDocument())
            let inspector = CanvasScreenFixture(failure: denied ? .permission : nil, source: denied ? "unreadable" : "")
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            let reply = await coordinator.executeModelTool("draw", query: "", minutes: 0, original: "Draw a diagram of the selected class", usesAudio: false)
            #expect(await service.requests.isEmpty)
            #expect(overlay.generatedCanvas == nil && !reply.contains("Verified canvas"))
            #expect(coordinator.screenAccessIssue == (denied ? .permission : nil))
        }
        @Test("G30.03 · A delayed model tool cannot replace a newer drawing or its language")
        func supersededToolCanvas() async throws {
            let service = GeneratedCanvasFixture(document: codeDocument(), holds: true)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            let task = Task { await coordinator.executeModelTool("draw", query: "", minutes: 0, original: "Write code on my screen", usesAudio: true) }
            defer { task.cancel(); Task { await service.finish() }; coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            try await waitForCanvas(service)
            _ = await coordinator.executeFromChatIfApplicable("Desenha um círculo na tela")
            let drawing = try #require(overlay.activeDrawing)
            await service.finish(); _ = await task.value
            #expect(overlay.generatedCanvas == nil && overlay.activeDrawing?.id == drawing.id)
            #expect(coordinator.response == nil)
        }
        @Test("G30.03 · A model tool preserves the request language while the generator is delayed")
        func toolLanguageSnapshot() async throws {
            let service = GeneratedCanvasFixture(document: codeDocument(), holds: true)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            coordinator.responseLanguage = "en-US"
            let task = Task { await coordinator.executeModelTool("draw", query: "", minutes: 0, original: "Write code on my screen", usesAudio: false) }
            defer { task.cancel(); Task { await service.finish() }; coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            try await waitForCanvas(service)
            coordinator.responseLanguage = "pt-BR"
            await service.finish(); _ = await task.value
            #expect(await service.languages == ["en-US"])
            #expect(overlay.uiLanguage == "en-US")
        }
        @Test("G30.03 · A planned draw keeps the region selected before the model tool was called")
        func toolSelectedRegion() async throws {
            let service = GeneratedCanvasFixture(document: codeDocument()), inspector = CanvasScreenFixture()
            let engine = PresentationVoiceGenerator(); engine.holdsReplies = true
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, voiceEngine: engine, spatialContent: service, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); engine.finishAll(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            coordinator.screenInteraction.beginListening(language: "pt-BR")
            let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
            coordinator.screenInteraction.drag(to: .init(x: 100, y: 120), in: frame)
            coordinator.screenInteraction.drag(to: .init(x: 450, y: 500), in: frame)
            coordinator.screenInteraction.finishDrag()
            let selection = try #require(coordinator.screenInteraction.pendingSelection)
            let prompt = "Ative o Keep Awake por 2 horas e faça um diagrama dessa classe na tela"
            coordinator.answerVoiceQuestion(prompt)
            try await PresentationWait.until { !engine.requests.isEmpty }
            _ = await coordinator.executeModelTool("draw", query: "", minutes: 0, original: prompt, usesAudio: false)
            #expect(inspector.selections == [selection])
            #expect(await service.requests.first?.screenContext == inspector.reading.ocrText)
        }
        @Test("G30.03 · Replacement during tool capture does not start generation with stale source")
        func supersededToolCapture() async throws {
            let inspector = CanvasScreenFixture(); inspector.holdsReading = true
            let service = GeneratedCanvasFixture(document: codeDocument())
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            let task = Task { await coordinator.executeModelTool("draw", query: "", minutes: 0, original: "Faça um diagrama dessa classe", usesAudio: false) }
            defer { inspector.finish(); task.cancel(); coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            try await PresentationWait.until { !inspector.requests.isEmpty }
            _ = await coordinator.executeFromChatIfApplicable("Desenha um círculo na tela")
            let drawing = try #require(overlay.activeDrawing)
            inspector.finish(); _ = await task.value
            #expect(await service.requests.isEmpty)
            #expect(overlay.activeDrawing?.id == drawing.id && overlay.generatedCanvas == nil)
        }
        @Test("G30.03 · Superseded weather tools cannot restore their card or follow-up context")
        func supersededToolWeather() async throws {
            let weather = DelayedToolWeatherFixture()
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, weather: weather, managesWindows: false)
            let task = Task { await coordinator.executeModelTool("weather", query: "", minutes: 0, original: "Qual a temperatura de Lisboa?", usesAudio: true) }
            defer { task.cancel(); Task { await weather.finish() }; coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            let clock = ContinuousClock(), deadline = clock.now.advanced(by: .seconds(3))
            while !(await weather.entered), clock.now < deadline { try await Task.sleep(for: .milliseconds(2)) }
            try #require(await weather.entered)
            _ = await coordinator.executeFromChatIfApplicable("Desenha um círculo na tela")
            await weather.finish(); let reply = await task.value
            #expect(coordinator.weatherObservation == nil && coordinator.weatherQuery(for: "E Lisboa?") == nil)
            #expect(reply.contains("discarded"))
        }
        @Test("G30.03 · Delayed guidance cannot start after a different typed request")
        func supersededGuidance() async throws {
            let service = DelayedGuidanceFixture()
            let selected = "Selected source: TripPreviewCoordinator"
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), inspector: CanvasScreenFixture(source: "Unrelated menu text", selectedText: selected), managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            let task = Task { await coordinator.executeFromChatIfApplicable("Leia minha tela e me guie passo a passo na tela") }
            defer { task.cancel(); Task { await service.finish() }; coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            let clock = ContinuousClock(), deadline = clock.now.advanced(by: .seconds(3))
            while !(await service.entered), clock.now < deadline { try await Task.sleep(for: .milliseconds(2)) }
            try #require(await service.entered)
            #expect(await service.texts == [selected])
            _ = await coordinator.executeFromChatIfApplicable("Desenha um círculo na tela")
            let drawing = try #require(overlay.activeDrawing)
            await service.finish(); _ = await task.value
            #expect(!coordinator.walkthrough.isActive && overlay.activeDrawing?.id == drawing.id)
        }
        @Test("G30.03 · Delayed screen annotation cannot replace newer content or reappear after dismissal", arguments: [false, true])
        func supersededAnnotation(_ dismisses: Bool) async throws {
            let inspector = CanvasScreenFixture(); inspector.holdsReading = true
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), inspector: inspector, managesWindow: false)
            let task = Task { await overlay.inspectScreen(query: "Read this screen", speaksReading: false) }
            defer { inspector.finish(); task.cancel(); overlay.dismiss() }
            try await PresentationWait.until { !inspector.requests.isEmpty }
            if dismisses { overlay.dismiss() }
            else { try overlay.present(codeDocument()) }
            let document = overlay.generatedCanvas
            inspector.finish(); _ = await task.value
            #expect(overlay.activeHighlight == nil && overlay.generatedCanvas == document)
            #expect(overlay.isPresentingOverlay == !dismisses)
        }
        private func waitForCanvas(_ service: GeneratedCanvasFixture) async throws {
            let clock = ContinuousClock(), deadline = clock.now.advanced(by: .seconds(3))
            while !(await service.entered), clock.now < deadline { try await Task.sleep(for: .milliseconds(2)) }
            try #require(await service.entered)
        }
        @Test("G30.03 · A class diagram receives observed source through typed and voice entry", arguments: [false, true], [
            "Faça um diagrama dessa classe do CarPlay e me explique",
            "Explique como essa classe funciona e faça um diagrama",
            "Ada, explique como essa classe funciona e crie um diagrama",
            "Explain how the selected class works and draw a diagram"
        ])
        func observedClassContext(_ usesAudio: Bool, _ prompt: String) async throws {
            let document = codeDocument(), service = GeneratedCanvasFixture(document: document)
            let inspector = CanvasScreenFixture(), speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            if usesAudio {
                #expect(coordinator.tryHandleVoiceCommand(prompt) == .handledAsync)
                try await PresentationWait.until { overlay.generatedCanvas != nil }
            } else {
                _ = await coordinator.executeFromChatIfApplicable(prompt)
            }
            let requests = await service.requests
            #expect(inspector.requests == [prompt] && requests.count == 1)
            #expect(requests.first?.screenContext == inspector.reading.ocrText)
            #expect(requests.first?.authorPrompt.contains("TripPreviewCoordinator") == true)
            #expect(overlay.generatedCanvas == document)
            #expect(usesAudio ? speech.lastSpokenText == document.spokenSummary : speech.lastSpokenText == nil)
        }
        @Test("G30.03 · Missing screen permission blocks class generation and offers recovery")
        func missingClassPermission() async throws {
            let service = GeneratedCanvasFixture(document: codeDocument())
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: SigVoiceSynthesizer(playsHardwareAudio: false), inspector: CanvasScreenFixture(failure: .permission), managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            _ = await coordinator.executeFromChatIfApplicable("Faça um diagrama dessa classe do CarPlay e me explique")
            let requests = await service.requests
            #expect(requests.isEmpty && overlay.generatedCanvas == nil)
            #expect(coordinator.screenAccessIssue == .permission)
        }
        @Test("G30.03 · Translate this takes a fresh reading unless the user explicitly refers to the old reading")
        func freshScreenReference() async throws {
            let inspector = CanvasScreenFixture(), voice = PresentationVoiceGenerator()
            let overlay = SpatialOverlayViewModel(inspector: inspector, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, voiceEngine: voice, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork() }
            _ = await coordinator.executeFromChatIfApplicable("Leia minha tela")
            _ = await coordinator.executeFromChatIfApplicable("Traduza isso")
            #expect(inspector.requests == ["Leia minha tela", "Traduza isso"])
        }
        @Test("G30.02 · Code is supplied by the generator and appears as text in the actual overlay")
        func generatedCodeDelivery() async throws {
            let document = codeDocument(), speech = SigVoiceSynthesizer()
            let service = GeneratedCanvasFixture(document: document)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); overlay.dismiss() }
            let request = "Escreva o código do Two Sum na minha tela e explique"
            #expect(coordinator.tryHandleVoiceCommand(request) == .handledAsync)
            try await PresentationWait.until { overlay.generatedCanvas != nil }
            #expect(overlay.generatedCanvas == document && overlay.activeDrawing == nil)
            #expect(speech.lastSpokenText == document.spokenSummary && overlay.isPresentingOverlay)
            let requests = await service.requests
            #expect(requests.first?.prompt == request && requests.first?.wantsCode == true)
        }
        @Test("G30.02 · Cancelled generation cannot show content or speak after a replacement")
        func cancelledCanvasGeneration() async throws {
            let service = GeneratedCanvasFixture(document: codeDocument(), holds: true)
            let speech = SigVoiceSynthesizer()
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, spatialContent: service, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); overlay.dismiss() }
            #expect(coordinator.tryHandleVoiceCommand("Write code on my screen") == .handledAsync)
            let clock = ContinuousClock(), deadline = clock.now.advanced(by: .seconds(3))
            while !(await service.entered), clock.now < deadline { try await Task.sleep(for: .milliseconds(2)) }
            try #require(await service.entered)
            coordinator.cancelVoiceResponse()
            await service.finish()
            await Task.yield(); await Task.yield()
            #expect(overlay.generatedCanvas == nil && !overlay.isPresentingOverlay && speech.lastSpokenText == nil)
        }
    }
}
