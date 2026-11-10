//
//  MeridianGlass.swift
//  ios
//
//  Liquid Glass helpers — chrome / floating controls only (iOS 26+).
//

import SwiftUI

enum MeridianGlass {
    static let panelRadius: CGFloat = 16
    static let chipRadius: CGFloat = 14
}

/// Soft color field so glass chrome can refract over paper screens.
struct MeridianAmbientBackground: View {
    var body: some View {
        ZStack {
            MeridianTheme.paper

            EllipticalGradient(
                colors: [
                    MeridianTheme.atlantic.opacity(0.28),
                    MeridianTheme.atlantic.opacity(0.08),
                    Color.clear,
                ],
                center: .topLeading,
                startRadiusFraction: 0.05,
                endRadiusFraction: 0.85
            )

            EllipticalGradient(
                colors: [
                    MeridianTheme.ink.opacity(0.07),
                    Color.clear,
                ],
                center: .bottomTrailing,
                startRadiusFraction: 0.1,
                endRadiusFraction: 0.7
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

extension View {
    @ViewBuilder
    func meridianGlassPanel(interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
        if interactive {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self.glassEffect(.regular, in: shape)
        }
    }

    @ViewBuilder
    func meridianGlassCapsule(interactive: Bool = true, tint: Color? = nil) -> some View {
        if let tint {
            if interactive {
                self.glassEffect(.regular.tint(tint).interactive(), in: .capsule)
            } else {
                self.glassEffect(.regular.tint(tint), in: .capsule)
            }
        } else if interactive {
            self.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            self.glassEffect(.regular, in: .capsule)
        }
    }
}
