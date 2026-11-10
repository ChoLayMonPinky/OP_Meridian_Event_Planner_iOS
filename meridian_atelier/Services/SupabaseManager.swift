//
//  SupabaseManager.swift
//  ios
//
//  Standalone Supabase client (publishable key). Used for Club Consult Realtime
//  and optional inquiry list when Meridian API is offline.
//

import Foundation
import Supabase

enum SupabaseManager {
    static let shared: SupabaseClient? = {
        guard AppConfig.isSupabaseConfigured else { return nil }
        return SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabasePublishableKey,
            options: .init(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }()
}

/// Row shape matching `public.inquiries` (snake_case from Postgres).
struct InquiryRow: Codable, Sendable {
    var id: String
    var user_id: String?
    var name: String
    var email: String
    var phone: String?
    var location: String?
    var date: String?
    var budget: String?
    var vision: String?
    var plan_title: String?
    var plan_tagline: String?
    var status: String
    var points_redeemed: Int
    var credit_applied_usd: Int
    var created_at: String
    var updated_at: String

    func toRecord() -> InquiryRecord? {
        guard let status = ConsultStatus(rawValue: status) else { return nil }
        return InquiryRecord(
            id: id,
            name: name,
            email: email,
            location: location,
            planTitle: plan_title,
            status: status,
            pointsRedeemed: points_redeemed,
            creditAppliedUsd: credit_applied_usd,
            createdAt: created_at,
            updatedAt: updated_at
        )
    }
}
