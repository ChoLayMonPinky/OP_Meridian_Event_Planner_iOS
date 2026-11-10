//
//  meridian_atelierTests.swift
//

import Testing
@testable import meridian_atelier

struct meridian_atelierTests {
    @Test func apiBaseURLIsValid() async throws {
        #expect(AppConfig.apiBaseURL.scheme == "http" || AppConfig.apiBaseURL.scheme == "https")
    }

    @Test func fallbackPlanHasItinerary() async throws {
        let plan = APIClient.fallbackPlan(for: .starter())
        #expect(!plan.itinerary.isEmpty)
        #expect(!plan.title.isEmpty)
    }
}
