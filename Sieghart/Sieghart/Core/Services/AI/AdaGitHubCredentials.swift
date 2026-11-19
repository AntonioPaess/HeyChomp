import Foundation
import Security

protocol AdaGitHubCredentialStoring: Sendable {
    func load() async throws -> String?
    func save(_ token: String) async throws
    func clear() async throws
}

/// Owns only Sieg's GitHub credential. Initializing it never reads the Keychain.
actor KeychainAdaGitHubCredentials: AdaGitHubCredentialStoring {
    private let service = "com.heychomp.mac.github"
    /// Nome usado até 17/11/2026, quando o app ainda era `com.sieghart.app`.
    /// O token encontrado nele é movido para o nome novo na primeira leitura.
    private let legacyService = "com.sieghart.app.github"
    private let account = "personal-access-token"

    private var identity: [String: Any] { identity(service) }

    private func identity(_ service: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    func load() throws -> String? {
        if let token = try read(service) { return token }
        guard let legacy = try read(legacyService) else { return nil }
        try save(legacy)
        SecItemDelete(identity(legacyService) as CFDictionary)
        return legacy
    }

    private func read(_ service: String) throws -> String? {
        var query = identity(service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else { throw AdaGitHubError.credentialStorage }
        return token
    }

    func save(_ token: String) throws {
        let data = Data(token.utf8)
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(identity as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else { throw AdaGitHubError.credentialStorage }
        var item = identity
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw AdaGitHubError.credentialStorage }
    }

    func clear() throws {
        for item in [identity, identity(legacyService)] {
            let status = SecItemDelete(item as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw AdaGitHubError.credentialStorage }
        }
    }
}
