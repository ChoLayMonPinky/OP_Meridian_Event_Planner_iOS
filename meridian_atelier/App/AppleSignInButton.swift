//
//  AppleSignInButton.swift
//  ios
//

import AuthenticationServices
import SwiftUI

struct AppleSignInButton: View {
    var onResult: (Result<AppleSignInPayload, Error>) -> Void

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    onResult(.failure(APIError.decoding))
                    return
                }
                let token = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
                let nameParts = [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                onResult(.success(AppleSignInPayload(
                    identityToken: token,
                    email: credential.email,
                    name: nameParts.isEmpty ? nil : nameParts,
                    subject: credential.user
                )))
            case .failure(let error):
                onResult(.failure(error))
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(MeridianTheme.ink.opacity(0.12), lineWidth: 1)
        )
    }
}

struct AppleSignInPayload {
    var identityToken: String?
    var email: String?
    var name: String?
    var subject: String
}
