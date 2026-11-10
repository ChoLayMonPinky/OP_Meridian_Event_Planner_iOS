//
//  AuthStore.swift
//  ios
//

import Foundation
import Observation

@Observable
@MainActor
final class AuthStore {
    private let tokenKey = "meridian.auth.token"
    private let userKey = "meridian.auth.user"
    private let faceIDKey = "meridian.auth.faceIDEnabled"

    var user: AuthUser?
    var token: String?
    var club: ClubSummary?
    var ready = false
    /// When Face ID is on, session stays locked until biometrics succeed.
    var isUnlocked = false
    var faceIDEnabled: Bool {
        didSet { UserDefaults.standard.set(faceIDEnabled, forKey: faceIDKey) }
    }
    /// Optional prompt after successful registration OTP.
    var pendingFaceIDEnrollment = false

    var biometryLabel: String { BiometricKeychain.biometryLabel }
    /// Cached — LAContext checks are not free and can hitch the main thread.
    private(set) var canUseBiometrics: Bool = BiometricKeychain.biometryAvailable

    init() {
        faceIDEnabled = UserDefaults.standard.bool(forKey: faceIDKey)
        canUseBiometrics = BiometricKeychain.biometryAvailable
        if let data = UserDefaults.standard.data(forKey: userKey),
           let stored = try? JSONDecoder().decode(AuthUser.self, from: data) {
            user = stored
        }
        Task { await bootstrap() }
    }

    func bootstrap() async {
        defer { ready = true }

        if faceIDEnabled {
            token = nil
            APIClient.shared.authToken = nil
            isUnlocked = false
            return
        }

        guard let stored = UserDefaults.standard.string(forKey: tokenKey) else {
            if !faceIDEnabled { user = nil }
            isUnlocked = false
            return
        }
        await restoreSession(token: stored)
    }

    func unlockWithFaceID() async throws {
        let reason = "Unlock Meridian Club with \(biometryLabel)"
        let sessionToken = try await BiometricKeychain.loadSessionToken(reason: reason)
        await restoreSession(token: sessionToken)
        isUnlocked = true
    }

    /// Optional enroll after registration succeeds.
    func enrollFaceIDAfterSignIn() async throws {
        guard let token else { return }
        guard canUseBiometrics else {
            pendingFaceIDEnrollment = false
            isUnlocked = true
            return
        }
        try await BiometricKeychain.confirmBiometrics(
            reason: "Enable \(biometryLabel) to unlock Meridian Club next time"
        )
        try BiometricKeychain.saveSessionToken(token)
        faceIDEnabled = true
        isUnlocked = true
        pendingFaceIDEnrollment = false
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }

    func skipFaceIDEnrollment() {
        pendingFaceIDEnrollment = false
        isUnlocked = true
        if let token, let user {
            persist(token: token, user: user)
        }
    }

    /// Settings: turn Face ID on while already signed in.
    func enableFaceIDFromSettings() async throws {
        guard let token else { return }
        guard canUseBiometrics else {
            throw APIError.http(400, "\(biometryLabel) is not available on this device")
        }
        try await BiometricKeychain.confirmBiometrics(
            reason: "Enable \(biometryLabel) for Meridian Club"
        )
        try BiometricKeychain.saveSessionToken(token)
        faceIDEnabled = true
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }

    /// Settings: turn Face ID off; keep the session in normal storage.
    func disableFaceIDFromSettings() {
        faceIDEnabled = false
        BiometricKeychain.deleteSessionToken()
        if let token, let user {
            UserDefaults.standard.set(token, forKey: tokenKey)
            if let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: userKey)
            }
        }
    }

    private func restoreSession(token: String) async {
        APIClient.shared.authToken = token
        self.token = token
        do {
            let me = try await APIClient.shared.fetchMe()
            user = me
            if !faceIDEnabled {
                persist(token: token, user: me)
            } else if let data = try? JSONEncoder().encode(me) {
                UserDefaults.standard.set(data, forKey: userKey)
            }
            club = try? await APIClient.shared.fetchClub()
            isUnlocked = true
        } catch {
            signOut()
        }
    }

    func requestOtp(email: String) async throws -> APIClient.OtpRequestResult {
        try await APIClient.shared.requestOtp(email: email)
    }

    func signIn(email: String, password: String) async throws {
        let session = try await APIClient.shared.login(email: email, password: password)
        apply(session)
        club = try? await APIClient.shared.fetchClub()
        isUnlocked = true
        pendingFaceIDEnrollment = false
    }

    /// Join: after OTP, create account with password.
    func completeRegistration(email: String, code: String, password: String, name: String, otpTicket: String? = nil) async throws {
        let session = try await APIClient.shared.verifyOtp(
            email: email,
            code: code,
            password: password,
            name: name,
            otpTicket: otpTicket
        )
        apply(session)
        club = try? await APIClient.shared.fetchClub()
        isUnlocked = true
        if canUseBiometrics {
            pendingFaceIDEnrollment = true
        }
    }

    func continueWithGoogle(email: String, name: String? = nil, idToken: String? = nil) async throws {
        let session = try await APIClient.shared.socialSignIn(
            provider: "google",
            email: email,
            name: name,
            idToken: idToken
        )
        apply(session)
        club = try? await APIClient.shared.fetchClub()
        isUnlocked = true
        if canUseBiometrics { pendingFaceIDEnrollment = true }
    }

    func continueWithApple(email: String?, name: String?, idToken: String?, subject: String?) async throws {
        let session = try await APIClient.shared.socialSignIn(
            provider: "apple",
            email: email,
            name: name,
            idToken: idToken,
            subject: subject
        )
        apply(session)
        club = try? await APIClient.shared.fetchClub()
        isUnlocked = true
        if canUseBiometrics { pendingFaceIDEnrollment = true }
    }

    func signOut() {
        token = nil
        user = nil
        club = nil
        isUnlocked = false
        pendingFaceIDEnrollment = false
        faceIDEnabled = false
        APIClient.shared.authToken = nil
        BiometricKeychain.deleteSessionToken()
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    func refreshClub() async {
        guard token != nil, isUnlocked else { return }
        if let summary = try? await APIClient.shared.fetchClub() {
            club = summary
            if var user {
                user.points = summary.points
                user.creditUsd = summary.creditUsd
                self.user = user
                if let data = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(data, forKey: userKey)
                }
            }
        }
    }

    func applyClub(_ summary: ClubSummary) {
        club = summary
        if var user {
            user.points = summary.points
            user.creditUsd = summary.creditUsd
            self.user = user
            if let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: userKey)
            }
        }
    }

    func updateProfile(name: String) async throws {
        let next = try await APIClient.shared.updateProfile(name: name)
        user = next
        if let data = try? JSONEncoder().encode(next) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }

    private func apply(_ session: AuthSessionResponse) {
        token = session.token
        user = session.user
        APIClient.shared.authToken = session.token
        persist(token: session.token, user: session.user)
    }

    private func persist(token: String, user: AuthUser) {
        if !faceIDEnabled {
            UserDefaults.standard.set(token, forKey: tokenKey)
        }
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }
}
