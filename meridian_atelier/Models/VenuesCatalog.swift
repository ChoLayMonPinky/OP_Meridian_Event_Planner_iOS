//
//  VenuesCatalog.swift
//  ios
//
//  Embedded mirror of web venuesByCountry (offline fallback).
//

import Foundation

struct CuratedVenue: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let localCategory: LocalCategory
    let city: String
    let countryCode: String
    let mapQuery: String
    let tag: String?
    /// Absolute or path URL from API (web `/venues/…`); mobile prefers local assets.
    let imageUrl: String?

    init(
        id: String,
        name: String,
        localCategory: LocalCategory,
        city: String,
        countryCode: String,
        mapQuery: String,
        tag: String? = nil,
        imageUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.localCategory = localCategory
        self.city = city
        self.countryCode = countryCode
        self.mapQuery = mapQuery
        self.tag = tag
        self.imageUrl = imageUrl
    }
}

/// Bundled Asset Catalog names — unique realistic thumbs per venue.
enum VenueImageCatalog {
    static func assetName(for id: String) -> String? {
        assets[id]
    }

    private static let assets: [String: String] = [
        "sg-marina-bay-hotel": "VenueSgMarina",
        "sg-orchard-hotel": "VenueSgOrchard",
        "sg-sentosa-beach": "VenueSgSentosaBeach",
        "sg-east-coast-beach": "VenueSgEastCoast",
        "sg-sentosa-resort": "VenueSgSentosaResort",
        "sg-botanic-resort": "VenueSgBotanic",
        "sg-robertson-dining": "VenueSgRobertson",
        "sg-chinatown-salon": "VenueSgChinatown",
        "vn-hcmc-hotel": "VenueVnHcmc",
        "vn-hanoi-hotel": "VenueVnHanoi",
        "vn-danang-beach": "VenueVnDanang",
        "vn-nhatrang-beach": "VenueVnNhatrang",
        "vn-phuquoc-resort": "VenueVnPhuquoc",
        "vn-halong-resort": "VenueVnHalong",
        "vn-hanoi-dining": "VenueVnHanoiDine",
        "vn-saigon-dining": "VenueVnSaigonDine",
        "my-kl-hotel": "VenueMyKl",
        "my-langkawi-beach": "VenueMyLangkawi",
        "my-penang-resort": "VenueMyPenang",
        "my-kl-dining": "VenueMyKlDine",
        "th-bkk-hotel": "VenueThBkk",
        "th-phuket-beach": "VenueThPhuket",
        "th-chiangmai-resort": "VenueThChiangmai",
        "th-bkk-dining": "VenueThBkkDine",
        "id-jkt-hotel": "VenueIdJkt",
        "id-bali-beach": "VenueIdBali",
        "id-ubud-resort": "VenueIdUbud",
        "id-bali-dining": "VenueIdBaliDine",
    ]
}

enum VenuesCatalog {
    static let seaFallback = "SG"

    static let byCountry: [String: (name: String, venues: [CuratedVenue])] = [
        "SG": ("Singapore", [
            .init(id: "sg-marina-bay-hotel", name: "Marina Bay Grand Hotel", localCategory: .hotel, city: "Marina Bay", countryCode: "SG", mapQuery: "Marina Bay Sands Singapore", tag: "Skyline Hotel"),
            .init(id: "sg-orchard-hotel", name: "Orchard Heritage Hotel", localCategory: .hotel, city: "Orchard", countryCode: "SG", mapQuery: "Orchard Road Singapore hotel", tag: "City Hotel"),
            .init(id: "sg-sentosa-beach", name: "Sentosa Beach Pavilion", localCategory: .beach, city: "Sentosa", countryCode: "SG", mapQuery: "Sentosa Beach Singapore", tag: "Island Beach"),
            .init(id: "sg-east-coast-beach", name: "East Coast Shore Club", localCategory: .beach, city: "East Coast", countryCode: "SG", mapQuery: "East Coast Park Singapore", tag: "Coastal"),
            .init(id: "sg-sentosa-resort", name: "Sentosa Cove Resort", localCategory: .resort, city: "Sentosa", countryCode: "SG", mapQuery: "Sentosa Cove Singapore", tag: "Island Resort"),
            .init(id: "sg-botanic-resort", name: "Botanic Garden Estate", localCategory: .resort, city: "Tanglin", countryCode: "SG", mapQuery: "Singapore Botanic Gardens", tag: "Garden Estate"),
            .init(id: "sg-robertson-dining", name: "Robertson Quay Private Dining", localCategory: .restaurant, city: "Robertson Quay", countryCode: "SG", mapQuery: "Robertson Quay Singapore restaurant", tag: "Waterfront Dining"),
            .init(id: "sg-chinatown-salon", name: "Chinatown Heritage Salon", localCategory: .restaurant, city: "Chinatown", countryCode: "SG", mapQuery: "Chinatown Singapore fine dining", tag: "Heritage Dining"),
        ]),
        "VN": ("Vietnam", [
            .init(id: "vn-hcmc-hotel", name: "Saigon Riverside Hotel", localCategory: .hotel, city: "Ho Chi Minh City", countryCode: "VN", mapQuery: "Park Hyatt Saigon", tag: "City Hotel"),
            .init(id: "vn-hanoi-hotel", name: "Hanoi Metropole Hotel", localCategory: .hotel, city: "Hanoi", countryCode: "VN", mapQuery: "Sofitel Legend Metropole Hanoi", tag: "Heritage Hotel"),
            .init(id: "vn-danang-beach", name: "Da Nang Beach Gallery", localCategory: .beach, city: "Da Nang", countryCode: "VN", mapQuery: "My Khe Beach Da Nang", tag: "Beach"),
            .init(id: "vn-nhatrang-beach", name: "Nha Trang Shore Terrace", localCategory: .beach, city: "Nha Trang", countryCode: "VN", mapQuery: "Nha Trang Beach", tag: "Coastal"),
            .init(id: "vn-phuquoc-resort", name: "Phu Quoc Island Resort", localCategory: .resort, city: "Phu Quoc", countryCode: "VN", mapQuery: "Phu Quoc resort Vietnam", tag: "Island Resort"),
            .init(id: "vn-halong-resort", name: "Ha Long Bay Resort", localCategory: .resort, city: "Ha Long", countryCode: "VN", mapQuery: "Ha Long Bay resort", tag: "Bay Resort"),
            .init(id: "vn-hanoi-dining", name: "Old Quarter Private Dining", localCategory: .restaurant, city: "Hanoi", countryCode: "VN", mapQuery: "Hanoi Old Quarter restaurant", tag: "Heritage Dining"),
            .init(id: "vn-saigon-dining", name: "District 1 Culinary Salon", localCategory: .restaurant, city: "Ho Chi Minh City", countryCode: "VN", mapQuery: "District 1 Ho Chi Minh City restaurant", tag: "City Dining"),
        ]),
        "MY": ("Malaysia", [
            .init(id: "my-kl-hotel", name: "Kuala Lumpur Tower Hotel", localCategory: .hotel, city: "Kuala Lumpur", countryCode: "MY", mapQuery: "Kuala Lumpur luxury hotel", tag: "City Hotel"),
            .init(id: "my-langkawi-beach", name: "Langkawi Beach Club", localCategory: .beach, city: "Langkawi", countryCode: "MY", mapQuery: "Langkawi Beach", tag: "Island Beach"),
            .init(id: "my-penang-resort", name: "Penang Hillside Resort", localCategory: .resort, city: "Penang", countryCode: "MY", mapQuery: "Penang resort Malaysia", tag: "Resort"),
            .init(id: "my-kl-dining", name: "Bukit Bintang Dining Room", localCategory: .restaurant, city: "Kuala Lumpur", countryCode: "MY", mapQuery: "Bukit Bintang restaurant", tag: "Dining"),
        ]),
        "TH": ("Thailand", [
            .init(id: "th-bkk-hotel", name: "Bangkok Riverside Hotel", localCategory: .hotel, city: "Bangkok", countryCode: "TH", mapQuery: "Bangkok riverside luxury hotel", tag: "City Hotel"),
            .init(id: "th-phuket-beach", name: "Phuket Beach Pavilion", localCategory: .beach, city: "Phuket", countryCode: "TH", mapQuery: "Phuket Beach", tag: "Beach"),
            .init(id: "th-chiangmai-resort", name: "Chiang Mai Valley Resort", localCategory: .resort, city: "Chiang Mai", countryCode: "TH", mapQuery: "Chiang Mai resort", tag: "Resort"),
            .init(id: "th-bkk-dining", name: "Sukhumvit Private Dining", localCategory: .restaurant, city: "Bangkok", countryCode: "TH", mapQuery: "Sukhumvit fine dining Bangkok", tag: "Dining"),
        ]),
        "ID": ("Indonesia", [
            .init(id: "id-jkt-hotel", name: "Jakarta Grand Hotel", localCategory: .hotel, city: "Jakarta", countryCode: "ID", mapQuery: "Jakarta luxury hotel", tag: "City Hotel"),
            .init(id: "id-bali-beach", name: "Seminyak Beach Club", localCategory: .beach, city: "Bali", countryCode: "ID", mapQuery: "Seminyak Beach Bali", tag: "Beach"),
            .init(id: "id-ubud-resort", name: "Ubud Jungle Resort", localCategory: .resort, city: "Ubud", countryCode: "ID", mapQuery: "Ubud resort Bali", tag: "Resort"),
            .init(id: "id-bali-dining", name: "Canggu Culinary Terrace", localCategory: .restaurant, city: "Canggu", countryCode: "ID", mapQuery: "Canggu restaurant Bali", tag: "Dining"),
        ]),
    ]

    static func resolve(countryCode: String?, city: String? = nil) -> (countryCode: String, countryName: String, venues: [CuratedVenue]) {
        let code = (countryCode ?? "").uppercased()
        if let bucket = byCountry[code] {
            var venues = bucket.venues
            if let city, !city.isEmpty {
                let c = city.lowercased()
                let boosted = venues.filter { $0.city.lowercased().contains(c) || c.contains($0.city.lowercased()) }
                let rest = venues.filter { !boosted.contains($0) }
                venues = boosted + rest
            }
            return (code, bucket.name, venues)
        }
        let fb = byCountry[seaFallback]!
        return (seaFallback, fb.name, fb.venues)
    }
}
