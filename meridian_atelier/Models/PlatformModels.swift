//
//  PlatformModels.swift
//  ios
//

import Foundation

struct AuthUser: Codable, Equatable {
    var id: String
    var email: String
    var name: String
    var points: Int
    var creditUsd: Int
    var createdAt: String
}

struct AuthSessionResponse: Codable {
    var ok: Bool?
    var user: AuthUser
    var token: String
}

struct MeResponse: Codable {
    var ok: Bool?
    var user: AuthUser
}

struct ClubLedgerEntry: Codable, Identifiable {
    var id: String
    var userId: String
    var delta: Int
    var reason: String
    var createdAt: String
    var balanceAfter: Int
}

struct ClubSummary: Codable {
    var points: Int
    var creditUsd: Int
    var redeemRate: Int
    var history: [ClubLedgerEntry]
}

struct ClubResponse: Codable {
    var ok: Bool?
    var points: Int
    var creditUsd: Int
    var redeemRate: Int
    var history: [ClubLedgerEntry]
}

enum ConsultStatus: String, Codable, CaseIterable, Identifiable {
    case received, assigned, call_scheduled, deposit, completed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .received: return "Received"
        case .assigned: return "Planner assigned"
        case .call_scheduled: return "Call scheduled"
        case .deposit: return "Deposit stage"
        case .completed: return "Celebration complete"
        }
    }
}

struct WishlistItem: Codable, Identifiable {
    var id: String
    var userId: String
    var label: String
    var locationType: String
    var notes: String?
    var createdAt: String
}

struct InquiryRecord: Codable, Identifiable {
    var id: String
    var name: String
    var email: String
    var location: String?
    var planTitle: String?
    var status: ConsultStatus
    var pointsRedeemed: Int
    var creditAppliedUsd: Int
    var createdAt: String
    var updatedAt: String
}

struct VaultDoc: Codable, Identifiable {
    var id: String
    var title: String
    var kind: String
    var summary: String
    var createdAt: String
}

struct EventGuest: Codable, Identifiable {
    var id: String
    var inquiryId: String
    var name: String
    var email: String
    var rsvpStatus: String
    var inviteToken: String
    var hasAllergy: Bool?
    var allergyNote: String?
    var eventTitle: String?
    var eventLocation: String?
    var createdAt: String?
    var updatedAt: String?
}

struct GuestsListResponse: Codable {
    var ok: Bool?
    var guests: [EventGuest]
    var unlocked: Bool?
}

struct AddGuestResponse: Codable {
    var ok: Bool?
    var guest: EventGuest
    var inviteUrl: String
}

struct SavePlanResponse: Codable {
    var ok: Bool?
    var plan: SavedPlanStub?
    var club: ClubSummary
}

struct SavedPlanStub: Codable {
    var id: String
    var title: String
}

struct WishlistListResponse: Codable {
    var ok: Bool?
    var items: [WishlistItem]
}

struct WishlistItemResponse: Codable {
    var ok: Bool?
    var item: WishlistItem
}

struct InquiriesResponse: Codable {
    var ok: Bool?
    var inquiries: [InquiryRecord]
}

struct InquiryStatusResponse: Codable {
    var ok: Bool?
    var inquiry: InquiryRecord
    var club: ClubSummary
}

struct VaultResponse: Codable {
    var ok: Bool?
    var documents: [VaultDoc]
}
