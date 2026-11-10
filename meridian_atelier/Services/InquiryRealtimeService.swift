//
//  InquiryRealtimeService.swift
//  ios
//
//  Live Club Consult updates via postgres_changes + broadcast (matches web).
//

import Foundation
import Supabase

@MainActor
final class InquiryRealtimeService {
    static let shared = InquiryRealtimeService()

    private var listenTask: Task<Void, Never>?
    private var channels: [RealtimeChannelV2] = []
    private var activeUserId: String?

    private init() {}

    /// Hydrate inquiries from Supabase when Meridian API is unavailable.
    func fetchInquiries(userId: String) async -> [InquiryRecord] {
        guard let client = SupabaseManager.shared else { return [] }
        do {
            let rows: [InquiryRow] = try await client
                .from("inquiries")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            return rows.compactMap { $0.toRecord() }
        } catch {
            return []
        }
    }

    func start(userId: String, onUpdate: @escaping @MainActor (InquiryRecord) -> Void) {
        guard AppConfig.isSupabaseConfigured, SupabaseManager.shared != nil else { return }
        let taskAlive = listenTask.map { !$0.isCancelled } ?? false
        if activeUserId == userId, taskAlive { return }
        stop()
        activeUserId = userId

        listenTask = Task { [weak self] in
            guard let self, let client = SupabaseManager.shared else { return }

            let pg = client.channel("inquiries-pg:\(userId)")
            let bc = client.channel("club:\(userId)")
            await MainActor.run { self.channels = [pg, bc] }

            let changes = pg.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "inquiries",
                filter: .eq("user_id", value: userId)
            )
            let broadcasts = bc.broadcastStream(event: "inquiry")

            do {
                try await pg.subscribeWithError()
                try await bc.subscribeWithError()
            } catch {
                await MainActor.run {
                    self.listenTask = nil
                    self.activeUserId = nil
                }
                return
            }

            await withTaskGroup(of: Void.self) { group in
                group.addTask { @MainActor in
                    for await change in changes {
                        if Task.isCancelled { break }
                        let record: InquiryRecord?
                        switch change {
                        case .insert(let action):
                            record = (try? action.decodeRecord(as: InquiryRow.self, decoder: AnyJSON.decoder))?.toRecord()
                        case .update(let action):
                            record = (try? action.decodeRecord(as: InquiryRow.self, decoder: AnyJSON.decoder))?.toRecord()
                        case .delete:
                            record = nil
                        }
                        if let record {
                            onUpdate(record)
                        }
                    }
                }
                group.addTask { @MainActor in
                    for await payload in broadcasts {
                        if Task.isCancelled { break }
                        if let record = Self.decodeBroadcast(payload) {
                            onUpdate(record)
                        }
                    }
                }
            }

            await MainActor.run {
                if self.activeUserId == userId {
                    self.listenTask = nil
                }
            }
        }
    }

    func stop() {
        listenTask?.cancel()
        listenTask = nil
        activeUserId = nil
        let toRemove = channels
        channels = []
        guard let client = SupabaseManager.shared, !toRemove.isEmpty else { return }
        Task {
            for ch in toRemove {
                await client.removeChannel(ch)
            }
        }
    }

    private static func decodeBroadcast(_ payload: [String: AnyJSON]) -> InquiryRecord? {
        guard let inquiryJSON = payload["inquiry"] else { return nil }
        do {
            let data = try AnyJSON.encoder.encode(inquiryJSON)
            let raw = try AnyJSON.decoder.decode(BroadcastInquiry.self, from: data)
            return raw.toRecord()
        } catch {
            return nil
        }
    }
}

private struct BroadcastInquiry: Decodable {
    var id: String
    var name: String?
    var email: String?
    var location: String?
    var planTitle: String?
    var status: String
    var pointsRedeemed: Int?
    var creditAppliedUsd: Int?
    var createdAt: String?
    var updatedAt: String?

    func toRecord() -> InquiryRecord? {
        guard let status = ConsultStatus(rawValue: status) else { return nil }
        return InquiryRecord(
            id: id,
            name: name ?? "",
            email: email ?? "",
            location: location,
            planTitle: planTitle,
            status: status,
            pointsRedeemed: pointsRedeemed ?? 0,
            creditAppliedUsd: creditAppliedUsd ?? 0,
            createdAt: createdAt ?? "",
            updatedAt: updatedAt ?? ""
        )
    }
}
