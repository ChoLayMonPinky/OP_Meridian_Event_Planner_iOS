//
//  ClubGuestPanel.swift
//  ios
//
//  Live guest list + invite links for Club consults.
//

import SwiftUI
import UIKit

struct ClubGuestPanel: View {
    let inquiry: InquiryRecord

    @State private var guests: [EventGuest] = []
    @State private var name = ""
    @State private var email = ""
    @State private var inviteUrl: String?
    @State private var error: String?
    @State private var busy = false

    private var canSubmit: Bool {
        !busy
            && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && email.contains("@")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image("DestCliff")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(inquiry.planTitle ?? "Planner consult")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundStyle(MeridianTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(inquiry.status.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(MeridianTheme.atlantic)
                }
                Spacer(minLength: 0)
            }

            TextField("Guest name", text: $name)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
                        .allowsHitTesting(false)
                )

            TextField("Guest email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
                        .allowsHitTesting(false)
                )

            Button {
                Task { await addGuest() }
            } label: {
                Text(busy ? "Creating invite…" : "Add guest & create invite")
                    .font(.system(size: 13, weight: .semibold))
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
            .opacity(canSubmit ? 1 : 0.45)
            .disabled(!canSubmit)
            if let error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.8))
            }

            if let inviteUrl {
                VStack(alignment: .leading, spacing: 8) {
                    Text("INVITE LINK")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(MeridianTheme.ink.opacity(0.45))
                    Text(inviteUrl)
                        .font(.system(size: 12))
                        .foregroundStyle(MeridianTheme.ink)
                        .textSelection(.enabled)
                        .lineLimit(3)
                    HStack(spacing: 16) {
                        Button("Copy link") {
                            UIPasteboard.general.string = inviteUrl
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MeridianTheme.atlantic)
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())

                        ShareLink(item: inviteUrl) {
                            Text("Share")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MeridianTheme.atlantic)
                                .contentShape(Rectangle())
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(MeridianTheme.atlantic.opacity(0.06))
                )
            }

            if guests.isEmpty {
                Text("No guests yet — add the first invite above.")
                    .font(.system(size: 12))
                    .foregroundStyle(MeridianTheme.ink.opacity(0.45))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(guests.enumerated()), id: \.element.id) { index, guest in
                        if index > 0 {
                            Divider().opacity(0.35)
                        }
                        guestRow(guest)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
                .fill(MeridianTheme.paper.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
                .stroke(MeridianTheme.ink.opacity(0.08), lineWidth: 1)
                .allowsHitTesting(false)
        )
        .task(id: inquiry.id) {
            await loadGuests()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { break }
                await loadGuests(silent: true)
            }
        }
    }

    private func guestRow(_ guest: EventGuest) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(MeridianTheme.atlantic.opacity(0.12))
                .frame(width: 34, height: 34)
                .overlay(
                    Text(String(guest.name.prefix(1)).uppercased())
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(MeridianTheme.atlantic)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(guest.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MeridianTheme.ink)
                Text(guest.email)
                    .font(.system(size: 11))
                    .foregroundStyle(MeridianTheme.ink.opacity(0.45))
            }
            Spacer(minLength: 8)
            Text(guest.rsvpStatus.replacingOccurrences(of: "_", with: " ").uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(rsvpColor(guest.rsvpStatus))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(rsvpColor(guest.rsvpStatus).opacity(0.12))
                )
        }
        .padding(.vertical, 10)
    }

    private func rsvpColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "accepted", "yes", "attending":
            return MeridianTheme.atlantic
        case "declined", "no":
            return Color.red.opacity(0.75)
        default:
            return MeridianTheme.ink.opacity(0.55)
        }
    }

    private func loadGuests(silent: Bool = false) async {
        do {
            let res = try await APIClient.shared.listInquiryGuests(inquiryId: inquiry.id)
            guests = res.guests
        } catch {
            if !silent {
                self.error = error.localizedDescription
            }
        }
    }

    private func addGuest() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, trimmedEmail.contains("@") else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            let res = try await APIClient.shared.addInquiryGuest(
                inquiryId: inquiry.id,
                name: trimmedName,
                email: trimmedEmail
            )
            guests.insert(res.guest, at: 0)
            inviteUrl = res.inviteUrl
            name = ""
            email = ""
        } catch {
            self.error = error.localizedDescription
        }
    }
}
