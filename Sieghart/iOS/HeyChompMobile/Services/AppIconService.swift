import UIKit

/// Troca o ícone do app na tela de início.
///
/// É a única integração real do protótipo, porque o usuário pediu para escolher
/// o avatar do ícone. O iOS mostra um aviso do sistema a cada troca; isso é do
/// sistema e não pode ser evitado. No Mac o ícone continua sendo o Chomp
/// (ver `Sieghart/iOS/ARCHITECTURE.md`).
@MainActor
protocol AppIconService {
    /// Nome do ícone alternativo ativo (`nil` = padrão).
    var currentIconName: String? { get }
    var supportsAlternateIcons: Bool { get }
    func setIcon(named name: String?) async throws
}

/// Implementação com `UIApplication.setAlternateIconName`.
struct SystemAppIconService: AppIconService {
    var currentIconName: String? { UIApplication.shared.alternateIconName }
    var supportsAlternateIcons: Bool { UIApplication.shared.supportsAlternateIcons }

    func setIcon(named name: String?) async throws {
        try await UIApplication.shared.setAlternateIconName(name)
    }
}

/// Versão em memória para as prévias do Xcode.
final class PreviewAppIconService: AppIconService {
    var currentIconName: String?
    let supportsAlternateIcons = true

    func setIcon(named name: String?) async throws {
        currentIconName = name
    }
}
