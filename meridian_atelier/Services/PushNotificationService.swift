//
//  PushNotificationService.swift
//  ios
//

import Foundation
import UserNotifications

@MainActor
final class PushNotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationService()

    private let center = UNUserNotificationCenter.current()
    private var didInstallDelegate = false

    private override init() {
        super.init()
    }

    /// Call once at launch so banners show while the app is foregrounded.
    func configure() {
        guard !didInstallDelegate else { return }
        didInstallDelegate = true
        center.delegate = self
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        configure()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Schedules a local concierge alert. Returns false if permission is missing or scheduling fails.
    @discardableResult
    func sendConciergeAlert(
        title: String = "Meridian Concierge",
        body: String,
        identifier: String = "meridian.concierge.demo"
    ) async -> Bool {
        configure()
        let granted: Bool
        let status = await authorizationStatus()
        if status == .notDetermined {
            granted = await requestAuthorization()
        } else {
            granted = status == .authorized || status == .provisional
        }
        guard granted else { return false }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.8, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
