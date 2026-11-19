import Foundation

/// Item da área de transferência cuidada pelo Toni.
struct ClipboardItem: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case text, link, image
    }

    let id: String
    var kind: Kind
    var content: String
    var source: String
    var time: String
}

/// Arquivo recente.
struct FileItem: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var detail: String
    var symbol: String
}

/// Saída de áudio disponível.
struct AudioOutput: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var symbol: String
}

/// Atalho de captura.
struct CaptureAction: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var symbol: String
}
