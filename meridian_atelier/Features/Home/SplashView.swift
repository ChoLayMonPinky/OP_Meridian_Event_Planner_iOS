//
//  SplashView.swift
//  ios
//
//  In-app splash after the system launch screen.
//

import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void

    @State private var markOpacity = 0.0
    @State private var markScale = 0.92
    @State private var wordOpacity = 0.0
    @State private var wordOffset: CGFloat = 10

    var body: some View {
        ZStack {
            MeridianTheme.ink.ignoresSafeArea()

            VStack(spacing: 20) {
                Image("LaunchMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .opacity(markOpacity)
                    .scaleEffect(markScale)

                VStack(spacing: 6) {
                    Text(MeridianTheme.brandName)
                        .font(.system(size: 36, weight: .medium, design: .serif))
                        .foregroundStyle(MeridianTheme.paper)
                    Text(MeridianTheme.brandSub.uppercased())
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .tracking(4)
                        .foregroundStyle(MeridianTheme.paper.opacity(0.65))
                }
                .opacity(wordOpacity)
                .offset(y: wordOffset)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                markOpacity = 1
                markScale = 1
            }
            withAnimation(.easeOut(duration: 0.55).delay(0.18)) {
                wordOpacity = 1
                wordOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
