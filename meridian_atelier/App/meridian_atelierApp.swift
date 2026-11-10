//
//  meridian_atelierApp.swift
//  ios
//

import SwiftUI

@main
struct meridian_atelierApp: App {
    init() {
        PushNotificationService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
