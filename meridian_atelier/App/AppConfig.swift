//
//  AppConfig.swift
//  ios
//

import Foundation

enum AppConfig {
    /// Production API (HTTPS). Override via Info.plist `MeridianAPIHost` for staging.
    private static let productionAPI: URL = {
        if let host = Bundle.main.object(forInfoDictionaryKey: "MeridianAPIHost") as? String,
           !host.isEmpty,
           let url = URL(string: "http://\(host):3000") {
            return url
        }
        return URL(string: "https://api.meridianatelier.com")!
    }()

    /// DEBUG → Docker `web` on this Mac (`docker compose up` from docker/).
    /// Simulator: 127.0.0.1. Physical device: set MeridianAPIHost in Info.plist to your Mac LAN IP.
    #if DEBUG
    private static let useLocalAPI = true
    private static let localAPIHost: String = {
        #if targetEnvironment(simulator)
        return "127.0.0.1"
        #else
        if let host = Bundle.main.object(forInfoDictionaryKey: "MeridianAPIHost") as? String,
           !host.isEmpty {
            return host
        }
        return "127.0.0.1"
        #endif
    }()
    #endif

    static let apiBaseURL: URL = {
        #if DEBUG
        if useLocalAPI {
            return URL(string: "http://\(localAPIHost):3000")!
        }
        #endif
        return productionAPI
    }()

    /// Supabase project (Realtime Club consults). Publishable key only — never the secret.
    static let supabaseURL = URL(string: "https://iqwpwelnkczubaoevowj.supabase.co")!
    static let supabasePublishableKey = "sb_publishable_DnSeGphm6C9-7vzhENOs7A_xCvED6uy"

    static var isSupabaseConfigured: Bool {
        !supabasePublishableKey.isEmpty && supabasePublishableKey.hasPrefix("sb_")
    }

    static let brandName = "Meridian"
    static let brandSub = "Atelier"
    static let tagline = "Near or far, planned with care."
    static let plannerEmail = "planner@meridianatelier.com"
}
