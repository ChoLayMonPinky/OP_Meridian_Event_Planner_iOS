//
//  MainTabView.swift
//  ios
//

import SwiftUI

struct MainTabView: View {
    @Environment(PlanStore.self) private var store
    @Environment(AuthStore.self) private var auth

    var body: some View {
        @Bindable var store = store

        TabView(selection: tabSelection) {
            Tab("Explore", systemImage: "globe.europe.africa", value: PlanStore.AppTab.home) {
                HomeView()
                    .environment(store)
                    .environment(auth)
            }

            Tab("Plan", systemImage: "pencil.line", value: PlanStore.AppTab.plan) {
                PlanFlowView()
                    .environment(store)
                    .environment(auth)
                    .background { MeridianAmbientBackground() }
            }

            Tab("Inquire", systemImage: "bubble.left.and.bubble.right", value: PlanStore.AppTab.inquire) {
                InquireView()
                    .environment(store)
                    .environment(auth)
                    .background { MeridianAmbientBackground() }
            }

            Tab("Club", systemImage: "sparkles", value: PlanStore.AppTab.club) {
                ClubView()
                    .environment(auth)
                    .background { MeridianAmbientBackground() }
            }
        }
        .tint(MeridianTheme.atlantic)
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    /// Explicit binding so programmatic `openPlan` / `openInquire` always switches tabs.
    private var tabSelection: Binding<PlanStore.AppTab> {
        Binding(
            get: { store.selectedTab },
            set: { store.selectedTab = $0 }
        )
    }
}
