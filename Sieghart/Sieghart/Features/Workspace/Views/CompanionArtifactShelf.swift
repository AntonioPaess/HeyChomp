import AppKit
import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct CompanionArtifactShelf: View {
    @ObservedObject var library: CompanionArtifactLibrary
    let language: String
    var openSource: ((CompanionArtifact) -> Bool)? = nil
    @Environment(\.islandPreview) private var preview
    @State private var selected: CompanionArtifact?
    @State private var search = ""
    @State private var kind: CompanionArtifact.Kind?
    @State private var sourceMissing = false
    private var en: Bool { language.hasPrefix("en") }
    private var filtered: [CompanionArtifact] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return library.items.filter {
            (kind == nil || $0.kind == kind) && (term.isEmpty || $0.title.localizedStandardContains(term) || $0.content.localizedStandardContains(term))
        }
    }
    private let kinds: [CompanionArtifact.Kind] = [.text, .code, .diagram, .research, .document]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(en ? "Your library" : "Sua biblioteca").font(.title3.weight(.semibold))
                    Text(en ? "Keep the useful parts. Pick them up anytime." : "Guarde o que importa. Retome quando quiser.")
                        .font(.caption).foregroundStyle(CompanionStyle.muted)
                }
                Spacer()
                Button(action: importDocument) { Label(en ? "Import" : "Importar", systemImage: "plus") }
                    .help(en ? "Import a document" : "Importar documento")
            }
            if let issue = library.issue {
                HStack(alignment: .top) {
                    Label { Text(LocalizedStringKey(issue)) } icon: { Image(systemName: "exclamationmark.circle") }
                        .font(.callout).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button { library.clearIssue() } label: { Image(systemName: "xmark") }
                        .buttonStyle(.plain).accessibilityLabel(en ? "Dismiss notice" : "Fechar aviso")
                }
            }
            if library.items.isEmpty {
                emptyState(symbol: "tray", title: en ? "A home for your results" : "Um lugar para seus resultados",
                    detail: en ? "Save a reply from chat, create a diagram or import a document. Your files stay on this Mac." : "Salve uma resposta do chat, crie um diagrama ou importe um documento. Seus arquivos ficam neste Mac.")
            } else {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(CompanionStyle.muted)
                    if preview { Text(en ? "Find a result" : "Encontrar um resultado").foregroundStyle(CompanionStyle.muted) }
                    else { TextField(en ? "Find a result" : "Encontrar um resultado", text: $search).textFieldStyle(.plain) }
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.plain).accessibilityLabel(en ? "Clear search" : "Limpar busca")
                    }
                }.font(.callout).padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(CompanionStyle.edge.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                if preview { filters.frame(maxWidth: .infinity, alignment: .leading) }
                else { ScrollView(.horizontal, showsIndicators: false) { filters } }
                if filtered.isEmpty {
                    emptyState(symbol: "magnifyingglass", title: en ? "No results here yet" : "Nenhum resultado por aqui",
                        detail: en ? "Try another name, a word from the content or another type." : "Tente outro nome, uma palavra do conteúdo ou outro tipo.")
                    Button(en ? "Clear filters" : "Limpar filtros") { search = ""; kind = nil }
                } else {
                    Text(resultCount).font(.caption).foregroundStyle(CompanionStyle.muted)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                        ForEach(filtered) { item in card(item) }
                    }
                }
            }
        }
        .onChange(of: library.items) { _, items in
            if let selected { self.selected = items.first { $0.id == selected.id } }
        }
        .sheet(item: $selected, onDismiss: { sourceMissing = false }) { item in detail(item) }
    }
    private var resultCount: String {
        let count = filtered.count
        if en { return count == 1 ? "1 saved result" : "\(count) saved results" }
        return count == 1 ? "1 resultado salvo" : "\(count) resultados salvos"
    }
    private var filters: some View {
        HStack(spacing: 8) {
            filterButton(nil)
            ForEach(kinds, id: \.rawValue) { filterButton($0) }
        }
    }
    private func filterButton(_ value: CompanionArtifact.Kind?) -> some View {
        Button { kind = value } label: {
            Text(kindTitle(value)).font(.caption.weight(.medium)).padding(.horizontal, 12).padding(.vertical, 7)
                .foregroundStyle(kind == value ? CompanionStyle.accentInk : CompanionStyle.muted)
                .background(kind == value ? CompanionStyle.accent.opacity(0.15) : CompanionStyle.edge.opacity(0.035), in: Capsule())
        }.buttonStyle(.plain).accessibilityAddTraits(kind == value ? .isSelected : [])
    }
    private func emptyState(symbol: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol).font(.system(size: 26, weight: .light)).foregroundStyle(CompanionStyle.accentInk)
            Text(title).font(.headline)
            Text(detail).font(.callout).foregroundStyle(CompanionStyle.muted).fixedSize(horizontal: false, vertical: true)
        }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            .background(CompanionStyle.edge.opacity(0.025), in: RoundedRectangle(cornerRadius: 18))
    }
    private func card(_ item: CompanionArtifact) -> some View {
        Button { selected = item; sourceMissing = false } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(CompanionStyle.accent.opacity(0.07))
                    if let diagram = item.diagram {
                        CanvasDiagramView(document: .init(title: item.title, spokenSummary: item.title, code: "", codeLanguage: "", elements: [], diagram: diagram), diagram: diagram, progress: 1)
                            .frame(width: 600, height: 600).scaleEffect(0.18).frame(width: 120, height: 108).clipped()
                    } else if let url = library.url(for: item), url.pathExtension.lowercased() == "pdf" { CompanionPDFThumbnail(url: url) }
                    else { Image(systemName: symbol(item.kind)).font(.system(size: 30)).foregroundStyle(CompanionStyle.accentInk) }
                }.frame(height: 110).clipped().accessibilityHidden(true)
                Text(item.title).font(.callout.weight(.medium)).lineLimit(2).frame(height: 36, alignment: .topLeading)
                HStack {
                    Text(kindTitle(item.kind)).font(.caption2)
                    Spacer(minLength: 4)
                    Text(item.date, style: .relative).font(.caption2)
                }.foregroundStyle(CompanionStyle.muted)
            }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(CompanionStyle.edge.opacity(0.035), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(CompanionStyle.edge.opacity(0.07), lineWidth: 1))
        }.buttonStyle(.plain).onDrag { library.dragProvider(for: item) }
            .contextMenu {
                exportActions(item)
                if let url = library.url(for: item) { Button(en ? "Show in Finder" : "Mostrar no Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) } }
            }
            .help(en ? "Open preview or drag to another app" : "Abra a prévia ou arraste para outro app")
    }
    private func detail(_ item: CompanionArtifact) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title).font(.title2.weight(.semibold)).lineLimit(2)
                    Text(kindTitle(item.kind)).font(.caption).foregroundStyle(CompanionStyle.muted)
                }
                Spacer()
                Menu(en ? "Export" : "Exportar") { exportActions(item) }
                Button(en ? "Close" : "Fechar") { selected = nil }.keyboardShortcut(.cancelAction)
            }
            if item.sourceChatID != nil, let openSource {
                Button { if openSource(item) { selected = nil } else { sourceMissing = true } } label: {
                    Label(en ? "Open original reply" : "Abrir resposta original", systemImage: "arrow.up.backward")
                }
            }
            if sourceMissing {
                Text(en ? "The original chat is no longer available. This saved result is preserved." : "A conversa original não está mais disponível. Este resultado salvo foi preservado.").font(.callout).foregroundStyle(.secondary)
            }
            if let issue = library.issue { Text(LocalizedStringKey(issue)).font(.callout).foregroundStyle(.orange) }
            if item.originalFilename != nil, library.url(for: item) == nil {
                Label(en ? "Original unavailable · showing extracted text" : "Original indisponível · mostrando texto extraído", systemImage: "doc.badge.ellipsis")
                    .font(.callout).foregroundStyle(.orange)
            }
            if let url = library.url(for: item), url.pathExtension.lowercased() == "pdf" { CompanionPDFPreview(url: url) }
            else if let diagram = item.diagram {
                CanvasDiagramView(document: .init(title: item.title, spokenSummary: item.title, code: "", codeLanguage: "", elements: [], diagram: diagram), diagram: diagram, progress: 1)
            } else if let elements = item.elements, !elements.isEmpty {
                GeneratedCanvasView(document: .init(title: item.title, spokenSummary: item.title, code: "", codeLanguage: "", elements: elements), progress: 1, opacity: 1)
            } else {
                ScrollView {
                    if item.kind == .text || item.kind == .research { AgentMarkdownView(markdown: item.content) }
                    else { Text(item.content).font(item.kind == .code ? .system(.body, design: .monospaced) : .body).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                }
            }
            HStack {
                Label(en ? "Stored on this Mac" : "Salvo neste Mac", systemImage: "internaldrive").font(.caption).foregroundStyle(CompanionStyle.muted)
                Spacer()
                Button(en ? "Copy text" : "Copiar texto") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(item.content, forType: .string) }
            }
        }.padding(24).frame(minWidth: 640, idealWidth: 720, minHeight: 580)
    }
    @ViewBuilder private func exportActions(_ item: CompanionArtifact) -> some View {
        Button(item.originalFilename != nil ? (en ? "Export original…" : "Exportar original…") : (en ? "Export file…" : "Exportar arquivo…")) { library.export(item) }
            .disabled(item.originalFilename != nil && library.url(for: item) == nil)
        if item.kind == .document { Button(en ? "Export extracted text…" : "Exportar texto extraído…") { library.export(item, format: .extractedText) } }
    }
    private func importDocument() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.pdf, .plainText, .sourceCode, .json, .commaSeparatedText]
        if panel.runModal() == .OK, let url = panel.url { Task { do { _ = try await library.importDocument(url) } catch { library.report(error) } } }
    }
    private func kindTitle(_ kind: CompanionArtifact.Kind?) -> String {
        switch kind {
        case nil: en ? "All" : "Tudo"
        case .text: en ? "Replies" : "Respostas"
        case .code: en ? "Code" : "Código"
        case .diagram: en ? "Diagrams" : "Diagramas"
        case .research: en ? "Research" : "Pesquisas"
        case .document: en ? "Documents" : "Documentos"
        }
    }
    private func symbol(_ kind: CompanionArtifact.Kind) -> String {
        switch kind { case .code: "curlybraces"; case .diagram: "point.3.connected.trianglepath.dotted"; case .research: "books.vertical"; case .document: "doc.text"; case .text: "text.alignleft" }
    }
}
