//
//  EventModels.swift
//  ios
//

import Foundation

enum EventType: String, Codable, CaseIterable, Identifiable {
    case local
    case overseas
    var id: String { rawValue }
    var label: String { self == .local ? "Local" : "Overseas" }
}

enum LocalCategory: String, Codable, CaseIterable, Identifiable {
    case resort, beach, hotel, restaurant
    var id: String { rawValue }
    var label: String {
        switch self {
        case .resort: return "Resort"
        case .beach: return "Beach"
        case .hotel: return "Hotel"
        case .restaurant: return "Dining"
        }
    }
}

enum OverseasCategory: String, Codable, CaseIterable, Identifiable {
    case wedding_ceremony
    case hotel
    case air_ticket
    var id: String { rawValue }
    var label: String {
        switch self {
        case .wedding_ceremony: return "Ceremony & banquet"
        case .hotel: return "Stays"
        case .air_ticket: return "Travel"
        }
    }
}

enum CateringStyle: String, Codable, CaseIterable, Identifiable {
    case fine_dining, buffet, cocktail_reception, themed_bbq, traditional_banquet
    var id: String { rawValue }
    var label: String {
        switch self {
        case .fine_dining: return "Fine dining"
        case .buffet: return "Curated buffet"
        case .cocktail_reception: return "Cocktail reception"
        case .themed_bbq: return "Artisanal BBQ"
        case .traditional_banquet: return "Traditional banquet"
        }
    }
}

enum MessageStyle: String, Codable, CaseIterable, Identifiable {
    case romantic, formal, modern_minimalist, warm_festive
    var id: String { rawValue }
    var label: String {
        switch self {
        case .romantic: return "Romantic"
        case .formal: return "Formal"
        case .modern_minimalist: return "Minimal"
        case .warm_festive: return "Festive"
        }
    }
}

struct PlannerInput: Codable, Equatable {
    var eventType: EventType
    var localCategory: LocalCategory?
    var overseasCategory: OverseasCategory?
    var guestCount: Int
    var locationName: String
    var cateringStyle: CateringStyle
    var messageStyle: MessageStyle
    var targetMonth: String
    var specialNotes: String?

    static let months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]

    static func starter(eventType: EventType = .overseas) -> PlannerInput {
        PlannerInput(
            eventType: eventType,
            localCategory: eventType == .local ? .resort : nil,
            overseasCategory: eventType == .overseas ? .wedding_ceremony : nil,
            guestCount: 100,
            locationName: eventType == .overseas ? "Santorini, Greece" : "Local Premium Venue",
            cateringStyle: .fine_dining,
            messageStyle: .romantic,
            targetMonth: "September",
            specialNotes: nil
        )
    }
}

struct ItineraryItem: Codable, Equatable, Identifiable {
    var id: String
    var time: String
    var activity: String
    var description: String

    init(time: String, activity: String, description: String, id: String = UUID().uuidString) {
        self.id = id
        self.time = time
        self.activity = activity
        self.description = description
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        time = try c.decode(String.self, forKey: .time)
        activity = try c.decode(String.self, forKey: .activity)
        description = try c.decode(String.self, forKey: .description)
    }
}

struct MenuItem: Codable, Equatable, Identifiable {
    var id: String { "\(category)-\(name)" }
    var category: String
    var name: String
    var description: String
}

struct PlanMessage: Codable, Equatable {
    var invitationSubject: String
    var invitationBody: String
    var rsvpDeadlineNote: String
}

struct WeatherForecast: Codable, Equatable {
    var conditions: String
    var temperatureAvg: String
    var advice: String
    var indoorContingencyNeeded: Bool
    var contingencyPlan: String
}

struct EventPlan: Codable, Equatable, Identifiable {
    var id: String { title + location }
    var title: String
    var tagline: String
    var location: String
    var estimatedBudgetRange: String
    var itinerary: [ItineraryItem]
    var cateringMenu: [MenuItem]
    var message: PlanMessage
    var weatherForecast: WeatherForecast
    var eventChecklist: [String]
    var generationSource: String?
}

struct LeadPayload: Codable {
    var name: String
    var email: String
    var phone: String?
    var location: String?
    var date: String?
    var budget: String?
    var vision: String?
    var planTitle: String?
    var planTagline: String?
    var redeemPoints: Int?
}

struct LeadResult: Codable {
    var ok: Bool
    var id: String
    var message: String
    var status: String?
    var pointsRedeemed: Int?
    var creditAppliedUsd: Int?
    var club: ClubSummary?
}

struct StoredPlanBundle: Codable {
    var plan: EventPlan
    var input: PlannerInput
    var savedAt: Date
}
