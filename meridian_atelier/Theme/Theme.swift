//
//  Theme.swift
//  ios
//

import SwiftUI

enum MeridianTheme {
    static let ink = Color("Ink")
    static let paper = Color("Paper")
    static let atlantic = Color("Atlantic")

    static var brandName: String { AppConfig.brandName }
    static var brandSub: String { AppConfig.brandSub }
    static var tagline: String { AppConfig.tagline }
}
