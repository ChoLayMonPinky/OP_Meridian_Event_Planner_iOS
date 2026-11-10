//
//  LocationService.swift
//  ios
//
//  One-shot GPS + reverse geocode for Local venue suggestions.
//

import CoreLocation
import Foundation
import MapKit

struct GeoLocale: Sendable {
    var lat: Double
    var lng: Double
    var countryCode: String?
    var countryName: String?
    var city: String?
}

@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<GeoLocale?, Never>?
    private var awaitingAuthorization = false

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Request when-in-use location once. Returns nil if denied / unavailable.
    func requestLocale() async -> GeoLocale? {
        if continuation != nil { return nil }

        switch manager.authorizationStatus {
        case .denied, .restricted:
            return nil
        case .notDetermined:
            awaitingAuthorization = true
            return await withCheckedContinuation { cont in
                continuation = cont
                manager.requestWhenInUseAuthorization()
            }
        default:
            return await withCheckedContinuation { cont in
                continuation = cont
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            guard awaitingAuthorization || continuation != nil else { return }
            switch manager.authorizationStatus {
            case .denied, .restricted:
                awaitingAuthorization = false
                finish(nil)
            case .authorizedWhenInUse, .authorizedAlways:
                guard awaitingAuthorization else { return }
                awaitingAuthorization = false
                manager.requestLocation()
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else {
            Task { @MainActor in self.finish(nil) }
            return
        }
        Task { @MainActor in
            let place = await Self.reverseGeocode(loc)
            finish(GeoLocale(
                lat: loc.coordinate.latitude,
                lng: loc.coordinate.longitude,
                countryCode: place.code,
                countryName: place.name,
                city: place.city
            ))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            // Ignore transient failures while the permission sheet is still up.
            if self.awaitingAuthorization { return }
            self.finish(nil)
        }
    }

    private func finish(_ value: GeoLocale?) {
        continuation?.resume(returning: value)
        continuation = nil
        awaitingAuthorization = false
    }

    /// MapKit reverse geocode (CLGeocoder is deprecated in iOS 26).
    private static func reverseGeocode(_ location: CLLocation) async -> (code: String?, name: String?, city: String?) {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return (nil, nil, nil)
        }
        do {
            let mapItems = try await request.mapItems
            guard let item = mapItems.first else { return (nil, nil, nil) }
            let reps = item.addressRepresentations
            let code = reps?.region?.identifier
            let name = reps?.regionName
            let city = reps?.cityName
            return (code, name, city)
        } catch {
            return (nil, nil, nil)
        }
    }
}
