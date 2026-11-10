//
//  APIClient.swift
//  ios
//

import Foundation

enum APIError: LocalizedError, Sendable {
    case badURL
    case http(Int, String?)
    case decoding

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid API URL."
        case .http(let code, let message):
            if let message, !message.isEmpty { return message }
            if code == 401 { return "Invalid email or password." }
            if code == 502 || code == 503 || code == 504 {
                return "Club API is temporarily unavailable (\(code)). Try again in a moment."
            }
            return "Server error (\(code))."
        case .decoding: return "Could not read the server response."
        }
    }
}

@MainActor
final class APIClient {
    static let shared = APIClient()

    var authToken: String?

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generatePlan(_ input: PlannerInput) async -> EventPlan {
        do {
            return try await post(path: "/api/generate-plan", body: input, authed: false)
        } catch {
            return Self.fallbackPlan(for: input)
        }
    }

    func submitLead(_ payload: LeadPayload) async -> LeadResult {
        do {
            return try await post(path: "/api/leads", body: payload, authed: true)
        } catch {
            return LeadResult(
                ok: false,
                id: "",
                message: (error as? LocalizedError)?.errorDescription
                    ?? "Could not reach the planner API. Check Wi‑Fi and that Docker is running on your Mac."
            )
        }
    }

    func register(name: String, email: String, password: String) async throws -> AuthSessionResponse {
        struct Body: Encodable { var name: String; var email: String; var password: String }
        return try await post(path: "/api/auth/register", body: Body(name: name, email: email, password: password), authed: false, as: AuthSessionResponse.self)
    }

    func login(email: String, password: String) async throws -> AuthSessionResponse {
        struct Body: Encodable { var email: String; var password: String }
        return try await post(path: "/api/auth/login", body: Body(email: email, password: password), authed: false, as: AuthSessionResponse.self)
    }

    struct OtpRequestResult: Decodable {
        var ok: Bool?
        var message: String
        var expiresInSec: Int?
        var devCode: String?
        var otpTicket: String?
    }

    func requestOtp(email: String) async throws -> OtpRequestResult {
        struct Body: Encodable { var email: String }
        return try await post(path: "/api/auth/otp/request", body: Body(email: email), authed: false, as: OtpRequestResult.self)
    }

    func verifyOtp(email: String, code: String, password: String? = nil, name: String? = nil, otpTicket: String? = nil) async throws -> AuthSessionResponse {
        struct Body: Encodable {
            var email: String
            var code: String
            var password: String?
            var name: String?
            var otpTicket: String?
        }
        return try await post(
            path: "/api/auth/otp/verify",
            body: Body(email: email, code: code, password: password, name: name, otpTicket: otpTicket),
            authed: false,
            as: AuthSessionResponse.self
        )
    }

    func socialSignIn(
        provider: String,
        email: String? = nil,
        name: String? = nil,
        idToken: String? = nil,
        subject: String? = nil
    ) async throws -> AuthSessionResponse {
        struct Body: Encodable {
            var provider: String
            var email: String?
            var name: String?
            var idToken: String?
            var subject: String?
        }
        return try await post(
            path: "/api/auth/social",
            body: Body(provider: provider, email: email, name: name, idToken: idToken, subject: subject),
            authed: false,
            as: AuthSessionResponse.self
        )
    }

    func fetchMe() async throws -> AuthUser {
        try await get(path: "/api/auth/me", as: MeResponse.self).user
    }

    func updateProfile(name: String) async throws -> AuthUser {
        struct Body: Encodable { var name: String }
        let res: MeResponse = try await send(
            path: "/api/auth/me",
            method: "PATCH",
            bodyData: try encoder.encode(Body(name: name)),
            authed: true
        )
        return res.user
    }

    func fetchClub() async throws -> ClubSummary {
        let res = try await get(path: "/api/club", as: ClubResponse.self)
        return ClubSummary(
            points: res.points,
            creditUsd: res.creditUsd,
            redeemRate: res.redeemRate,
            history: res.history
        )
    }

    func savePlan(plan: EventPlan, input: PlannerInput) async throws -> SavePlanResponse {
        struct Body: Encodable {
            var plan: EventPlan
            var input: PlannerInput
            var title: String
        }
        return try await post(
            path: "/api/plans",
            body: Body(plan: plan, input: input, title: plan.title),
            authed: true,
            as: SavePlanResponse.self
        )
    }

    func listWishlist() async throws -> [WishlistItem] {
        try await get(path: "/api/wishlist", as: WishlistListResponse.self).items
    }

    func addWishlist(label: String, locationType: String, notes: String? = nil) async throws -> WishlistItem {
        struct Body: Encodable {
            var label: String
            var locationType: String
            var notes: String?
        }
        return try await post(
            path: "/api/wishlist",
            body: Body(label: label, locationType: locationType, notes: notes),
            authed: true,
            as: WishlistItemResponse.self
        ).item
    }

    func removeWishlist(id: String) async throws {
        _ = try await send(path: "/api/wishlist/\(id)", method: "DELETE", bodyData: nil, authed: true) as OkOnly
    }

    func listInquiries() async throws -> [InquiryRecord] {
        try await get(path: "/api/inquiries", as: InquiriesResponse.self).inquiries
    }

    func updateInquiryStatus(id: String, status: ConsultStatus) async throws -> InquiryStatusResponse {
        struct Body: Encodable { var status: ConsultStatus }
        return try await send(
            path: "/api/inquiries/\(id)/status",
            method: "PATCH",
            bodyData: try encoder.encode(Body(status: status)),
            authed: true
        )
    }

    func listVault() async throws -> [VaultDoc] {
        try await get(path: "/api/vault", as: VaultResponse.self).documents
    }

    func listInquiryGuests(inquiryId: String) async throws -> GuestsListResponse {
        try await get(path: "/api/inquiries/\(inquiryId)/guests", as: GuestsListResponse.self)
    }

    func addInquiryGuest(inquiryId: String, name: String, email: String) async throws -> AddGuestResponse {
        struct Body: Encodable { var name: String; var email: String }
        return try await send(
            path: "/api/inquiries/\(inquiryId)/guests",
            method: "POST",
            bodyData: try encoder.encode(Body(name: name, email: email)),
            authed: true
        )
    }

    struct NearbyVenuesPayload: Decodable {
        var ok: Bool?
        var countryCode: String
        var countryName: String
        var venues: [NearbyVenueDTO]
        var source: String?
    }

    struct NearbyVenueDTO: Decodable {
        var id: String
        var name: String
        var localCategory: String
        var city: String
        var countryCode: String
        var mapQuery: String?
        var tag: String?
        var imageUrl: String?

        func toCurated() -> CuratedVenue? {
            guard let cat = LocalCategory(rawValue: localCategory) else { return nil }
            return CuratedVenue(
                id: id,
                name: name,
                localCategory: cat,
                city: city,
                countryCode: countryCode,
                mapQuery: mapQuery ?? name,
                tag: tag,
                imageUrl: imageUrl
            )
        }
    }

    /// GPS-scoped venues — API first, embedded catalog fallback.
    func fetchNearbyVenues(country: String?, city: String?) async -> (countryCode: String, countryName: String, venues: [CuratedVenue]) {
        var components = URLComponents(string: AppConfig.apiBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/api/venues/nearby")
        var items: [URLQueryItem] = []
        if let country, !country.isEmpty { items.append(URLQueryItem(name: "country", value: country)) }
        if let city, !city.isEmpty { items.append(URLQueryItem(name: "city", value: city)) }
        components?.queryItems = items.isEmpty ? nil : items
        if let url = components?.url {
            do {
                var req = URLRequest(url: url)
                req.httpMethod = "GET"
                let (data, response) = try await URLSession.shared.data(for: req)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    let payload = try decoder.decode(NearbyVenuesPayload.self, from: data)
                    let venues = payload.venues.compactMap { $0.toCurated() }
                    if !venues.isEmpty {
                        return (payload.countryCode, payload.countryName, venues)
                    }
                }
            } catch {
                // fall through to embedded
            }
        }
        return VenuesCatalog.resolve(countryCode: country, city: city)
    }

    /// Overseas Explore — day-seeded trending order (API with local day-seed fallback).
    func fetchTrendingDestinations() async -> (day: String, label: String, destinations: [ExploreDestination]) {
        let path = AppConfig.apiBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            + "/api/explore/destinations"
        if let url = URL(string: path) {
            do {
                var req = URLRequest(url: url)
                req.httpMethod = "GET"
                req.timeoutInterval = 20
                let (data, response) = try await URLSession.shared.data(for: req)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    let payload = try decoder.decode(TrendingDestinationsPayload.self, from: data)
                    let mapped = payload.destinations.map {
                        DestinationsCatalog.fromAPI(
                            id: $0.id,
                            name: $0.name,
                            region: $0.region,
                            blurb: $0.blurb,
                            locationName: $0.locationName,
                            imageKey: $0.imageKey,
                            score: $0.score
                        )
                    }
                    if !mapped.isEmpty {
                        return (payload.day, payload.label, mapped)
                    }
                }
            } catch {
                // fall through
            }
        }
        return DestinationsCatalog.trendingToday()
    }

    private struct TrendingDestinationsPayload: Decodable {
        var day: String
        var label: String
        var destinations: [TrendingDestinationRow]
    }

    private struct TrendingDestinationRow: Decodable {
        var id: String
        var name: String
        var region: String
        var blurb: String
        var locationName: String
        var imageKey: String
        var score: Int
    }

    private struct OkOnly: Decodable { var ok: Bool? }

    private func get<Response: Decodable>(path: String, as _: Response.Type = Response.self) async throws -> Response {
        try await send(path: path, method: "GET", bodyData: nil, authed: true)
    }

    private func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        authed: Bool,
        as _: Response.Type = Response.self
    ) async throws -> Response {
        try await send(path: path, method: "POST", bodyData: try encoder.encode(body), authed: authed)
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        bodyData: Data?,
        authed: Bool
    ) async throws -> Response {
        guard var components = URLComponents(url: AppConfig.apiBaseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.badURL
        }
        components.path = path.hasPrefix("/") ? path : "/\(path)"
        guard let url = components.url else { throw APIError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MeridianAtelieriOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 45
        if authed, let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = bodyData

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.http(-1, nil) }
        if !(200..<300).contains(http.statusCode) {
            if let parsed = try? decoder.decode(ErrorBody.self, from: data),
               let message = parsed.error, !message.isEmpty {
                throw APIError.http(http.statusCode, message)
            }
            let raw = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if raw.localizedCaseInsensitiveContains("FUNCTION_INVOCATION_FAILED") {
                throw APIError.http(http.statusCode, "Club API failed to start on the server. Redeploy the web API, then try again.")
            }
            if !raw.isEmpty, raw.count < 180, !raw.hasPrefix("<!") {
                throw APIError.http(http.statusCode, raw)
            }
            throw APIError.http(http.statusCode, nil)
        }
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private struct ErrorBody: Decodable { var error: String? }

    static func fallbackPlan(for input: PlannerInput) -> EventPlan {
        let isLocal = input.eventType == .local
        let location = input.locationName.isEmpty
            ? (isLocal ? "Heritage Coastal Estate" : "Santorini Cliffside Sanctuary")
            : input.locationName

        return EventPlan(
            title: isLocal ? "Curated Local Celebration Blueprint" : "Destination Horizon Proposal",
            tagline: "A Meridian proposal for \(input.guestCount) guests · \(input.targetMonth)",
            location: location,
            estimatedBudgetRange: input.guestCount > 150 ? "$45,000 – $95,000" : "$18,000 – $45,000",
            itinerary: [
                .init(time: "3:00 PM", activity: "Guest Arrival & Welcome", description: "Champagne greeting and soft acoustic ambience."),
                .init(time: "4:30 PM", activity: "Ceremony / Keynote Moment", description: "Primary gathering framed by floral architecture."),
                .init(time: "6:00 PM", activity: "Cocktail Hour", description: "Canapés and signature drinks on terrace."),
                .init(time: "7:30 PM", activity: "Seated Celebration Dinner", description: "\(input.cateringStyle.label) for \(input.guestCount) guests."),
                .init(time: "10:00 PM", activity: "Late Evening Send-Off", description: "Dessert station and curated exit moment."),
            ],
            cateringMenu: [
                .init(category: "Appetizers", name: "Garden Crudo Selection", description: "Seasonal citrus, herbs, and artisan oils."),
                .init(category: "Mains", name: "Herb-Crusted Catch or Local Roast", description: "Dual entrée for mixed dietary notes."),
                .init(category: "Desserts", name: "Champagne Sabayon & Berries", description: "Light finish with edible florals."),
            ],
            message: .init(
                invitationSubject: "You're invited — \(location)",
                invitationBody: "Dear Guest,\n\nWe would be honored by your presence at our \(input.targetMonth) celebration in \(location).\n\nWith warmth,\nYour Hosts",
                rsvpDeadlineNote: "Kindly RSVP within 21 days."
            ),
            weatherForecast: .init(
                conditions: "Mild & clear",
                temperatureAvg: "24°C",
                advice: "Ideal for outdoor segments with light evening wrap recommended.",
                indoorContingencyNeeded: false,
                contingencyPlan: "Adjacent salon held on soft hold for wind or rain."
            ),
            eventChecklist: [
                "Confirm guest count and dietary matrix",
                "Lock ceremony / reception floor plan",
                "Finalize floral & lighting mood board",
                "Schedule rehearsal walkthrough",
                "Issue vendor call sheet",
            ],
            generationSource: "fallback"
        )
    }
}
