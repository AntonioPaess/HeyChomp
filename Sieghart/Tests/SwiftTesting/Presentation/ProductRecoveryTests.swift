import AppKit
import Foundation
import Testing
import CoreText
import UniformTypeIdentifiers

extension LogicTests {
    @Suite(.tags(.logic, .interactions)) struct ProductRecoveryLogicTests {
        @Test("G30.02 · Weather accepts global unqualified names, English and contextual follow-ups")
        func locationPhrasing() {
            for (question, city) in [("Qual a temperatura de Alasca?", "alasca"), ("Sieg, como está o tempo em Zermmat?", "zermmat"), ("What's the temperature in Tokyo?", "tokyo"), ("Está chovendo em Porto?", "porto")] {
                #expect(VoiceWeatherQuery.parse(question)?.city == city)
            }
            #expect(VoiceWeatherQuery.parse("E em Lisboa?", previousCity: "Porto")?.city == "lisboa")
            #expect(VoiceWeatherQuery.parse("Está chovendo lá?", previousCity: "Porto")?.city == "Porto")
            #expect(VoiceWeatherQuery.parse("Alasca", expectsLocation: true)?.city == "alasca")
            #expect(VoiceWeatherQuery.parse("E Zermmat", previousCity: "Porto")?.city == "zermmat")
            #expect(VoiceWeatherQuery.parse("obrigado", previousCity: "Porto") == nil)
            #expect(VoiceWeatherQuery.parse("Explique o que é chuva") == nil)
        }
        @Test("G30.02 · Geographic spelling repair is general and rejects equally close places")
        func spelling() {
            let a = WeatherPlace(name: "Zermatt", latitude: 46, longitude: 7, admin1: "Valais", country: "Switzerland", feature_code: "PPL")
            let b = WeatherPlace(name: "Zermatt", latitude: 10, longitude: 10, admin1: "Other", country: "Other", feature_code: "PPL")
            #expect(WeatherNameMatching.distance("Zermmat", "Zermatt") == 2)
            #expect(WeatherNameMatching.closest("Zermmat", among: [a]) == a)
            #expect(WeatherNameMatching.closest("Zermmat", among: [a,b]) == nil)
            #expect(WeatherNameMatching.closest("unrelated", among: [a]) == nil)
        }
        @Test("G30.02 · Seven distinct weather scenes follow data rather than city names")
        func weatherScenes() {
            for (temperature, code, expected) in [(-4.0, 0, CompanionWeatherMood.frozen), (8, 0, .cold), (22, 0, .comfortable), (32, 0, .hot), (22, 61, .rain), (2, 71, .snow), (22, 95, .storm)] {
                let observation = VoiceWeatherObservation(location: "Any named place", temperature: temperature, feelsLike: temperature, date: Date(), timezone: "UTC", code: code, isDay: true)
                #expect(CompanionWeatherMood.resolve(observation) == expected)
            }
        }
        @Test("G30.02 · Region searches preserve regional scope and source while making audio concise")
        func regionalWeather() async throws {
            let service = VoiceWeatherService(transport: { request in
                let url = try #require(request.url)
                let data = url.host == "geocoding-api.open-meteo.com" ? #"{"results":[{"name":"Alasca","latitude":64.0,"longitude":-152.0,"country":"Estados Unidos","feature_code":"ADM1"}]}"# : #"{"timezone":"America/Anchorage","current":{"time":1800000000,"temperature_2m":-4,"apparent_temperature":-9,"weather_code":71,"is_day":1}}"#
                return (Data(data.utf8), try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)))
            }, now: { Date(timeIntervalSince1970: 1800000000) })
            let report = try await service.report(to: .init(city: "alasca", future: false), language: "pt-BR")
            #expect(report.observation?.regionEstimate == true)
            #expect(report.reply.contains("Open-Meteo") && report.reply.contains("horário local"))
            #expect(report.spokenReply(language: "pt-BR").count < report.reply.count)
            #expect(report.spokenReply(language: "pt-BR").contains("referência regional"))
        }
        @Test("G30.03 · Canvas revisions preserve ids, relationships and unrelated labels")
        func revisions() throws {
            let graph = CanvasDiagram(arrangement: .flow, nodes: [.init(id: "a", title: "Entrada", detail: "", kind: .process), .init(id: "b", title: "Saída", detail: "", kind: .terminal)], links: [.init(from: "a", to: "b", label: "")])
            let original = GeneratedCanvas(title: "Test", spokenSummary: "Test graph", code: "", codeLanguage: "", elements: [], diagram: graph)
            let revised = try #require(CanvasRevision.parse("Troque a legenda \"Entrada\" por \"Início\"" )).applying(to: original)
            #expect(revised.id == original.id && revised.diagram?.links == graph.links)
            #expect(revised.diagram?.nodes[0].title == "Início" && revised.diagram?.nodes[1] == graph.nodes[1])
            let highlight = try #require(CanvasRevision.parse("Destaca \"Saída\"" )).applying(to: revised)
            #expect(highlight.diagram?.nodes[1].emphasized == true)
            #expect(CanvasRevision.parse("Não renomeie \"Entrada\" para \"Outra\"") == nil)
            #expect(throws: CanvasRevisionError.self) { try CanvasRevision.rename("Missing", "X").applying(to: original) }
            let svg = CanvasSVGExporter.render(graph, title: "<script>alert('x')</script>")
            #expect(!svg.contains("<script>") && svg.contains("&lt;script&gt;") && svg.contains("marker-end"))
        }
        @Test("G30.03 · Unquoted PT and EN edits change only the named block", arguments: [
            "Mova o bloco Entrada para a direita", "Por favor, move Entrada pra cima!",
            "Could you move the node Entrada to the right?", "Move Entrada up",
            "Destaque a etapa Entrada", "Please highlight the block Entrada",
            "Troque a legenda Entrada por Validação", "Rename the node Entrada to Validação"
        ])
        func naturalRevision(_ command: String) throws {
            let original = revisionDocument()
            let graph = try #require(original.diagram)
            let revised = try #require(CanvasRevision.parse(command, canvas: original)).applying(to: original)
            let updated = try #require(revised.diagram)
            #expect(revised.id == original.id && revised.elements == original.elements)
            #expect(updated.links == graph.links && updated.arrangement == graph.arrangement)
            #expect(updated.nodes[0] != graph.nodes[0] && updated.nodes[1] == graph.nodes[1])
            _ = try revised.validated()
        }
        @Test("G30.03 · Rename separators inside arbitrary node titles use the displayed document")
        func revisionWithSeparators() throws {
            let original = revisionDocument(first: "Busca por nome")
            let command = "Troque o bloco Busca por nome por Consulta por usuário"
            let revision = try #require(CanvasRevision.parse(command, canvas: original))
            let revised = try revision.applying(to: original)
            #expect(revision == .rename("Busca por nome", "Consulta por usuário"))
            #expect(revised.diagram?.nodes[0].title == "Consulta por usuário")
            #expect(revised.diagram?.nodes[1] == original.diagram?.nodes[1])
            let ambiguous = revisionDocument(first: "Busca", second: "Busca por nome")
            #expect(CanvasRevision.parse(command, canvas: ambiguous) == .ambiguous)
            #expect(throws: CanvasRevisionError.self) { try CanvasRevision.ambiguous.applying(to: ambiguous) }
            let quoted = try #require(CanvasRevision.parse("Troque o bloco \"Busca por nome\" por \"Consulta por usuário\"", canvas: ambiguous))
            #expect(try quoted.applying(to: ambiguous).diagram?.nodes[1].title == "Consulta por usuário")
        }
        @Test("G30.03 · Missing or duplicate edit targets preserve the current drawing")
        func invalidRevisionTargets() throws {
            let original = revisionDocument()
            let duplicate = revisionDocument(second: "Entrada")
            let missing = try #require(CanvasRevision.parse("Destaque o bloco Inexistente", canvas: original))
            #expect(throws: CanvasRevisionError.self) { try missing.applying(to: original) }
            #expect(throws: CanvasRevisionError.self) { try CanvasRevision.highlight("Entrada").applying(to: duplicate) }
            #expect(original.diagram?.nodes.map(\.title) == ["Entrada", "Saída"])
            #expect(duplicate.diagram?.nodes.allSatisfy { $0.emphasized == nil } == true)
        }
        @Test("G30.03 · Questions, new content, searches and negated edits are not canvas mutations", arguments: [
            "Não mova Entrada para a direita", "Please don't highlight Entrada", "Could you not rename Entrada to Outra",
            "Pesquise como mover o bloco Entrada para a direita", "How do I highlight Entrada?",
            "Explique como renomear Entrada para Outra", "Draw a new diagram about moving blocks",
            "Crie um fluxograma de Entrada para Saída", "Qual a temperatura de Recife?"
        ])
        func inertRevision(_ command: String) {
            #expect(CanvasRevision.parse(command, canvas: revisionDocument()) == nil)
        }
        @Test("G30.03 · Natural edits do not intercept window, code or settings commands", arguments: [
            "Mova Safari para a esquerda", "Move Safari to the left", "Rename the variable count to total",
            "Change my language to English", "Renomeie a variável entrada para resultado",
            "Highlight the selected text", "Mude o tema para escuro",
            "Change the name of this file to Outro", "Troque o texto selecionado por outro"
        ], [false, true])
        func unrelatedEdits(_ command: String, _ hasCanvas: Bool) {
            #expect(CanvasRevision.parse(command, canvas: hasCanvas ? revisionDocument() : nil) == nil)
        }
        @Test("G30.03 · Unquoted drawing edits require a displayed drawing", arguments: [
            "Destaque a etapa Entrada", "Troque a legenda Entrada por Outra", "Move the block Input up"
        ])
        func naturalEditWithoutCanvas(_ command: String) {
            #expect(CanvasRevision.parse(command) == nil)
        }
        private func revisionDocument(first: String = "Entrada", second: String = "Saída") -> GeneratedCanvas {
            let graph = CanvasDiagram(arrangement: .flow, nodes: [
                .init(id: "a", title: first, detail: "Keep this detail", kind: .process),
                .init(id: "b", title: second, detail: "Keep the other detail", kind: .terminal)
            ], links: [.init(from: "a", to: "b", label: "next")])
            return GeneratedCanvas(title: "Revision fixture", spokenSummary: "Fixture graph", code: "", codeLanguage: "", elements: [], diagram: graph)
        }
        @Test("G30.03 · A real class with one observed member does not require invented siblings")
        func singleObservedMember() throws {
            let source = "final class SelectedTripController { func cancelPreview() {} }"
            let canvas = try ObservedClassDiagram.make(title: "Selected class", summary: "The observed member cancels the preview.",
                className: "SelectedTripController", members: [.init(identifier: "cancelPreview", detail: "Cancels the preview")], observed: source)
            #expect(canvas.diagram?.nodes.map(\.title) == ["SelectedTripController", "cancelPreview"])
            #expect(canvas.diagram?.links.count == 1)
            #expect(throws: SpatialContentError.self) {
                try ObservedClassDiagram.make(title: "Selected class", summary: "Unknown member", className: "SelectedTripController",
                    members: [.init(identifier: "inventedAPI", detail: "")], observed: source)
            }
        }
        @Test("G30.01 · Voice address repair never rewrites references to Siri inside the request")
        func address() {
            #expect(VoiceAddressNormalization.request("Siri, leia minha tela") == "Chomp, leia minha tela")
            #expect(VoiceAddressNormalization.request("Explique como funciona a Siri") == "Explique como funciona a Siri")
            #expect(VoiceAddressNormalization.request("Siri funciona offline?") == "Siri funciona offline?")
        }
        @Test("G30.03 · Class diagram requests retain the observed code as data without changing intent")
        func contextualClassDiagram() throws {
            var request = try #require(CanvasRequest.parse("Faça um diagrama dessa classe do CarPlay e me explique"))
            #expect(request.wantsDiagram && !request.wantsCode && request.needsScreenContext)
            request.screenContext = "class DestinationController { func refresh() {} }"
            #expect(request.authorPrompt.contains("DestinationController") && request.authorPrompt.contains("untrusted data"))
            #expect(request.prompt == "Faça um diagrama dessa classe do CarPlay e me explique")
            #expect(CanvasRequest.parse("Crie um diagrama do ciclo da água")?.needsScreenContext == false)
            #expect(CanvasRequest.parse("Escreva o código do Two Sum na minha tela")?.needsScreenContext == false)
        }
        @Test("G30.03 · Observed class members produce connected containment without invented calls")
        func observedClassStructure() throws {
            let source = "final class TripPreviewCoordinator { func showPreview() {} func cancelPreview() {} }"
            let members = [ObservedClassDiagram.Member(identifier: "showPreview", detail: "Shows the selected trip"), .init(identifier: "cancelPreview", detail: "Clears the preview")]
            let canvas = try ObservedClassDiagram.make(title: "Class", summary: "The observed members.", className: "TripPreviewCoordinator", members: members, observed: source)
            let graph = try #require(canvas.diagram)
            #expect(graph.arrangement == .hierarchy && graph.nodes.count == 3)
            #expect(graph.links.allSatisfy { $0.from == "class" })
            #expect(throws: SpatialContentError.self) {
                try ObservedClassDiagram.make(title: "Class", summary: "Missing", className: "TripPreviewCoordinator", members: [.init(identifier: "inventedAPI", detail: ""), members[0]], observed: source)
            }
            #expect(throws: SpatialContentError.self) {
                try ObservedClassDiagram.make(title: "Class", summary: "Wrong root", className: "showPreview", members: members, observed: source)
            }
        }
    }
}

extension MacContractsTests {
    @MainActor @Suite(.tags(.isolated, .voiceIntegration)) struct ProductRecoveryStateTests {
        @Test("G30.03 · Typed and transcribed revisions share current-canvas resolution without model calls", arguments: [false, true])
        func contextualCanvasRevision(_ usesAudio: Bool) async throws {
            let speech = SigVoiceSynthesizer(playsHardwareAudio: false), engine = PresentationVoiceGenerator()
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, voiceEngine: engine, managesWindows: false)
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            let graph = CanvasDiagram(arrangement: .flow, nodes: [
                .init(id: "a", title: "Busca por nome", detail: "Source detail", kind: .process),
                .init(id: "b", title: "Resultado", detail: "Target detail", kind: .terminal)
            ], links: [.init(from: "a", to: "b", label: "next")])
            let original = GeneratedCanvas(title: "Fixture", spokenSummary: "Fixture summary", code: "", codeLanguage: "", elements: [], diagram: graph)
            try overlay.present(original)
            let command = "Troque o bloco Busca por nome por Consulta por usuário"
            var reply: String?
            if usesAudio {
                if case .handledImmediate(let status, _) = coordinator.tryHandleVoiceCommand(command) { reply = status }
            } else { reply = await coordinator.executeFromChatIfApplicable(command) }
            #expect(reply == "Atualizei essa parte do desenho.")
            #expect(overlay.generatedCanvas?.id == original.id)
            #expect(overlay.generatedCanvas?.diagram?.nodes[0].title == "Consulta por usuário")
            #expect(overlay.generatedCanvas?.diagram?.nodes[1] == graph.nodes[1])
            #expect(overlay.generatedCanvas?.diagram?.links == graph.links && engine.requests.isEmpty)
            if !usesAudio { #expect(coordinator.response == nil && !speech.isSpeaking) }
        }
        @Test("G30.03 · Failed edits preserve the canvas and explain recovery in the selected language", arguments: [false, true])
        func failedCanvasRevision(_ usesAudio: Bool) async throws {
            let speech = SigVoiceSynthesizer(playsHardwareAudio: false)
            let overlay = SpatialOverlayViewModel(voiceSynthesizer: speech, managesWindow: false)
            let coordinator = SpatialAssistantCoordinator(overlay: overlay, managesWindows: false)
            coordinator.responseLanguage = "en-US"
            defer { coordinator.cancelVoiceResponse(); coordinator.stopBackgroundWork(); overlay.dismiss() }
            let graph = CanvasDiagram(arrangement: .flow, nodes: [
                .init(id: "a", title: "Input", detail: "", kind: .process),
                .init(id: "b", title: "Output", detail: "", kind: .terminal)
            ], links: [.init(from: "a", to: "b", label: "")])
            let original = GeneratedCanvas(title: "Fixture", spokenSummary: "Fixture summary", code: "", codeLanguage: "", elements: [], diagram: graph)
            try overlay.present(original, language: "en-US")
            var reply: String?
            if usesAudio {
                if case .handledImmediate(let status, _) = coordinator.tryHandleVoiceCommand("Highlight the block Missing") { reply = status }
            } else { reply = await coordinator.executeFromChatIfApplicable("Highlight the block Missing") }
            #expect(reply?.contains("unique label") == true)
            #expect(overlay.generatedCanvas == original && coordinator.lastStatus == reply)
            if !usesAudio { #expect(coordinator.response == nil && !speech.isSpeaking) }
        }
        @Test("G30.04 · Artifact files survive reopening and cannot turn into executable SVG markup")
        func artifactStorage() throws {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("sieg-library-" + UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: root) }
            let library = CompanionArtifactLibrary(directory: root)
            let canvas = GeneratedCanvas(title: "Example code", spokenSummary: "Display only", code: "print(1)", codeLanguage: "python", elements: [])
            library.saveCanvas(canvas); library.saveCanvas(canvas)
            #expect(library.items.count == 1)
            let item = try #require(library.items.first), url = try #require(library.url(for: item))
            let code = try String(contentsOf: url, encoding: .utf8)
            #expect(url.pathExtension == "py" && code == "print(1)")
            let restored = CompanionArtifactLibrary(directory: root)
            #expect(restored.items == library.items)
            try Data("corrupt".utf8).write(to: root.appendingPathComponent("index.json"))
            let corrupt = CompanionArtifactLibrary(directory: root); corrupt.saveCanvas(canvas)
            let preserved = try String(contentsOf: root.appendingPathComponent("index.json"), encoding: .utf8)
            #expect(corrupt.issue != nil && preserved == "corrupt")
        }
        @Test("G30.03 · Fifteen-step walkthrough checkpoints survive restart at the completed offset")
        func checkpointStorage() throws {
            let name = "sieg-checkpoint-" + UUID().uuidString, defaults = try #require(UserDefaults(suiteName: name))
            defer { defaults.removePersistentDomain(forName: name) }
            let plan = try ScreenGuidancePlan(title: "Long workflow", steps: (0..<15).map { .init(instruction: "Step \($0)", targetText: "Target \($0)", expectedText: "") }).validated()
            let journal = CompanionTaskJournal(defaults: defaults)
            let id = journal.begin(kind: .guidance, request: "Guide me", language: "en")
            journal.update(id, guidance: .init(plan: plan, index: 8))
            let restored = CompanionTaskJournal(defaults: defaults)
            #expect(restored.tasks.first?.state == .paused && restored.tasks.first?.guidance?.index == 8)
            #expect(!WalkthroughCheckpoint(plan: plan, index: 15).valid)
        }
        @Test("G03.05 · Pinning and archiving keep original conversation contents and persist")
        func historyOrganization() async throws {
            let a = LocalChatConversation(id: "a", persona: .sig, title: "Weather", updatedAt: Date(timeIntervalSince1970: 1), messages: [.init(role: .user, text: "Recife")])
            let b = LocalChatConversation(id: "b", persona: .ada, title: "Code", updatedAt: Date(timeIntervalSince1970: 2), messages: [])
            let store = MemoryLocalChatStore([a,b]), model = LocalChatViewModel(generator: UnavailableLocalChatEngine(), store: store)
            await model.prepare(); await model.setPinned("a", true)
            #expect(model.matchingConversations().map(\.id) == ["a", "b"])
            #expect(model.matchingConversations("recife").map(\.id) == ["a"])
            await model.setArchived("a", true)
            #expect(model.matchingConversations().map(\.id) == ["b"])
            let restored = LocalChatViewModel(generator: UnavailableLocalChatEngine(), store: store); await restored.prepare()
            #expect(restored.matchingConversations(archived: true).first?.messages == a.messages)
        }
        @Test("G30.04 · Document reading includes the last PDF page and rejects a symbolic-link attachment")
        func documentPages() throws {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("sieg-pdf-test-"+UUID().uuidString)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: root) }
            let url = root.appendingPathComponent("example.pdf")
            var bounds = CGRect(x: 0, y: 0, width: 400, height: 500)
            let consumer = try #require(CGDataConsumer(url: url as CFURL))
            let context = try #require(CGContext(consumer: consumer, mediaBox: &bounds, nil))
            for text in ["First page: source alpha", "Final page: source omega"] {
                context.beginPDFPage(nil); context.textPosition = CGPoint(x: 30, y: 440)
                let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: CTFontCreateWithName("Helvetica" as CFString, 14, nil)]))
                CTLineDraw(line, context); context.endPDFPage()
            }
            context.closePDF()
            let document = try CompanionDocument.read(url)
            #expect(document.pages.count == 2 && !document.truncated)
            #expect(document.text.contains("source alpha") && document.text.contains("source omega"))
            let library = CompanionArtifactLibrary(directory: root.appendingPathComponent("library"))
            library.saveDocument(document)
            let stored = try #require(library.items.first), storedURL = try #require(library.url(for: stored))
            #expect(storedURL.pathExtension == "pdf")
            #expect(try Data(contentsOf: storedURL) == Data(contentsOf: url))
            let reopened = try CompanionDocument.read(storedURL)
            #expect(reopened.pages.count == 2 && reopened.text.contains("source omega"))
            let exported = try library.file(for: stored)
            #expect(try exported.name.hasSuffix(".pdf") && exported.data == Data(contentsOf: url))
            let dragURL = try library.representationURL(for: stored)
            #expect(try dragURL.lastPathComponent == "example.pdf" && Data(contentsOf: dragURL) == exported.data)
            try FileManager.default.removeItem(at: storedURL)
            #expect(throws: CompanionArtifactFailure.self) { try library.file(for: stored) }
            let extracted = try library.file(for: stored, format: .extractedText)
            #expect(extracted.name == "example.txt" && String(data: extracted.data, encoding: .utf8) == document.text)
            let failedDestination = root.appendingPathComponent("should-not-exist.pdf")
            #expect(throws: CompanionArtifactFailure.self) { try library.write(stored, to: failedDestination) }
            #expect(!FileManager.default.fileExists(atPath: failedDestination.path))
            try FileManager.default.createSymbolicLink(at: storedURL, withDestinationURL: url)
            #expect(library.url(for: stored) == nil)
            #expect(throws: CompanionArtifactFailure.self) { try library.file(for: stored) }
            let textURL = root.appendingPathComponent("example.txt"); try Data("Text fixture".utf8).write(to: textURL)
            let link = root.appendingPathComponent("link.txt"); try FileManager.default.createSymbolicLink(at: link, withDestinationURL: textURL)
            #expect(throws: (any Error).self) { try CompanionDocument.read(link) }
        }
        @Test("G30.05 · Workflow retry retains a completed step and does not execute it twice")
        func workflowRetry() async throws {
            let journal = CompanionTaskJournal(), runner = CompanionWorkflowRunner(journal: journal)
            defer { runner.shutdown() }
            var calls: [String] = [], fail = true
            runner.executor = { step, context, _ in
                calls.append(step.request)
                if step.request == "second", fail { fail = false; throw ResearchFailure.unavailable }
                if step.request == "second" { #expect(context.contains("first result")) }
                return step.request + " result"
            }
            let id = try runner.start(title: "Pipeline", steps: [.init(persona: .ada, request: "first"), .init(persona: .toni, request: "second")], language: "en")
            try await PresentationWait.until { journal.tasks.first?.state == .failed && runner.activeID == nil }
            let steps = try #require(journal.tasks.first?.workflow)
            #expect(steps[0].result == "first result" && steps[1].result == nil)
            try runner.start(title: "Pipeline", steps: steps, language: "en", resuming: id)
            try await PresentationWait.until { journal.tasks.first?.state == .completed && runner.activeID == nil }
            #expect(journal.tasks.count == 1 && calls == ["first", "second", "second"])
            #expect(journal.tasks.first?.fullResult.contains("second result") == true)
        }
        @Test("G30.05 · Daily routines require opt-in, coalesce missed runs and keep the next occurrence in the future")
        func routineSchedule() async throws {
            let routines = CompanionRoutines(), now = Date()
            defer { routines.stop() }
            let calendar = Calendar.current, components = calendar.dateComponents([.hour, .minute], from: now)
            let routine = CompanionRoutine(title: "Fixture", kind: .briefing, prompt: "Fixture agenda", hour: components.hour!, minute: components.minute!, timezone: calendar.timeZone.identifier, language: "pt-BR", nextRun: now.addingTimeInterval(-60))
            var calls = 0
            routines.execute = { _ in calls += 1 }
            routines.add(routine); routines.start(); routines.tick(now: now)
            #expect(!routines.items[0].enabled && calls == 0)
            routines.setEnabled(routine.id, true, now: now.addingTimeInterval(-90000))
            routines.tick(now: now); routines.tick(now: now)
            try await PresentationWait.until { routines.items[0].lastRun != nil && routines.activeID == nil }
            routines.tick(now: now)
            #expect(calls == 1 && routines.items[0].nextRun > now)
            #expect(routines.items[0].failures == 0)
        }
    }
}


extension MacContractsTests {
    @MainActor @Suite(.tags(.isolated, .interactions, .localChat)) struct ArtifactReplyTests {
        @Test("G30.04 · Saved replies preserve source, code bytes and identity across restart")
        func replyPersistence() throws {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("sieg-reply-" + UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: root) }
            let reply = LocalChatMessage(role: .assistant, text: "<think>private draft\n```swift\nsecret()\n```</think>\nA useful answer.\n```python\nprint('olá')\n```\n```swift\nlet value = 42\n```")
            let chat = LocalChatConversation(persona: .ada, title: "An answer / example", messages: [reply])
            let library = CompanionArtifactLibrary(directory: root)
            let saved = try #require(library.saveReply(reply, in: chat))
            #expect(!saved.content.contains("secret") && !saved.content.contains("<think>"))
            #expect(library.saveReply(reply, in: chat)?.id == saved.id && library.items.count == 1)
            let code = try #require(library.saveReply(reply, in: chat, codeBlock: 0))
            #expect(code.kind == .code && code.content == "print('olá')" && code.filename.hasSuffix(".py"))
            #expect(library.saveReply(reply, in: chat, codeBlock: 99) == nil)
            #expect(library.saveReply(reply, in: chat, codeBlock: 1)?.filename.hasSuffix(".swift") == true)
            let restored = CompanionArtifactLibrary(directory: root)
            let restoredCode = try #require(restored.items.first { $0.id == code.id })
            #expect(restoredCode.sourceChatID == chat.id && restoredCode.sourceMessageID == reply.id)
            try FileManager.default.removeItem(at: root.appendingPathComponent(code.filename))
            var forged = restoredCode; forged.content = "uncommitted text"
            let file = try restored.file(for: forged)
            #expect(file.name.hasSuffix(".py") && file.data == Data("print('olá')".utf8))
            let representation = try restored.representationURL(for: restoredCode)
            #expect(try Data(contentsOf: representation) == file.data)
            let drag = restored.dragProvider(for: restoredCode)
            #expect(drag.registeredTypeIdentifiers.first == UTType.fileURL.identifier)
            #expect(drag.suggestedName == representation.lastPathComponent)
            let blocker = root.appendingPathComponent("blocker"); try Data().write(to: blocker)
            #expect(throws: (any Error).self) { try restored.write(restoredCode, to: blocker.appendingPathComponent("reply.py")) }
        }
        @Test("G30.04 · Thought-only, unfinished, user and detached messages cannot be saved")
        func rejectsNonReplies() {
            let library = CompanionArtifactLibrary()
            for text in ["<think>private</think>", "<think>unfinished", " "] {
                let reply = LocalChatMessage(role: .assistant, text: text)
                #expect(library.saveReply(reply, in: .init(persona: .sig, title: "Example", messages: [reply])) == nil)
            }
            let user = LocalChatMessage(role: .user, text: "Not a reply")
            #expect(library.saveReply(user, in: .init(persona: .sig, title: "Example", messages: [user])) == nil)
            let reply = LocalChatMessage(role: .assistant, text: "Detached")
            #expect(library.saveReply(reply, in: .init(persona: .sig, title: "Example")) == nil)
            #expect(library.items.isEmpty)
        }
        @Test("G30.04 · Legacy index without chat links still opens and exports")
        func legacyIndex() throws {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("sieg-legacy-" + UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: root) }
            let library = CompanionArtifactLibrary(directory: root)
            library.saveCanvas(.init(title: "Legacy", spokenSummary: "Display", code: "hello", codeLanguage: "text", elements: []))
            let index = root.appendingPathComponent("index.json")
            var records = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: index)) as? [[String: Any]])
            records[0].removeValue(forKey: "sourceChatID"); records[0].removeValue(forKey: "sourceMessageID")
            try JSONSerialization.data(withJSONObject: records).write(to: index)
            let restored = CompanionArtifactLibrary(directory: root)
            let item = try #require(restored.items.first)
            #expect(item.sourceChatID == nil && item.sourceMessageID == nil)
            #expect(try restored.file(for: item).data == Data("hello".utf8))
        }
    }
}
