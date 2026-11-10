//
//  GuestMessagingView.swift
//  ios
//

import SwiftUI

/// Guest messaging intro for Club → Guests.
/// Live invites / RSVP live in guest list cards below — no phone preview mock.
struct GuestMessagingView: View {
    var compact: Bool = false
    /// Kept for call-site compatibility; unused after preview removal.
    var sampleEventTitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COMMUNICATION SUITE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundStyle(MeridianTheme.atlantic)

            Text("Bespoke Guest Messaging")
                .font(.system(size: 26, weight: .medium, design: .serif))
                .foregroundStyle(MeridianTheme.ink)

            Text("Add guests below to create invite links, collect RSVPs, and share logistics for each consult.")
                .font(.system(size: 14))
                .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, compact ? 0 : 24)
        .padding(.vertical, compact ? 0 : 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(compact ? Color.clear : MeridianTheme.paper)
    }
}
