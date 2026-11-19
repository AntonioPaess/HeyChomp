import SwiftUI

/// Toni: área de transferência, arquivos, áudio e captura.
///
/// A saída de áudio e o volume são só estado de tela: não há roteamento de
/// áudio nem reprodução.
@MainActor
@Observable
final class ToniViewModel {
    let status: AgentStatus
    let clipboard: [ClipboardItem]
    let files: [FileItem]
    let outputs: [AudioOutput]
    let captures: [CaptureAction]

    var selectedOutputID: AudioOutput.ID
    var volume = 0.6

    init(data: any DataSource = MockDataSource()) {
        status = data.status(of: .toni)
        clipboard = data.clipboard
        files = data.recentFiles
        outputs = data.audioOutputs
        captures = data.captureActions
        selectedOutputID = data.audioOutputs.first?.id ?? ""
    }

    func symbol(for item: ClipboardItem) -> String {
        switch item.kind {
        case .text: "text.alignleft"
        case .link: "link"
        case .image: "photo"
        }
    }
}
