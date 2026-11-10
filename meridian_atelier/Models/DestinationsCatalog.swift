//
//  DestinationsCatalog.swift
//  ios
//
//  Curated overseas destinations for Explore — day-seeded trending order.
//

import Foundation

struct ExploreDestination: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let region: String
    let blurb: String
    /// Seeded into PlannerInput.locationName
    let locationName: String
    /// Asset catalog image name
    let imageName: String
    var score: Int = 0
}

enum DestinationsCatalog {
    static let all: [ExploreDestination] = [
        .init(id: "santorini", name: "Santorini", region: "Greece", blurb: "White terraces & caldera light", locationName: "Santorini, Greece", imageName: "DestCliff"),
        .init(id: "amalfi", name: "Amalfi", region: "Italy", blurb: "Cliffside vows above the sea", locationName: "Amalfi Coast, Italy", imageName: "DestCover"),
        .init(id: "bali", name: "Bali", region: "Indonesia", blurb: "Jungle resorts & shore clubs", locationName: "Bali, Indonesia", imageName: "DestBeach"),
        .init(id: "kyoto", name: "Kyoto", region: "Japan", blurb: "Temple gardens & quiet formality", locationName: "Kyoto, Japan", imageName: "DestDining"),
        .init(id: "hawaii", name: "Hawaii", region: "USA", blurb: "Pacific estates & lava shores", locationName: "Hawaii, USA", imageName: "DestResort"),
        .init(id: "phuket", name: "Phuket", region: "Thailand", blurb: "Andaman beaches & private villas", locationName: "Phuket, Thailand", imageName: "DestSalon"),
    ]

    private static let seasonal: [String: [Int]] = [
        "santorini": [40, 45, 55, 70, 90, 95, 88, 85, 80, 70, 50, 42],
        "amalfi": [35, 40, 55, 75, 90, 95, 92, 88, 78, 65, 45, 38],
        "bali": [85, 80, 70, 60, 55, 50, 55, 60, 70, 80, 90, 92],
        "kyoto": [55, 50, 85, 90, 70, 55, 50, 55, 65, 90, 85, 60],
        "hawaii": [75, 70, 65, 60, 55, 50, 55, 60, 65, 70, 80, 85],
        "phuket": [80, 75, 65, 55, 50, 45, 50, 55, 60, 70, 85, 90],
    ]

    private static let imageKeyMap: [String: String] = [
        "cliff": "DestCliff",
        "cover": "DestCover",
        "beach": "DestBeach",
        "dining": "DestDining",
        "resort": "DestResort",
        "salon": "DestSalon",
    ]

    static func utcDayKey(date: Date = Date()) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }

    /// Offline / fallback — matches web `resolveTrendingDestinations` for the same UTC day.
    static func trendingToday(day: String? = nil) -> (day: String, label: String, destinations: [ExploreDestination]) {
        let dayKey: String = {
            if let day, day.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil {
                return day
            }
            return utcDayKey()
        }()
        let month = Int(dayKey.dropFirst(5).prefix(2)) ?? 1
        let ranked = all.map { dest -> ExploreDestination in
            let weight = seasonal[dest.id]?[max(0, min(11, month - 1))] ?? 50
            let jitter = Int(fnv1a("\(dayKey):\(dest.id)") % 1000)
            var copy = dest
            copy.score = weight * 1000 + jitter
            return copy
        }
        .sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            return $0.id < $1.id
        }
        return (dayKey, "Trending today", ranked)
    }

    static func fromAPI(
        id: String,
        name: String,
        region: String,
        blurb: String,
        locationName: String,
        imageKey: String,
        score: Int
    ) -> ExploreDestination {
        ExploreDestination(
            id: id,
            name: name,
            region: region,
            blurb: blurb,
            locationName: locationName,
            imageName: imageKeyMap[imageKey] ?? "DestCliff",
            score: score
        )
    }

    private static func fnv1a(_ input: String) -> UInt32 {
        var h: UInt32 = 2_166_136_261
        for b in input.utf8 {
            h ^= UInt32(b)
            h = h &* 16_777_619
        }
        return h
    }
}
