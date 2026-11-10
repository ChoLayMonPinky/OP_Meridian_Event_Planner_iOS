//
//  ClubView.swift
//  ios
//

import SwiftUI
import AuthenticationServices
import UIKit

struct ClubView: View {
    @Environment(AuthStore.self) private var auth

    @State private var mode: AuthMode = .signIn
    @State private var step: JoinStep = .credentials
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var otpCode = ""
    @State private var otpHint: String?
    @State private var otpTicket: String?
    @State private var error: String?
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var confirmPasswordError: String?
    @State private var nameError: String?
    @State private var otpError: String?
    @State private var busy = false
    @State private var pane: Pane = .overview
    @State private var wishlist: [WishlistItem] = []
    @State private var inquiries: [InquiryRecord] = []
    @State private var vault: [VaultDoc] = []
    @State private var wishLabel = ""
    @State private var wishType = "overseas"
    @State private var showSocialSheet = false
    @State private var socialProvider: SocialProvider = .google
    @State private var socialEmailDraft = ""
    @State private var showFaceIDPrompt = false
    @State private var settingsNote: String?
    @State private var profileName = ""
    @State private var profileSaving = false
    @State private var unlockAttempted = false

    private enum AuthMode { case signIn, join }
    /// Join only: credentials → OTP. Sign in stays on credentials.
    private enum JoinStep { case credentials, otp }
    private enum Pane: String, CaseIterable { case overview, status, guests, wishlist, vault, settings }
    private enum SocialProvider { case google, apple }

    var body: some View {
        ZStack {
            if !auth.ready {
                ProgressView("Loading Club…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            } else if auth.faceIDEnabled && !auth.isUnlocked {
                faceIDUnlock
                    .transition(.opacity.combined(with: .offset(y: 10)))
            } else if auth.user == nil || !auth.isUnlocked {
                authForm
                    .transition(.opacity)
            } else {
                memberContent
                    .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
        .animation(MeridianMotion.soft, value: auth.ready)
        .animation(MeridianMotion.soft, value: auth.isUnlocked)
        .animation(MeridianMotion.soft, value: auth.user?.id)
        .background(Color.clear)
        .onChange(of: auth.user?.id) { _, newId in
            if let newId, auth.isUnlocked {
                startInquiryRealtime(userId: newId)
            } else {
                InquiryRealtimeService.shared.stop()
            }
        }
        .onChange(of: auth.isUnlocked) { _, unlocked in
            if unlocked, let id = auth.user?.id {
                startInquiryRealtime(userId: id)
            } else if !unlocked {
                InquiryRealtimeService.shared.stop()
            }
        }
        .onChange(of: auth.pendingFaceIDEnrollment) { _, pending in
            if pending { showFaceIDPrompt = true }
        }
        .alert("Add \(auth.biometryLabel)?", isPresented: $showFaceIDPrompt) {
            Button("Not now", role: .cancel) { auth.skipFaceIDEnrollment() }
            Button("Add \(auth.biometryLabel)") {
                Task { await enrollFaceID() }
            }
        } message: {
            Text("Optional. You can also turn this on later in Club → Settings.")
        }
        .sheet(isPresented: $showSocialSheet) {
            NavigationStack {
                Form {
                    TextField(
                        socialProvider == .apple ? "Apple email" : "Google email",
                        text: $socialEmailDraft
                    )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    Text(
                        socialProvider == .apple
                            ? "Confirm the email for your Apple ID to enter Club."
                            : "Confirm the Google email for your Club account."
                    )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .navigationTitle(socialProvider == .apple ? "Continue with Apple" : "Continue with Google")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showSocialSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Continue") {
                            showSocialSheet = false
                            Task { await runSocial(provider: socialProvider, email: socialEmailDraft) }
                        }
                        .disabled(!isValidEmail(socialEmailDraft))
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
    }

    private var faceIDUnlock: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "faceid")
                .font(.system(size: 48))
                .foregroundStyle(MeridianTheme.atlantic)
            Text("Welcome back\(auth.user.map { ", \($0.name)" } ?? "")")
                .font(.system(size: 26, weight: .medium, design: .serif))
            Text("Unlock your Club session with \(auth.biometryLabel).")
                .font(.system(size: 14))
                .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                .multilineTextAlignment(.center)
            if let error {
                Text(error).font(.system(size: 13)).foregroundStyle(.red.opacity(0.8))
            }
            Button {
                Task { await unlockFaceID() }
            } label: {
                Text(busy ? "Looking…" : "Unlock with \(auth.biometryLabel)")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(MeridianTheme.paper)
            }
            .meridianGlassProminent(tint: MeridianTheme.ink)
            .disabled(busy)
            Button("Sign in with email instead") {
                auth.signOut()
            }
            .font(.system(size: 13))
            .foregroundStyle(MeridianTheme.ink.opacity(0.45))
            Spacer()
        }
        .padding(24)
        .task {
            guard !unlockAttempted else { return }
            unlockAttempted = true
            await unlockFaceID()
        }
    }

    private var authForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(title: "Atelier credit & perks")
                Text(mode == .join
                    ? "Create your account with email and password, verify with a one-time code, then optionally add \(auth.biometryLabel)."
                    : "Sign in with your email and password. Use \(auth.biometryLabel) if you’ve enabled it in Settings.")
                    .font(.system(size: 14))
                    .foregroundStyle(MeridianTheme.ink.opacity(0.6))

                AppleSignInButton { result in
                    switch result {
                    case .success(let payload):
                        Task { await completeAppleSignIn(payload) }
                    case .failure(let err):
                        let ns = err as NSError
                        // User cancel — stay on form; capability / Personal Team → email fallback
                        if ns.domain == ASAuthorizationError.errorDomain,
                           ns.code == ASAuthorizationError.canceled.rawValue {
                            return
                        }
                        socialProvider = .apple
                        socialEmailDraft = email
                        showSocialSheet = true
                    }
                }
                .disabled(busy)
                .opacity(busy ? 0.55 : 1)

                Button {
                    socialProvider = .google
                    socialEmailDraft = email
                    showSocialSheet = true
                } label: {
                    HStack(spacing: 10) {
                        GoogleMark()
                            .frame(width: 18, height: 18)
                        Text("Continue with Google")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(MeridianTheme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .meridianInputSurface()
                .disabled(busy)
                .opacity(busy ? 0.55 : 1)

                HStack {
                    Rectangle().fill(MeridianTheme.ink.opacity(0.1)).frame(height: 1)
                    Text("or email")
                        .font(.system(size: 11))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.4))
                    Rectangle().fill(MeridianTheme.ink.opacity(0.1)).frame(height: 1)
                }

                HStack(spacing: 4) {
                    MeridianModeTab("Sign in", selected: mode == .signIn) {
                        withAnimation(MeridianMotion.soft) {
                            mode = .signIn
                            step = .credentials
                        }
                        otpHint = nil
                        otpTicket = nil
                        clearFieldErrors()
                        error = nil
                    }
                    MeridianModeTab("Join", selected: mode == .join) {
                        withAnimation(MeridianMotion.soft) {
                            mode = .join
                            step = .credentials
                        }
                        otpHint = nil
                        otpTicket = nil
                        clearFieldErrors()
                        error = nil
                    }
                }
                .padding(4)
                .glassEffect(.regular, in: .capsule)

                Group {
                    if mode == .join, step == .otp {
                        Group {
                            Text(normalizedEmail(email))
                                .font(.system(size: 14))
                                .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                            field("Verification code", text: $otpCode, error: otpError)
                                .keyboardType(.numberPad)
                                .onChange(of: otpCode) { _, _ in otpError = nil }
                        }
                        .transition(.opacity.combined(with: .offset(y: 8)))
                    } else {
                        Group {
                            if mode == .join {
                                field("Name", text: $name, error: nameError)
                                    .textContentType(.name)
                                    .onChange(of: name) { _, _ in nameError = nil }
                            }
                            field("Email", text: $email, error: emailError)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .textContentType(mode == .signIn ? .username : .emailAddress)
                                .onChange(of: email) { _, _ in emailError = nil }
                            ClubSecureField(
                                title: "Password",
                                text: $password,
                                error: passwordError,
                                contentType: mode == .join ? .newPassword : .password
                            )
                            .onChange(of: password) { _, _ in passwordError = nil }
                            if mode == .join {
                                ClubSecureField(
                                    title: "Confirm password",
                                    text: $confirmPassword,
                                    error: confirmPasswordError,
                                    contentType: .newPassword
                                )
                                .onChange(of: confirmPassword) { _, _ in confirmPasswordError = nil }
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .animation(MeridianMotion.soft, value: mode)
                .animation(MeridianMotion.soft, value: step)

                if let otpHint {
                    Text(otpHint).font(.system(size: 13)).foregroundStyle(MeridianTheme.atlantic)
                }
                if let error {
                    Text(error).font(.system(size: 13)).foregroundStyle(.red.opacity(0.8))
                }

                Button(action: submitAuth) {
                    Text(busy ? "Please wait…" : authButtonTitle)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(MeridianTheme.paper)
                }
                .meridianGlassProminent(tint: MeridianTheme.ink)
                .disabled(busy)

                if mode == .join, step == .otp {
                    Button("Back to account details") {
                        step = .credentials
                        otpCode = ""
                        otpHint = nil
                        otpTicket = nil
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(MeridianTheme.ink.opacity(0.45))
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var authButtonTitle: String {
        if mode == .signIn { return "Sign in" }
        return step == .credentials ? "Continue to verification" : "Verify & create account"
    }

    private var memberContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(title: "Atelier credit & perks")

                VStack(alignment: .leading, spacing: 6) {
                    Label("Balance", systemImage: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(MeridianTheme.atlantic)
                    Text("\((auth.club?.points ?? auth.user?.points ?? 0).formatted()) pts")
                        .font(.system(size: 36, weight: .medium, design: .serif))
                    Text("≈ $\(auth.club?.creditUsd ?? auth.user?.creditUsd ?? 0) planning credit · 100 pts = $1")
                        .font(.system(size: 13))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
                        .fill(MeridianTheme.atlantic.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
                        .stroke(MeridianTheme.atlantic.opacity(0.18), lineWidth: 1)
                )

                // Fixed-height chip row — unbounded horizontal ScrollViews steal taps from panes below.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(Pane.allCases, id: \.self) { p in
                            Button {
                                guard pane != p else { return }
                                pane = p
                                Task { await loadPane(p) }
                            } label: {
                                Text(paneLabel(p))
                                    .font(.system(size: 12, weight: pane == p ? .semibold : .regular))
                                    .foregroundStyle(pane == p ? MeridianTheme.ink : MeridianTheme.ink.opacity(0.4))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .overlay(alignment: .bottom) {
                                        Rectangle()
                                            .fill(pane == p ? MeridianTheme.atlantic : Color.clear)
                                            .frame(height: 2)
                                    }
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, 8)
                }
                .frame(height: 40)
                .fixedSize(horizontal: false, vertical: true)

                Group {
                switch pane {
                case .overview:
                    ForEach((auth.club?.history ?? []).prefix(8)) { entry in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.reason).font(.system(size: 14))
                                Text(entry.createdAt).font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(entry.delta >= 0 ? "+" : "")\(entry.delta)")
                                .foregroundStyle(entry.delta >= 0 ? MeridianTheme.atlantic : MeridianTheme.ink.opacity(0.55))
                        }
                        Divider()
                    }
                    if (auth.club?.history ?? []).isEmpty {
                        clubEmptyState(
                            title: "Your activity starts here",
                            detail: "Save a plan or send an inquiry to begin earning atelier points."
                        )
                    }

                case .wishlist:
                    wishForm
                    if wishlist.isEmpty {
                        clubEmptyState(
                            title: "No wishes yet",
                            detail: "Capture a venue, city, or mood — we’ll keep it with your Club."
                        )
                    }
                    ForEach(wishlist) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.label).font(.system(size: 18, design: .serif))
                                Text(item.locationType.uppercased())
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Remove") {
                                Task {
                                    try? await APIClient.shared.removeWishlist(id: item.id)
                                    wishlist.removeAll { $0.id == item.id }
                                }
                            }
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                        .padding(12)
                        .contentShape(Rectangle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
                                .allowsHitTesting(false)
                        )
                    }

                case .status:
                    if inquiries.isEmpty {
                        clubEmptyState(
                            title: "No consults yet",
                            detail: "Inquire from a blueprint to track planner status here in real time."
                        )
                    }
                    ForEach(inquiries) { inq in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(inq.planTitle ?? "Planner consult")
                                .font(.system(size: 20, design: .serif))
                            Text(inq.status.label)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            FlowStatusButtons(current: inq.status) { status in
                                Task {
                                    if let result = try? await APIClient.shared.updateInquiryStatus(id: inq.id, status: status) {
                                        if let idx = inquiries.firstIndex(where: { $0.id == inq.id }) {
                                            inquiries[idx] = result.inquiry
                                        }
                                        auth.applyClub(result.club)
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
                                .allowsHitTesting(false)
                        )
                    }

                case .guests:
                    guestsPane

                case .vault:
                    if vault.isEmpty {
                        clubEmptyState(
                            title: "Vault is empty",
                            detail: "Synced proposals appear here when you save a plan to your Club account."
                        )
                    }
                    ForEach(vault) { doc in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(doc.kind.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(MeridianTheme.atlantic)
                            Text(doc.title).font(.system(size: 20, design: .serif))
                            Text(doc.summary).font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
                                .allowsHitTesting(false)
                        )
                    }

                case .settings:
                    settingsPane
                }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(pane)            }
            .padding(20)
            .padding(.bottom, 28)
        }
        .task {
            await auth.refreshClub()
            await loadPane(pane)
            if let id = auth.user?.id, auth.isUnlocked {
                startInquiryRealtime(userId: id)
            }
        }
        // Keep Realtime alive across tab switches; stop only on logout / lock (onChange above).
    }

    private var guestsPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            GuestMessagingView(
                compact: true,
                sampleEventTitle: inquiries.first?.planTitle
            )
            Text("LIVE GUEST LISTS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundStyle(MeridianTheme.ink.opacity(0.45))
                .padding(.top, 6)
            if inquiries.isEmpty {
                clubEmptyState(
                    title: "No consults yet",
                    detail: "Start a plan and open a Club consult — then invite guests and share links here."
                )
            }
            ForEach(inquiries) { inq in
                ClubGuestPanel(inquiry: inq)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var wishForm: some View {
        VStack(spacing: 10) {
            TextField("Venue, city, or mood…", text: $wishLabel)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.12), lineWidth: 1)
                        .allowsHitTesting(false)
                )

            HStack(spacing: 8) {
                ForEach(["overseas", "local"], id: \.self) { t in
                    Button {
                        wishType = t
                    } label: {
                        Text(t.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(wishType == t ? MeridianTheme.atlantic : MeridianTheme.ink.opacity(0.5))
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(wishType == t ? MeridianTheme.atlantic.opacity(0.08) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        wishType == t ? MeridianTheme.atlantic : MeridianTheme.ink.opacity(0.15),
                                        lineWidth: 1
                                    )
                                    .allowsHitTesting(false)
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                Task {
                    let label = wishLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !label.isEmpty else { return }
                    if let item = try? await APIClient.shared.addWishlist(label: label, locationType: wishType) {
                        wishlist.insert(item, at: 0)
                        wishLabel = ""
                    }
                }
            } label: {
                Label("Save to wishlist", systemImage: "heart")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(MeridianTheme.paper)
                    .background(
                        MeridianTheme.ink,
                        in: RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func header(title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Meridian Club")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.atlantic)
            Text(title)
                .font(.system(size: 24, weight: .medium, design: .serif))
        }
    }

    private var settingsPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.ink.opacity(0.45))

            VStack(alignment: .leading, spacing: 14) {
                field("Name", text: $profileName)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(MeridianTheme.ink.opacity(0.5))
                    Text(auth.user?.email ?? "")
                        .font(.system(size: 15))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.12), lineWidth: 1)
                )
                    Text("Email can’t be changed here.")
                        .font(.system(size: 12))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.4))
                }
                Button {
                    Task { await saveProfile() }
                } label: {
                    Text(profileSaving ? "Saving…" : "Save changes")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(MeridianTheme.paper)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(MeridianTheme.ink)
                        )
                }
                .buttonStyle(.plain)
                .disabled(profileSaving || profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || profileName.trimmingCharacters(in: .whitespacesAndNewlines) == (auth.user?.name ?? ""))
                .opacity(
                    profileSaving || profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || profileName.trimmingCharacters(in: .whitespacesAndNewlines) == (auth.user?.name ?? "")
                        ? 0.45 : 1
                )
            }
            .padding(14)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
            )

            Text("Security")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.ink.opacity(0.45))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(auth.biometryLabel)
                        .font(.system(size: 18, design: .serif))
                    Text(auth.canUseBiometrics
                        ? "Unlock Meridian Club with \(auth.biometryLabel) after you’ve signed in."
                        : "\(auth.biometryLabel) isn’t available on this device.")
                        .font(.system(size: 13))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                }
                Spacer()
                Toggle(
                    "",
                    isOn: Binding(
                        get: { auth.faceIDEnabled },
                        set: { enabled in
                            Task { await setFaceID(enabled) }
                        }
                    )
                )
                .labelsHidden()
                .tint(MeridianTheme.atlantic)
                .disabled(!auth.canUseBiometrics && !auth.faceIDEnabled)
            }
            .padding(14)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
            )

            if let settingsNote {
                Text(settingsNote)
                    .font(.system(size: 13))
                    .foregroundStyle(MeridianTheme.atlantic)
            }
            if let error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.8))
            }

            VStack(spacing: 0) {
                Divider().overlay(MeridianTheme.ink.opacity(0.08))
                Button {
                    auth.signOut()
                } label: {
                    Text("Sign out")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(MeridianTheme.ink)
                }
                .buttonStyle(.plain)
                .meridianGlassRegular()
            }
            .padding(.top, 8)
        }
        .onAppear {
            if profileName.isEmpty {
                profileName = auth.user?.name ?? ""
            }
        }
        .onChange(of: auth.user?.name) { _, newName in
            if let newName, !profileSaving {
                profileName = newName
            }
        }
    }

    private func saveProfile() async {
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profileSaving = true
        error = nil
        settingsNote = nil
        defer { profileSaving = false }
        do {
            try await auth.updateProfile(name: trimmed)
            settingsNote = "Profile saved."
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func paneLabel(_ pane: Pane) -> String {
        switch pane {
        case .overview: return "Activity"
        case .status: return "Consult"
        case .guests: return "Guests"
        case .wishlist: return "Wishlist"
        case .vault: return "Vault"
        case .settings: return "Settings"
        }
    }

    @ViewBuilder
    private func clubEmptyState(title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundStyle(MeridianTheme.ink)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.system(size: 14))
                .foregroundStyle(MeridianTheme.ink.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                .foregroundStyle(MeridianTheme.ink.opacity(0.12))
                .allowsHitTesting(false)
        )
        .transition(.opacity.combined(with: .offset(y: 6)))
    }

    private func setFaceID(_ enabled: Bool) async {
        error = nil
        settingsNote = nil
        if enabled {
            do {
                try await auth.enableFaceIDFromSettings()
                settingsNote = "\(auth.biometryLabel) is on."
            } catch {
                self.error = error.localizedDescription
            }
        } else {
            auth.disableFaceIDFromSettings()
            settingsNote = "\(auth.biometryLabel) is off. You’ll sign in with email next time."
        }
    }

    private func field(_ title: String, text: Binding<String>, error: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.ink.opacity(0.5))
            TextField("", text: text)
                .textFieldStyle(.plain)
                .padding(12)
                .meridianInputSurface(isError: error != nil)
            if let error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.8))
            }
        }
    }

    private func clearFieldErrors() {
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        nameError = nil
        otpError = nil
    }

    private func normalizedEmail(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = normalizedEmail(value)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    /// Returns false when client-side field validation fails.
    private func validateCredentials() -> Bool {
        clearFieldErrors()
        var ok = true

        if mode == .join, step == .credentials {
            if name.trimmingCharacters(in: .whitespaces).isEmpty {
                nameError = "Enter your name"
                ok = false
            }
        }

        if mode == .join, step == .otp {
            if otpCode.trimmingCharacters(in: .whitespaces).count < 4 {
                otpError = "Enter the verification code"
                ok = false
            }
            return ok
        }

        let trimmedEmail = normalizedEmail(email)
        if trimmedEmail.isEmpty {
            emailError = "Enter your email"
            ok = false
        } else if !isValidEmail(trimmedEmail) {
            emailError = "Enter a valid email"
            ok = false
        }

        if password.isEmpty {
            passwordError = "Enter your password"
            ok = false
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            ok = false
        }

        if mode == .join, step == .credentials {
            if confirmPassword.isEmpty {
                confirmPasswordError = "Confirm your password"
                ok = false
            } else if password != confirmPassword {
                confirmPasswordError = "Passwords do not match"
                ok = false
            }
        }

        return ok
    }

    private func submitAuth() {
        busy = true
        error = nil
        guard validateCredentials() else {
            busy = false
            return
        }
        Task {
            do {
                let currentEmail = normalizedEmail(email)
                if mode == .signIn {
                    try await auth.signIn(email: currentEmail, password: password)
                } else {
                    switch step {
                    case .credentials:
                        let res = try await auth.requestOtp(email: currentEmail)
                        otpTicket = res.otpTicket
                        otpHint = res.devCode.map { "Your verification code is \($0)." } ?? res.message
                        step = .otp
                    case .otp:
                        try await auth.completeRegistration(
                            email: currentEmail,
                            code: otpCode,
                            password: password,
                            name: name,
                            otpTicket: otpTicket
                        )
                        if auth.pendingFaceIDEnrollment {
                            showFaceIDPrompt = true
                        }
                    }
                }
            } catch {
                self.error = error.localizedDescription
            }
            busy = false
        }
    }

    private func unlockFaceID() async {
        busy = true
        error = nil
        do {
            try await auth.unlockWithFaceID()
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    private func enrollFaceID() async {
        busy = true
        error = nil
        do {
            try await auth.enrollFaceIDAfterSignIn()
        } catch {
            self.error = error.localizedDescription
            auth.skipFaceIDEnrollment()
        }
        busy = false
    }

    private func completeAppleSignIn(_ payload: AppleSignInPayload) async {
        busy = true
        error = nil
        do {
            try await auth.continueWithApple(
                email: payload.email ?? (isValidEmail(email) ? normalizedEmail(email) : nil),
                name: payload.name ?? (name.isEmpty ? nil : name),
                idToken: payload.identityToken,
                subject: payload.subject
            )
            if auth.pendingFaceIDEnrollment { showFaceIDPrompt = true }
        } catch {
            // First-time without email, Personal Team, or API error → email sheet
            self.error = error.localizedDescription
            socialProvider = .apple
            socialEmailDraft = payload.email ?? email
            showSocialSheet = true
        }
        busy = false
    }

    private func runSocial(provider: SocialProvider, email: String) async {
        let currentEmail = normalizedEmail(email)
        guard isValidEmail(currentEmail) else {
            self.error = "Enter a valid email"
            return
        }

        busy = true
        error = nil
        do {
            switch provider {
            case .google:
                try await auth.continueWithGoogle(email: currentEmail, name: name.isEmpty ? nil : name)
            case .apple:
                try await auth.continueWithApple(
                    email: currentEmail,
                    name: name.isEmpty ? nil : name,
                    idToken: nil,
                    subject: nil
                )
            }
            if auth.pendingFaceIDEnrollment { showFaceIDPrompt = true }
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    private func loadPane(_ target: Pane) async {
        guard let user = auth.user, auth.isUnlocked else { return }
        switch target {
        case .overview, .settings:
            break
        case .wishlist:
            wishlist = (try? await APIClient.shared.listWishlist()) ?? []
        case .status, .guests:
            if let remote = try? await APIClient.shared.listInquiries(), !remote.isEmpty {
                inquiries = remote
            } else {
                let fromSupabase = await InquiryRealtimeService.shared.fetchInquiries(userId: user.id)
                if !fromSupabase.isEmpty {
                    inquiries = fromSupabase
                } else if let remote = try? await APIClient.shared.listInquiries() {
                    inquiries = remote
                }
            }
        case .vault:
            vault = (try? await APIClient.shared.listVault()) ?? []
        }
    }

    private func startInquiryRealtime(userId: String) {
        InquiryRealtimeService.shared.start(userId: userId) { record in
            mergeInquiry(record)
            Task { await auth.refreshClub() }
        }
    }

    private func mergeInquiry(_ record: InquiryRecord) {
        let prior = inquiries.first(where: { $0.id == record.id })
        if let idx = inquiries.firstIndex(where: { $0.id == record.id }) {
            inquiries[idx] = record
        } else {
            inquiries.insert(record, at: 0)
        }
        let statusChanged = prior.map { $0.status != record.status } ?? (record.status != .received)
        if statusChanged {
            Task {
                await PushNotificationService.shared.sendConciergeAlert(
                    title: "Meridian Consult",
                    body: "Status updated: \(record.status.label)",
                    identifier: "meridian.consult.\(record.id)"
                )
            }
        }
    }
}

private struct ClubSecureField: View {
    let title: String
    @Binding var text: String
    var error: String? = nil
    var contentType: UITextContentType = .password
    @State private var visible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.ink.opacity(0.5))
            HStack(spacing: 0) {
                Group {
                    if visible {
                        TextField("", text: $text)
                    } else {
                        SecureField("", text: $text)
                    }
                }
                .textFieldStyle(.plain)
                .textContentType(contentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .frame(minHeight: 22)

                Button {
                    visible.toggle()
                } label: {
                    Image(systemName: visible ? "eye.slash" : "eye")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.4))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(visible ? "Hide password" : "Show password")
            }
            .padding(.leading, 12)
            .padding(.trailing, 4)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        error == nil ? MeridianTheme.ink.opacity(0.12) : Color.red.opacity(0.45),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
            if let error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.8))
            }
        }
    }
}

private struct FlowStatusButtons: View {
    let current: ConsultStatus
    var onSelect: (ConsultStatus) -> Void

    var body: some View {
        let options: [ConsultStatus] = [.assigned, .call_scheduled, .deposit, .completed]
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options) { status in
                    let selected = current == status
                    Button(status.label) { onSelect(status) }
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .foregroundStyle(selected ? MeridianTheme.paper : MeridianTheme.ink.opacity(0.6))
                        .background(selected ? MeridianTheme.ink.opacity(0.55) : MeridianTheme.ink.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(MeridianTheme.ink.opacity(selected ? 0 : 0.12), lineWidth: 1)
                                .allowsHitTesting(false)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .disabled(selected)
                        .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 36)
        .fixedSize(horizontal: false, vertical: true)
    }
}
