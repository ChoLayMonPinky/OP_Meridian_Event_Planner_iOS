//
//  ContentView.swift
//  ios
//
//  Splash → Landing → Native SwiftUI app
//

import SwiftUI

private enum AppStage {
    case splash
    case landing
    case app
}

struct ContentView: View {
    @State private var stage: AppStage = .splash
    @State private var store = PlanStore()
    @State private var auth = AuthStore()

    var body: some View {
        ZStack {
            MeridianTheme.ink.ignoresSafeArea()

            switch stage {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        stage = .landing
                    }
                }
                .transition(.opacity)

            case .landing:
                LandingView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        stage = .app
                    }
                }
                .transition(.opacity)

            case .app:
                MainTabView()
                    .environment(store)
                    .environment(auth)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: stage)
    }
}

#Preview {
    ContentView()
}
