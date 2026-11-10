//
//  ProposalView.swift
//  ios
//

import SwiftUI

struct ProposalView: View {
    let plan: EventPlan
    var onOpenStudio: () -> Void
    var onInquire: () -> Void
    var onStartOver: () -> Void

    @Environment(PlanStore.self) private var store
    @Environment(AuthStore.self) private var auth

    @State private var shareNote: String?
    @State private var syncNote: String?
    @State private var syncing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your blueprint")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(MeridianTheme.atlantic)
                    Text(plan.title)
                        .font(.system(size: 30, weight: .medium, design: .serif))
                        .foregroundStyle(MeridianTheme.ink)
                    Text(plan.tagline)
                        .font(.system(size: 14))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.6))
                    HStack(spacing: 12) {
                        Text(plan.location)
                        Text(plan.estimatedBudgetRange)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(MeridianTheme.ink.opacity(0.5))
                }

                WeatherContingencyCard(forecast: plan.weatherForecast)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Itinerary")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(MeridianTheme.ink.opacity(0.45))

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(plan.itinerary.prefix(6)) { step in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.time)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(MeridianTheme.atlantic)
                                Text(step.activity)
                                    .font(.system(size: 18, weight: .medium, design: .serif))
                                Text(step.description)
                                    .font(.system(size: 12))
                                    .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                            }
                            .padding(.vertical, 12)
                            if step.id != plan.itinerary.prefix(6).last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
                )
                }

                HStack(spacing: 8) {
                    Button(action: sharePlan) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(MeridianTheme.ink)
                            .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.15), lineWidth: 1)
                )
                    }
                    .buttonStyle(.plain)

                    Button(action: exportPlan) {
                        Label("Export", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(MeridianTheme.ink)
                            .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.15), lineWidth: 1)
                )
                    }
                    .buttonStyle(.plain)
                }

                if let shareNote {
                    Text(shareNote)
                        .font(.system(size: 12))
                        .foregroundStyle(MeridianTheme.atlantic)
                }

                if auth.user != nil {
                    Button(action: syncClub) {
                        Label(syncing ? "Syncing…" : "Save to Meridian Club (+25 pts)", systemImage: "icloud.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(MeridianTheme.atlantic)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .meridianGlassRegular()
                    .disabled(syncing)
                }

                if let syncNote {
                    Text(syncNote)
                        .font(.system(size: 12))
                        .foregroundStyle(MeridianTheme.atlantic)
                }

                Button(action: onOpenStudio) {
                    Label("Refine package", systemImage: "square.stack.3d.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MeridianTheme.paper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .meridianGlassProminent(tint: MeridianTheme.ink)

                Button(action: onInquire) {
                    Label("Talk to a planner", systemImage: "bubble.left.and.bubble.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MeridianTheme.paper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .meridianGlassProminent(tint: MeridianTheme.atlantic)

                Button(action: onStartOver) {
                    Label("Start a new plan", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .meridianGlassRegular()
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(Color.clear)
    }

    private var summaryText: String {
        var lines = [
            "Meridian Atelier — Event Blueprint",
            plan.title,
            plan.tagline,
            "",
            "Location: \(plan.location)",
            "Budget: \(plan.estimatedBudgetRange)",
            "",
            "— Itinerary —",
        ]
        for step in plan.itinerary {
            lines.append("\(step.time) · \(step.activity)")
            lines.append(step.description)
            lines.append("")
        }
        lines.append("— Weather —")
        lines.append("\(plan.weatherForecast.temperatureAvg) · \(plan.weatherForecast.conditions)")
        lines.append(plan.weatherForecast.advice)
        lines.append(plan.weatherForecast.contingencyPlan)
        return lines.joined(separator: "\n")
    }

    private func sharePlan() {
        let items: [Any] = [summaryText]
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
                ?? scene.windows.first?.rootViewController
        else { return }
        if let pop = av.popoverPresentationController {
            pop.sourceView = root.view
            pop.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        root.present(av, animated: true)
        shareNote = "Share sheet opened"
    }

    private func exportPlan() {
        UIPasteboard.general.string = summaryText
        shareNote = "Copied summary to clipboard"
    }

    private func syncClub() {
        guard let input = store.lastInput else {
            syncNote = "Generate from the wizard first to sync input."
            return
        }
        syncing = true
        syncNote = nil
        Task {
            do {
                let result = try await APIClient.shared.savePlan(plan: plan, input: input)
                auth.applyClub(result.club)
                syncNote = "Saved to Club · balance \(result.club.points) pts"
            } catch {
                syncNote = error.localizedDescription
            }
            syncing = false
        }
    }
}
