//
//  PackageStudioView.swift
//  ios
//

import SwiftUI
import UIKit

struct PackageStudioView: View {
    var onCommit: (EventPlan) -> Void
    var onInquire: () -> Void

    @State private var draft: EventPlan
    @State private var pane: StudioPane = .timeline
    @State private var stayNights: [String: Int] = [:]
    @State private var exportNote: String?

    init(plan: EventPlan, onCommit: @escaping (EventPlan) -> Void, onInquire: @escaping () -> Void) {
        self.onCommit = onCommit
        self.onInquire = onInquire
        _draft = State(initialValue: plan)
    }

    private enum StudioPane: String, CaseIterable {
        case timeline, stays, transfers, map, export
        var label: String {
            switch self {
            case .timeline: return "Timeline"
            case .stays: return "Stays"
            case .transfers: return "Transfers"
            case .map: return "Map"
            case .export: return "Export"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Package Studio")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(MeridianTheme.atlantic)
                Text(draft.title)
                    .font(.system(size: 26, weight: .medium, design: .serif))
                Text("Stays, transfers, map, and export — then inquire with this package attached.")
                    .font(.system(size: 13))
                    .foregroundStyle(MeridianTheme.ink.opacity(0.55))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(StudioPane.allCases, id: \.self) { p in
                            Button(p.label) { pane = p }
                                .font(.system(size: 12, weight: pane == p ? .semibold : .regular))
                                .foregroundStyle(pane == p ? MeridianTheme.paper : MeridianTheme.ink.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(pane == p ? MeridianTheme.ink : Color.clear)
                                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(pane == p ? 1 : 0.12), lineWidth: 1)
                )
                                .buttonStyle(.plain)
                        }
                    }
                }

                switch pane {
                case .timeline: timelinePane
                case .stays: staysPane
                case .transfers: transfersPane
                case .map: mapPane
                case .export: exportPane
                }

                Button {
                    onCommit(draft)
                    onInquire()
                } label: {
                    Label("Talk to a planner", systemImage: "bubble.left.and.bubble.right")
                        .fontWeight(.semibold)
                        .foregroundStyle(MeridianTheme.paper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .meridianGlassProminent(tint: MeridianTheme.atlantic)
            }
            .padding(20)
            .padding(.bottom, 28)
        }
        .background(Color.clear)
        .onDisappear { onCommit(draft) }
    }

    private var timelinePane: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Itinerary")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.3)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.ink.opacity(0.45))

            ForEach(Array(draft.itinerary.enumerated()), id: \.element.id) { index, _ in
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Time", text: bindingTime(at: index))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MeridianTheme.atlantic)
                    TextField("Activity", text: bindingActivity(at: index))
                        .font(.system(size: 17, design: .serif))
                    TextField("Description", text: bindingDescription(at: index), axis: .vertical)
                        .font(.system(size: 12))
                        .lineLimit(2...4)
                }
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
                )
            }

            Button {
                draft.itinerary.append(
                    ItineraryItem(time: "—", activity: "New moment", description: "Describe this beat.")
                )
            } label: {
                Label("Add itinerary beat", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(MeridianTheme.atlantic)
                    .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.atlantic.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Text("Checklist")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.3)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.ink.opacity(0.45))

            ForEach(Array(draft.eventChecklist.enumerated()), id: \.offset) { index, _ in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(MeridianTheme.atlantic)
                    TextField("Checklist item", text: bindingChecklist(at: index))
                        .font(.system(size: 14))
                }
            }
        }
    }

    private var staysPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add hotel or villa nights to the itinerary (one row per night).")
                .font(.system(size: 13))
                .foregroundStyle(MeridianTheme.ink.opacity(0.55))
            ForEach(PackageCatalog.stays) { stay in
                let nights = stayNights[stay.id] ?? stay.nightsDefault
                VStack(alignment: .leading, spacing: 8) {
                    Text(stay.name).font(.system(size: 17, design: .serif))
                    Text("\(stay.neighborhood) · \(stay.blurb)")
                        .font(.system(size: 12))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                    HStack {
                        Stepper("Nights: \(nights)", value: Binding(
                            get: { stayNights[stay.id] ?? stay.nightsDefault },
                            set: { stayNights[stay.id] = $0 }
                        ), in: 1...7)
                        Button("Add") { addStay(stay, nights: nights) }
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    private var transfersPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Airport, venue, and hotel logistics legs.")
                .font(.system(size: 13))
                .foregroundStyle(MeridianTheme.ink.opacity(0.55))
            ForEach(PackageCatalog.transfers) { xfer in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(xfer.title).font(.system(size: 16, design: .serif))
                        Text("\(xfer.fromLabel) → \(xfer.toLabel) · \(xfer.minutes) min")
                            .font(.system(size: 11))
                            .foregroundStyle(MeridianTheme.atlantic)
                        Text(xfer.blurb)
                            .font(.system(size: 12))
                            .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                    }
                    Spacer()
                    Button("Add") { addTransfer(xfer) }
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    private var mapPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(draft.location)
                .font(.system(size: 20, design: .serif))
            Text("Open the destination in Apple Maps for venue context.")
                .font(.system(size: 13))
                .foregroundStyle(MeridianTheme.ink.opacity(0.55))
            if let url = mapURL(for: draft.location) {
                Link(destination: url) {
                    Label("Open in Maps", systemImage: "map")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(MeridianTheme.paper)
                        .background(MeridianTheme.ink)
                }
            }
        }
    }

    private var exportPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share a package summary (calendar-friendly text).")
                .font(.system(size: 13))
                .foregroundStyle(MeridianTheme.ink.opacity(0.55))
            ShareLink(item: packageSummaryText()) {
                Label("Share package summary", systemImage: "square.and.arrow.up")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(MeridianTheme.paper)
                    .background(MeridianTheme.ink)
            }
            Button("Copy summary") {
                UIPasteboard.general.string = packageSummaryText()
                exportNote = "Copied to clipboard."
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(MeridianTheme.atlantic)
            if let exportNote {
                Text(exportNote).font(.system(size: 12)).foregroundStyle(MeridianTheme.atlantic)
            }
            Text(packageSummaryText())
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(MeridianTheme.ink.opacity(0.55))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
                )
        }
    }

    private func addStay(_ stay: StayCatalogItem, nights: Int) {
        let n = max(1, nights)
        for i in 0..<n {
            let label: String
            if i == 0 {
                label = "\(stay.name) · check-in"
            } else if i == n - 1 {
                label = "\(stay.name) · night \(i + 1) / check-out eve"
            } else {
                label = "\(stay.name) · night \(i + 1)"
            }
            draft.itinerary.append(
                ItineraryItem(
                    time: i == 0 ? "15:00" : "12:00",
                    activity: label,
                    description: "\(stay.neighborhood). \(stay.blurb)"
                )
            )
        }
        pane = .timeline
    }

    private func addTransfer(_ xfer: TransferCatalogItem) {
        draft.itinerary.append(
            ItineraryItem(
                time: "10:00",
                activity: xfer.title,
                description: "\(xfer.fromLabel) → \(xfer.toLabel) · \(xfer.minutes) min. \(xfer.blurb)"
            )
        )
        pane = .timeline
    }

    private func mapURL(for query: String) -> URL? {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return URL(string: "https://maps.apple.com/?q=\(q)")
    }

    private func packageSummaryText() -> String {
        var lines = [
            "Meridian Atelier — Package",
            draft.title,
            draft.tagline,
            "Location: \(draft.location)",
            "Budget: \(draft.estimatedBudgetRange)",
            "",
            "— Itinerary —",
        ]
        for step in draft.itinerary {
            lines.append("\(step.time) · \(step.activity)")
            lines.append(step.description)
            lines.append("")
        }
        lines.append("— Checklist —")
        for item in draft.eventChecklist {
            lines.append("• \(item)")
        }
        return lines.joined(separator: "\n")
    }

    private func bindingTime(at index: Int) -> Binding<String> {
        Binding(
            get: { draft.itinerary[index].time },
            set: { draft.itinerary[index].time = $0 }
        )
    }

    private func bindingActivity(at index: Int) -> Binding<String> {
        Binding(
            get: { draft.itinerary[index].activity },
            set: { draft.itinerary[index].activity = $0 }
        )
    }

    private func bindingDescription(at index: Int) -> Binding<String> {
        Binding(
            get: { draft.itinerary[index].description },
            set: { draft.itinerary[index].description = $0 }
        )
    }

    private func bindingChecklist(at index: Int) -> Binding<String> {
        Binding(
            get: { draft.eventChecklist[index] },
            set: { draft.eventChecklist[index] = $0 }
        )
    }
}
