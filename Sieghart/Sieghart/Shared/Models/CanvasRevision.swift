import Foundation
import CoreGraphics

enum CanvasRevision: Equatable, Sendable {
    case rename(String, String)
    case highlight(String)
    case move(String, Double, Double)
    case ambiguous

    static func parse(_ request: String, canvas: GeneratedCanvas? = nil) -> Self? {
        let request = SearchVoiceParser.requestText(request)
        guard !SearchVoiceParser.hasSearchIntent(request), !SearchVoiceParser.hasNegatedIntent(request) else { return nil }
        var text = request.replacingOccurrences(of: #"^(?:(?:por favor|please)[, ]+|(?:(?:voc[êe] )?(?:pode|poderia|consegue)|can you|could you)\s+)*"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !SearchVoiceParser.hasNegatedIntent(text) else { return nil }
        if let last = text.last, ".!?".contains(last) { text.removeLast() }
        func groups(_ pattern: String) -> [String]? {
            guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive), let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
            return (1..<m.numberOfRanges).map { Range(m.range(at: $0), in: text).map { String(text[$0]) } ?? "" }
        }
        if let values = groups(#"^(?:troque|troca|renomeie|renomeia|mude|muda|rename|change)\s+(?:(?:a legenda|o texto|o nome|a etapa|the label|the node)\s+)?["“'](.{1,72}?)["”']\s+(?:por|para|to)\s+["“'](.{1,72}?)["”'][.!]?$"#) { return .rename(values[0], values[1]) }
        if let values = groups(#"^(?:destaque|destaca|highlight)\s+(?:(?:a etapa|o bloco|the node)\s+)?["“'](.{1,72}?)["”'][.!]?$"#) { return .highlight(values[0]) }
        if let values = groups(#"^(?:mova|move|mover)\s+["“'](.{1,72}?)["”']\s+(?:para\s+(?:a |o )?|to the\s+)(direita|esquerda|cima|baixo|right|left|top|bottom)[.!]?$"#) {
            let word = values[1].lowercased()
            return .move(values[0], ["direita", "right"].contains(word) ? 0.12 : ["esquerda", "left"].contains(word) ? -0.12 : 0,
                ["baixo", "bottom"].contains(word) ? 0.09 : ["cima", "top"].contains(word) ? -0.09 : 0)
        }

        // Resolve spoken labels against the displayed document, not a subject
        // catalog. Consider every separator: a node may itself contain “por/to”.
        guard let canvas else { return nil }
        let part = #"(?:a legenda|o texto|o nome|a etapa|o bloco|the label|the text|the name|the step|the block|the node)"#
        let noun = "(?:" + part + #"\s+)?"#
        let canvasPart = #"(?:a legenda|a etapa|o bloco|the label|the step|the block|the node)"#
        let labels = canvas.diagram?.nodes.map(\.title) ?? canvas.elements.filter { $0.kind == .text }.map(\.text)
        func targetsPart(_ verbs: String) -> Bool {
            text.range(of: "^(?:" + verbs + #")\s+"# + canvasPart + #"\s+"#, options: [.regularExpression, .caseInsensitive]) != nil
        }
        func targetsLabel(_ target: String) -> Bool { labels.contains { matches($0, target) } }
        if let values = groups(#"^(?:troque|troca|renomeie|renomeia|mude|muda|rename|change)\s+"# + noun + #"(.+)$"#) {
            let body = values[0]
            let separators = try? NSRegularExpression(pattern: #"\s+(?:por|para|to)\s+"#, options: .caseInsensitive)
            let candidates = separators?.matches(in: body, range: NSRange(body.startIndex..., in: body)).compactMap { match -> (String, String)? in
                guard let range = Range(match.range, in: body) else { return nil }
                let source = label(String(body[..<range.lowerBound])), destination = label(String(body[range.upperBound...]))
                guard (1...72).contains(source.count), (1...72).contains(destination.count) else { return nil }
                return (source, destination)
            } ?? []
            let observed = candidates.filter { targetsLabel($0.0) }
            guard !observed.isEmpty || targetsPart("troque|troca|renomeie|renomeia|mude|muda|rename|change") else { return nil }
            let choices = observed.isEmpty ? candidates : observed
            guard choices.count == 1, let choice = choices.first else { return candidates.isEmpty ? nil : .ambiguous }
            return .rename(choice.0, choice.1)
        }
        if let values = groups(#"^(?:destaque|destaca|highlight|realce)\s+"# + noun + #"(.{1,76})$"#) {
            let target = label(values[0])
            guard targetsLabel(target) || targetsPart("destaque|destaca|highlight|realce") else { return nil }
            return (1...72).contains(target.count) ? .highlight(target) : nil
        }
        if let values = groups(#"^(?:mova|move|mover)\s+"# + noun + #"(.{1,76}?)\s+(?:para\s+(?:a |o )?|pra\s+(?:a |o )?|to the\s+|to\s+|)(direita|esquerda|cima|baixo|right|left|top|bottom|up|down)$"#) {
            let target = label(values[0]), word = values[1].lowercased()
            guard targetsLabel(target) || targetsPart("mova|move|mover") else { return nil }
            guard (1...72).contains(target.count) else { return nil }
            return .move(target, ["direita", "right"].contains(word) ? 0.12 : ["esquerda", "left"].contains(word) ? -0.12 : 0,
                         ["baixo", "bottom", "down"].contains(word) ? 0.09 : ["cima", "top", "up"].contains(word) ? -0.09 : 0)
        }
        return nil
    }

    private static func label(_ text: String) -> String {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = text.first, let last = text.last,
           ["\"\"", "“”", "''"].contains(String(first) + String(last)), text.count >= 2 {
            return String(text.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }
    private static func matches(_ value: String, _ target: String) -> Bool {
        value.compare(target, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }
    func applying(to canvas: GeneratedCanvas) throws -> GeneratedCanvas {
        var updated = canvas
        let target: String
        switch self {
        case .rename(let name, _), .highlight(let name), .move(let name, _, _): target = name
        case .ambiguous: throw CanvasRevisionError.ambiguousTarget
        }
        func matches(_ value: String) -> Bool { Self.matches(value, target) }
        if let graph = canvas.diagram {
            let matching = graph.nodes.indices.filter { matches(graph.nodes[$0].title) }
            guard matching.count == 1, let index = matching.first else { throw CanvasRevisionError.ambiguousTarget }
            var nodes = graph.nodes
            switch self {
            case .rename(_, let title): nodes[index].title = title
            case .highlight: nodes[index].emphasized = true
            case .move(_, let x, let y):
                let previous = nodes[index].offset ?? .init(x: 0, y: 0)
                nodes[index].offset = .init(x: previous.x+x, y: previous.y+y)
            case .ambiguous: throw CanvasRevisionError.ambiguousTarget
            }
            let diagram = try CanvasDiagram(arrangement: graph.arrangement, nodes: nodes, links: graph.links).validated()
            if case .move = self {
                let layout = CanvasDiagramLayout.make(diagram, in: .init(x: 80, y: 80, width: 1100, height: 1100))
                guard layout.boxes.allSatisfy({ a in !layout.boxes.contains { b in a.node.id != b.node.id && a.frame.intersects(b.frame) } }) else { throw CanvasRevisionError.overlap }
            }
            updated.diagram = diagram
        } else {
            let matching = canvas.elements.indices.filter { canvas.elements[$0].kind == .text && matches(canvas.elements[$0].text) }
            guard matching.count == 1, let index = matching.first else { throw CanvasRevisionError.ambiguousTarget }
            switch self {
            case .rename(_, let title): updated.elements[index].text = title
            case .highlight: updated.elements[index].ink = .gold
            case .move(_, let x, let y): updated.elements[index].points = updated.elements[index].points.map { .init(x: $0.x+x, y: $0.y+y) }
            case .ambiguous: throw CanvasRevisionError.ambiguousTarget
            }
        }
        return try updated.validated()
    }
}

enum CanvasRevisionError: LocalizedError {
    case ambiguousTarget, overlap
    var errorDescription: String? { message(english: false) }
    func message(english: Bool) -> String {
        switch self {
        case .ambiguousTarget: english ? "I couldn't identify a unique label in this drawing. Use the exact block name; quotation marks can clarify ambiguous names." : "Não consegui identificar uma única legenda no desenho. Use o nome exato do bloco; aspas podem esclarecer nomes ambíguos."
        case .overlap: english ? "That position would overlap another block. The drawing was preserved; choose another direction." : "Essa posição sobreporia outro bloco. O desenho foi preservado; escolha outra direção."
        }
    }
}
