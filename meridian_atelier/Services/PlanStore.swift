//
//  PlanStore.swift
//  ios
//

import Foundation
import Observation

@Observable
final class PlanStore {
    private let key = "meridian.storedPlanBundle"

    var activePlan: EventPlan?
    var lastInput: PlannerInput?
    var selectedTab: AppTab = .home
    var planPhase: PlanPhase = .wizard
    var wizardSeed: PlannerInput = .starter()
    /// Bumped when starting a fresh wizard so PlanWizardView resets step state.
    var planFlowEpoch: Int = 0

    enum AppTab: Hashable {
        case home, plan, inquire, club
    }

    enum PlanPhase: Hashable {
        case wizard, proposal, studio
    }

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let bundle = try? JSONDecoder().decode(StoredPlanBundle.self, from: data)
        else { return }
        activePlan = bundle.plan
        lastInput = bundle.input
        planPhase = .proposal
    }

    /// Update in-memory plan (and optionally persist) without changing phase.
    /// Used by Package Studio while editing.
    func updatePlan(_ plan: EventPlan, input: PlannerInput? = nil, persist: Bool = true) {
        activePlan = plan
        if let input {
            lastInput = input
        }
        guard persist, let input = lastInput ?? input else { return }
        writeBundle(plan: plan, input: input)
    }

    /// Persist and jump to Proposal (after generate / explicit save).
    func save(plan: EventPlan, input: PlannerInput) {
        activePlan = plan
        lastInput = input
        planPhase = .proposal
        writeBundle(plan: plan, input: input)
    }

    private func writeBundle(plan: EventPlan, input: PlannerInput) {
        let bundle = StoredPlanBundle(plan: plan, input: input, savedAt: Date())
        let storageKey = key
        // Encode on the caller’s actor first — Encodable conformances are MainActor-isolated
        // under SWIFT_DEFAULT_ACTOR_ISOLATION, so Task.detached must not touch the model types.
        guard let data = try? JSONEncoder().encode(bundle) else { return }
        Task.detached(priority: .utility) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func clear() {
        activePlan = nil
        lastInput = nil
        planPhase = .wizard
        UserDefaults.standard.removeObject(forKey: key)
        planFlowEpoch += 1
    }

    /// Open Plan tab at a phase (e.g. continue an existing proposal).
    func openPlan(seed: PlannerInput? = nil, phase: PlanPhase = .wizard) {
        if let seed {
            wizardSeed = seed
        }
        planPhase = phase
        selectedTab = .plan
        if phase == .wizard {
            planFlowEpoch += 1
        }
    }

    /// Discard any saved proposal and start a new guided blueprint.
    func startNewPlan(seed: PlannerInput) {
        activePlan = nil
        lastInput = nil
        UserDefaults.standard.removeObject(forKey: key)
        wizardSeed = seed
        planPhase = .wizard
        planFlowEpoch += 1
        selectedTab = .plan
    }

    func openInquire(with plan: EventPlan? = nil) {
        if let plan { activePlan = plan }
        selectedTab = .inquire
    }
}
