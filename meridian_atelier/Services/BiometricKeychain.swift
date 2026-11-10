//
//  BiometricKeychain.swift
//  ios
//

import Foundation
import LocalAuthentication
import Security

enum BiometricKeychain {
    private static let service = "dev.tintwym.meridian-atelier.auth"
    private static let account = "session"

    static var biometryAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        // Meridian iOS uses Face ID only (not fingerprint / Touch ID).
        return context.biometryType == .faceID || context.biometryType == .opticID
    }

    static var biometryLabel: String { "Face ID" }

    static func confirmBiometrics(reason: String) async throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error),
              context.biometryType == .faceID || context.biometryType == .opticID
        else {
            throw error ?? KeychainError.accessControl
        }
        try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
    }

    static func saveSessionToken(_ token: String) throws {
        deleteSessionToken()
        let data = Data(token.utf8)
        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &error
        ) else {
            throw error?.takeRetainedValue() as Error? ?? KeychainError.accessControl
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: access,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.status(status) }
    }

    static func loadSessionToken(reason: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let context = LAContext()
                context.localizedReason = reason
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecAttrAccount as String: account,
                    kSecReturnData as String: true,
                    kSecMatchLimit as String: kSecMatchLimitOne,
                    kSecUseAuthenticationContext as String: context,
                ]
                var item: CFTypeRef?
                let status = SecItemCopyMatching(query as CFDictionary, &item)
                guard status == errSecSuccess,
                      let data = item as? Data,
                      let token = String(data: data, encoding: .utf8)
                else {
                    continuation.resume(throwing: KeychainError.status(status))
                    return
                }
                continuation.resume(returning: token)
            }
        }
    }

    static func deleteSessionToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }

    enum KeychainError: LocalizedError {
        case accessControl
        case status(OSStatus)

        var errorDescription: String? {
            switch self {
            case .accessControl: return "Could not protect session with biometrics."
            case .status(let code): return "Keychain error (\(code))."
            }
        }
    }
}
