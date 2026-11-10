//
//  InquireView.swift
//  ios
//

import SwiftUI

struct InquireView: View {
    @Environment(PlanStore.self) private var store
    @Environment(AuthStore.self) private var auth

    @State private var name = ""
    @State private var email = ""
    @State private var location = ""
    @State private var date = ""
    @State private var budget = ""
    @State private var vision = ""
    @State private var redeemHundreds = 0
    @State private var isSubmitting = false
    @State private var done = false
    @State private var message: String?

    private var maxRedeemHundreds: Int {
        max(0, (auth.user?.points ?? 0) / 100)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Inquire")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundStyle(MeridianTheme.atlantic)
                    Text("Talk to a planner")
                        .font(.system(size: 24, weight: .medium, design: .serif))
                    Text("Share a few details. We’ll reply from \(AppConfig.plannerEmail).")
                        .font(.system(size: 14))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                }

                if done {
                    VStack(spacing: 14) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(MeridianTheme.atlantic)
                            .scaleEffect(done ? 1 : 0.7)
                        Text("Thank you, \(name)")
                            .font(.system(size: 28, weight: .medium, design: .serif))
                        Text("A planner will follow up at \(email). Track status in Meridian Club.")
                            .font(.system(size: 14))
                            .foregroundStyle(MeridianTheme.ink.opacity(0.6))
                            .multilineTextAlignment(.center)
                        if let message {
                            Text(message)
                                .font(.system(size: 12))
                                .foregroundStyle(MeridianTheme.atlantic)
                                .multilineTextAlignment(.center)
                        }
                        Button("Send another inquiry") {
                            done = false
                        }
                        .font(.system(size: 14))
                        .foregroundStyle(MeridianTheme.atlantic)
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .transition(.opacity.combined(with: .scale(0.97).combined(with: .offset(y: 10))))
                } else {
                    if let plan = store.activePlan {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Attached plan")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(1.4)
                                .textCase(.uppercase)
                                .foregroundStyle(MeridianTheme.atlantic)
                            Text(plan.title)
                                .font(.system(size: 20, weight: .medium, design: .serif))
                            Text(plan.estimatedBudgetRange)
                                .font(.system(size: 12))
                                .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(MeridianTheme.ink.opacity(0.04))
                        .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
                )
                    }

                    formField("Full name", text: $name)
                    formField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    formField("Location", text: $location)
                    formField("Target month / season", text: $date)
                    formField("Budget", text: $budget)
                    formField("Vision", text: $vision, axis: .vertical)

                    if auth.user != nil, maxRedeemHundreds > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Club credit")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.2)
                                .textCase(.uppercase)
                                .foregroundStyle(MeridianTheme.atlantic)
                            Text("You have \(auth.user?.points ?? 0) pts. Apply up to $\(maxRedeemHundreds).")
                                .font(.system(size: 12))
                                .foregroundStyle(MeridianTheme.ink.opacity(0.6))
                            Stepper(
                                "Redeem \(redeemHundreds * 100) pts → $\(redeemHundreds)",
                                value: $redeemHundreds,
                                in: 0...maxRedeemHundreds
                            )
                            .font(.system(size: 13))
                        }
                        .padding(14)
                        .background(MeridianTheme.atlantic.opacity(0.06))
                        .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.atlantic.opacity(0.25), lineWidth: 1)
                )
                    }

                    if let message, !done {
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundStyle(.red.opacity(0.8))
                    }

                    Button(action: submit) {
                        HStack {
                            if isSubmitting { ProgressView().tint(MeridianTheme.paper) }
                            Text(isSubmitting ? "Sending…" : "Send inquiry")
                                .fontWeight(.semibold)
                            Image(systemName: "paperplane")
                        }
                        .foregroundStyle(MeridianTheme.paper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .meridianGlassProminent(tint: MeridianTheme.ink)
                    .disabled(isSubmitting || name.isEmpty || email.isEmpty || date.isEmpty)
                }
            }
            .padding(20)
            .padding(.bottom, 28)
            .animation(MeridianMotion.soft, value: done)
        }
        .background(Color.clear)
        .onAppear(perform: prefill)
        .onChange(of: store.activePlan?.title) { _, _ in
            prefillFromPlan()
        }
        .onChange(of: auth.user?.email) { _, _ in
            prefillFromAuth()
        }
    }

    private func formField(_ title: String, text: Binding<String>, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.ink.opacity(0.5))
            Group {
                if axis == .vertical {
                    TextField("", text: text, axis: .vertical)
                        .lineLimit(3...5)
                } else {
                    TextField("", text: text)
                }
            }
            .textFieldStyle(.plain)
            .padding(12)
            .frame(minHeight: axis == .vertical ? 88 : nil, alignment: .topLeading)
            .meridianInputSurface()
        }
    }

    private func prefill() {
        prefillFromAuth()
        prefillFromPlan()
    }

    private func prefillFromAuth() {
        if name.isEmpty, let n = auth.user?.name { name = n }
        if email.isEmpty, let e = auth.user?.email { email = e }
    }

    private func prefillFromPlan() {
        guard let plan = store.activePlan else { return }
        if location.isEmpty { location = plan.location }
        if budget.isEmpty { budget = plan.estimatedBudgetRange }
        if vision.isEmpty { vision = "\(plan.title) — \(plan.tagline)" }
    }

    private func submit() {
        isSubmitting = true
        message = nil
        let redeem = redeemHundreds * 100
        let payload = LeadPayload(
            name: name,
            email: email,
            location: location,
            date: date,
            budget: budget,
            vision: vision,
            planTitle: store.activePlan?.title,
            planTagline: store.activePlan?.tagline,
            redeemPoints: auth.user != nil && redeem > 0 ? redeem : nil
        )
        Task { @MainActor in
            let result = await APIClient.shared.submitLead(payload)
            message = result.message
            withAnimation(MeridianMotion.soft) {
                done = result.ok
            }
            if let club = result.club {
                auth.applyClub(club)
            }
            isSubmitting = false
        }
    }
}
