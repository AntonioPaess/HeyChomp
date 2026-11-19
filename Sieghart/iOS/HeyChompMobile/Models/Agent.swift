import Foundation

/// Os seis personagens da equipe HeyChomp.
///
/// O Chomp é o companheiro principal e orquestrador; os outros cinco são
/// especialistas com responsabilidades fixas (ver `HANDOFF.md`). O enum só
/// descreve identidade e papel. Cores e imagens ficam em
/// `DesignSystem/Agent+Style.swift`, para o modelo não depender de SwiftUI.
enum Agent: String, CaseIterable, Identifiable, Hashable, Sendable {
    case chomp, rita, ada, gantt, elinor, toni

    var id: String { rawValue }

    /// Nome exibido.
    var name: String {
        switch self {
        case .chomp: "Chomp"
        case .rita: "Rita"
        case .ada: "Ada"
        case .gantt: "Gantt"
        case .elinor: "Elinor"
        case .toni: "Toni"
        }
    }

    /// Papel em poucas palavras (cartões, listas).
    var role: String {
        switch self {
        case .chomp: "Organiza a equipe e responde você"
        case .rita: "Foco e saúde"
        case .ada: "Código"
        case .gantt: "Agenda e diário"
        case .elinor: "Finanças"
        case .toni: "Arquivos, áudio e captura"
        }
    }

    /// Descrição mais longa, usada no perfil do agente.
    var summary: String {
        switch self {
        case .chomp: "Recebe seus pedidos por voz ou texto, decide quem da equipe resolve e devolve a resposta num balão."
        case .rita: "Segura seu foco com sessões e pausas. Em breve também vai olhar sono, passos e pausas com o Apple Health."
        case .ada: "Cuida de tarefas de código: revisões, trechos e o que está pendente nos seus projetos."
        case .gantt: "Guarda a agenda e o bullet journal. Avisa antes dos compromissos e migra o que ficou para trás."
        case .elinor: "Acompanha só as finanças: orçamento do mês, categorias e próximas contas."
        case .toni: "Cuida da área de transferência, dos arquivos recentes, do áudio e das capturas."
        }
    }

    /// Recurso anunciado mas ainda inexistente. Aparece como pílula "em breve".
    var upcomingFeature: String? {
        switch self {
        case .rita: "Saúde · em breve"
        case .elinor: "Apple Pay · em breve"
        case .gantt: "E-mail · em breve"
        default: nil
        }
    }

    /// Chave usada nos assets compartilhados com o Mac (`Peek-sig`, `Companion-sig`…).
    /// No código do Mac, o Chomp ainda se chama `sig`.
    var assetKey: String { self == .chomp ? "sig" : rawValue }

    /// Personagem "espiando" por cima de uma borda (480 × 340 px @2x).
    var peekImageName: String { "Peek-\(assetKey)" }

    /// Retrato inteiro com fundo transparente (1024 × 1024 px @2x).
    var portraitImageName: String { "Companion-\(assetKey)" }

    /// Nome do ícone alternativo do app (Ajustes → Ícone do app). `nil` = ícone padrão, o Chomp.
    /// Os conjuntos `AppIcon-<Nome>` são gerados por `Tools/app-icon/generate_app_icons.py`.
    var alternateIconName: String? { self == .chomp ? nil : "AppIcon-\(name)" }

    /// Miniatura do ícone para a tela de escolha (imageset com claro e escuro).
    var iconPreviewName: String { "IconPreview-\(rawValue)" }

    /// Especialistas, sem o Chomp.
    static var specialists: [Agent] { allCases.filter { $0 != .chomp } }
}
