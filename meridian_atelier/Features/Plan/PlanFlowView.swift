//
//  PlanFlowView.swift
//  ios
//

import SwiftUI

struct PlanFlowView: View {
    @Environment(PlanStore.self) private var store
    @State private var draft: PlannerInput = .starter()
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Color.clear)
        .onAppear {
            draft = store.wizardSeed
        }
        .onChange(of: store.wizardSeed) { _, newValue in
            draft = newValue
        }
        .onChange(of: store.planFlowEpoch) { _, _ in
            draft = store.wizardSeed
            errorMessage = nil
            isGenerating = false
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Plan")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.atlantic)
            Text(headerTitle)
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundStyle(MeridianTheme.ink)

            if store.activePlan != nil {
                GlassEffectContainer(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            MeridianPhaseChip("Wizard", selected: store.planPhase == .wizard) {
                                store.planPhase = .wizard
                            }
                            MeridianPhaseChip("Proposal", selected: store.planPhase == .proposal) {
                                store.planPhase = .proposal
                            }
                            MeridianPhaseChip("Studio", selected: store.planPhase == .studio) {
                                store.planPhase = .studio
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var headerTitle: String {
        switch store.planPhase {
        case .wizard: return "Guided blueprint"
        case .proposal: return "Proposal"
        case .studio: return "Package Studio"
        }
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch store.planPhase {
            case .wizard:
                PlanWizardView(
                    input: $draft,
                    isGenerating: isGenerating,
                    errorMessage: errorMessage,
                    onGenerate: generate
                )
                .id("wizard-\(store.planFlowEpoch)")
            case .proposal:
                if let plan = store.activePlan {
                    ProposalView(
                        plan: plan,
                        onOpenStudio: { store.planPhase = .studio },
                        onInquire: { store.openInquire(with: plan) },
                        onStartOver: {
                            store.startNewPlan(seed: .starter(eventType: draft.eventType))
                            draft = store.wizardSeed
                        }
                    )
                } else {
                    PlanWizardView(
                        input: $draft,
                        isGenerating: isGenerating,
                        errorMessage: errorMessage,
                        onGenerate: generate
                    )
                    .id("wizard-\(store.planFlowEpoch)")
                }
            case .studio:
                if let plan = store.activePlan {
                    PackageStudioView(
                        plan: plan,
                        onCommit: { updated in
                            store.updatePlan(updated, input: store.lastInput, persist: true)
                        },
                        onInquire: {
                            store.openInquire(with: store.activePlan)
                        }
                    )
                }
            }
        }
        .id(store.planPhase)
    }

    private func generate() {
        errorMessage = nil
        isGenerating = true
        Task { @MainActor in
            let plan = await APIClient.shared.generatePlan(draft)
            store.save(plan: plan, input: draft)
            store.wizardSeed = draft
            isGenerating = false
        }
    }
}
