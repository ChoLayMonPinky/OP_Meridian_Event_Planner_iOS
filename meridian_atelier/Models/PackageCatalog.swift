//
//  PackageCatalog.swift
//  ios
//

import Foundation

struct StayCatalogItem: Identifiable {
    let id: String
    let name: String
    let neighborhood: String
    let nightsDefault: Int
    let blurb: String
    let mapQuery: String
}

struct TransferCatalogItem: Identifiable {
    let id: String
    let title: String
    let fromLabel: String
    let toLabel: String
    let minutes: Int
    let blurb: String
}

enum PackageCatalog {
    static let stays: [StayCatalogItem] = [
        StayCatalogItem(
            id: "stay-cliff",
            name: "Cliffside Atelier Suites",
            neighborhood: "Caldera rim",
            nightsDefault: 3,
            blurb: "Whitewashed suites with private terraces — ideal for destination parties.",
            mapQuery: "Santorini cliff hotel"
        ),
        StayCatalogItem(
            id: "stay-harbor",
            name: "Harbor House Residences",
            neighborhood: "Old port",
            nightsDefault: 2,
            blurb: "Townhouse residences by the marina for rehearsal dinners and overflow.",
            mapQuery: "Santorini harbor hotel"
        ),
        StayCatalogItem(
            id: "stay-heritage",
            name: "Heritage Garden Hotel",
            neighborhood: "City garden district",
            nightsDefault: 2,
            blurb: "Local courtyard hotel with ballroom adjacency for same-site ceremonies.",
            mapQuery: "luxury garden hotel"
        ),
        StayCatalogItem(
            id: "stay-resort",
            name: "Atlantic Resort Wing",
            neighborhood: "Coastal resort",
            nightsDefault: 3,
            blurb: "Beach-facing wing with hospitality suite for VIP hosts.",
            mapQuery: "beach resort hotel"
        ),
    ]

    static let transfers: [TransferCatalogItem] = [
        TransferCatalogItem(id: "xfer-airport-hotel", title: "Airport → Hotel", fromLabel: "Airport", toLabel: "Host hotel", minutes: 75, blurb: "Meet-and-greet with private coach or sedan fleet."),
        TransferCatalogItem(id: "xfer-hotel-venue", title: "Hotel → Ceremony", fromLabel: "Host hotel", toLabel: "Ceremony", minutes: 45, blurb: "Staggered guest shuttles timed to call time."),
        TransferCatalogItem(id: "xfer-venue-reception", title: "Ceremony → Reception", fromLabel: "Ceremony", toLabel: "Reception", minutes: 30, blurb: "Short-hop when sites differ."),
        TransferCatalogItem(id: "xfer-late-return", title: "Reception → Hotel (late)", fromLabel: "Reception", toLabel: "Host hotel", minutes: 40, blurb: "Night return shuttles after last dance."),
        TransferCatalogItem(id: "xfer-hotel-airport", title: "Hotel → Airport", fromLabel: "Host hotel", toLabel: "Airport", minutes: 80, blurb: "Checkout-day departure with luggage handling."),
    ]
}
