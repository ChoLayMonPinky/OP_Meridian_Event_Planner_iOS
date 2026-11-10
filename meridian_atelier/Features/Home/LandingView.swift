//
//  LandingView.swift
//  ios
//
//  Native brand landing before the WebView app shell.
//

import SwiftUI

struct LandingView: View {
    var onEnter: () -> Void
    @State private var revealed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("LandingHero")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .scaleEffect(revealed ? 1.0 : 1.05)
                .animation(.easeOut(duration: 1.2), value: revealed)
                .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    MeridianTheme.ink.opacity(0.12),
                    MeridianTheme.ink.opacity(0.42),
                    MeridianTheme.ink.opacity(0.88),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 8) {
                    Text(MeridianTheme.brandName)
                        .font(.system(size: 48, weight: .medium, design: .serif))
                        .foregroundStyle(MeridianTheme.paper)
                    Text(MeridianTheme.brandSub.uppercased())
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .tracking(5)
                        .foregroundStyle(MeridianTheme.paper.opacity(0.75))
                }

                Text(MeridianTheme.tagline)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(MeridianTheme.paper.opacity(0.88))
                    .frame(maxWidth: 280, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onEnter) {
                    HStack(spacing: 8) {
                        Text("Enter atelier")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(MeridianTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .meridianGlassProminent(tint: MeridianTheme.paper.opacity(0.95))
                .padding(.top, 8)
                .accessibilityIdentifier("landing-enter")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 18)
        }
        .background(MeridianTheme.ink)
        .onAppear {
            withAnimation(MeridianMotion.entrance) {
                revealed = true
            }
        }
    }
}

#Preview {
    LandingView(onEnter: {})
}
