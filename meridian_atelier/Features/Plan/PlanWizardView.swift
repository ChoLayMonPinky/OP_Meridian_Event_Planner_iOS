//
//  PlanWizardView.swift
//  ios
//

import SwiftUI

struct PlanWizardView: View {
    @Binding var input: PlannerInput
    var isGenerating: Bool
    var errorMessage: String?
    var onGenerate: () -> Void

    @State private var step = 0
    @State private var nearbyVenues: [CuratedVenue] = []
    @State private var nearbyCountryName: String?
    @State private var nearbyLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Rectangle()
                        .fill(i <= step ? MeridianTheme.atlantic : MeridianTheme.ink.opacity(0.12))
                        .frame(height: 3)
                        .animation(MeridianMotion.soft, value: step)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)

            ScrollView {
                Group {
                    switch step {
                    case 0: stepType
                    case 1: stepPlace
                    default: stepTone
                    }
                }
                .id(step)
                .transition(.opacity.combined(with: .offset(y: 8)))
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .animation(MeridianMotion.soft, value: step)
            .task(id: input.eventType) {
                guard input.eventType == .local else {
                    nearbyVenues = []
                    nearbyCountryName = nil
                    return
                }
                await loadNearbyVenues()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.85))
                    .padding(.horizontal, 20)
            }

            HStack(alignment: .center, spacing: 10) {
                if step > 0 {
                    Button {
                        withAnimation(MeridianMotion.soft) { step -= 1 }
                    } label: {
                        Label("Back", systemImage: "arrow.left")
                            .labelStyle(.titleAndIcon)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .foregroundStyle(MeridianTheme.ink)
                    }
                    .meridianGlassRegular()
                    .disabled(isGenerating)
                    .fixedSize(horizontal: true, vertical: false)
                }

                Button {
                    if step < 2 {
                        withAnimation(MeridianMotion.soft) { step += 1 }
                    } else {
                        onGenerate()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isGenerating { ProgressView().tint(MeridianTheme.paper) }
                        Text(step < 2 ? "Continue" : "Generate blueprint")
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        if !isGenerating { Image(systemName: "arrow.right") }
                    }
                    .foregroundStyle(MeridianTheme.paper)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                }
                .meridianGlassProminent(tint: step < 2 ? MeridianTheme.ink : MeridianTheme.atlantic)
                .disabled(isGenerating)
                .layoutPriority(1)
            }
            .padding(20)
        }
        .background(Color.clear)
    }

    private var stepType: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What are you planning?")
                .font(.system(size: 28, weight: .medium, design: .serif))

            choice("Overseas", "Destination wedding or celebration abroad", input.eventType == .overseas) {
                input.eventType = .overseas
                input.overseasCategory = input.overseasCategory ?? .wedding_ceremony
                input.localCategory = nil
                if input.locationName.isEmpty || input.locationName == "Local Premium Venue" {
                    input.locationName = "Santorini, Greece"
                }
            }

            choice("Local", "Estate, resort, or city venue near you", input.eventType == .local) {
                input.eventType = .local
                input.localCategory = input.localCategory ?? .resort
                input.overseasCategory = nil
                if input.locationName.isEmpty || input.locationName.contains("Santorini") {
                    input.locationName = nearbyVenues.first?.name ?? "Local Premium Venue"
                    if let first = nearbyVenues.first {
                        input.localCategory = first.localCategory
                    }
                }
                Task { await loadNearbyVenues() }
            }

            if input.eventType == .overseas {
                chips("Focus", OverseasCategory.allCases, label: \.label, selection: Binding(
                    get: { input.overseasCategory ?? .wedding_ceremony },
                    set: { input.overseasCategory = $0 }
                ))
            } else {
                chips("Venue mood", LocalCategory.allCases, label: \.label, selection: Binding(
                    get: { input.localCategory ?? .resort },
                    set: { input.localCategory = $0 }
                ))
            }
        }
    }

    private var stepPlace: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Place & scale")
                .font(.system(size: 28, weight: .medium, design: .serif))

            labeled("Location") {
                TextField(
                    input.eventType == .overseas ? "e.g. Santorini" : "e.g. Cotswolds estate",
                    text: $input.locationName
                )
                .padding(12)
                .background(MeridianTheme.paper.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if input.eventType == .local {
                nearbyVenueSection
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Guests · \(input.guestCount)")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(MeridianTheme.ink.opacity(0.5))
                Slider(
                    value: Binding(
                        get: { Double(input.guestCount) },
                        set: { input.guestCount = Int($0) }
                    ),
                    in: 20...400,
                    step: 10
                )
                .tint(MeridianTheme.atlantic)
            }

            labeled("Target month") {
                Picker("Month", selection: $input.targetMonth) {
                    ForEach(PlannerInput.months, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(MeridianTheme.paper.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var stepTone: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Tone & table")
                .font(.system(size: 28, weight: .medium, design: .serif))

            chips("Catering", CateringStyle.allCases, label: \.label, selection: $input.cateringStyle)
            chips("Voice", MessageStyle.allCases, label: \.label, selection: $input.messageStyle)

            labeled("Notes") {
                TextField(
                    "Anything we should know…",
                    text: Binding(
                        get: { input.specialNotes ?? "" },
                        set: { input.specialNotes = $0.isEmpty ? nil : $0 }
                    ),
                    axis: .vertical
                )
                .lineLimit(3...5)
                .padding(12)
                .frame(minHeight: 88, alignment: .topLeading)
                .background(MeridianTheme.paper.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MeridianTheme.ink.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func choice(_ title: String, _ subtitle: String, _ selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 22, weight: .medium, design: .serif))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(selected ? MeridianTheme.paper.opacity(0.8) : MeridianTheme.ink.opacity(0.55))
            }
            .foregroundStyle(selected ? MeridianTheme.paper : MeridianTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassEffect(
                selected
                    ? .regular.tint(MeridianTheme.atlantic)
                    : .regular,
                in: RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.ink.opacity(0.5))
            content()
        }
    }

    private var nearbyVenueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(nearbyCountryName.map { "Near \($0)" } ?? "Local suggestions")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.ink.opacity(0.5))
            Text("Use your location to suggest nearby hotels, beaches, and resorts.")
                .font(.system(size: 12))
                .foregroundStyle(MeridianTheme.ink.opacity(0.45))
            if nearbyLoading {
                ProgressView()
                    .tint(MeridianTheme.atlantic)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(nearbyVenues.prefix(8)) { venue in
                            let active = input.locationName == venue.name
                            Button {
                                input.locationName = venue.name
                                input.localCategory = venue.localCategory
                            } label: {
                                HStack(spacing: 6) {
                                    Text(venue.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                    Text(venue.localCategory.label)
                                        .font(.system(size: 10))
                                        .opacity(0.55)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(active ? MeridianTheme.paper : MeridianTheme.ink)
                                .background(active ? MeridianTheme.ink.opacity(0.85) : MeridianTheme.paper.opacity(0.72))
                                .overlay(
                                    Capsule().stroke(MeridianTheme.ink.opacity(active ? 0 : 0.12), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func loadNearbyVenues() async {
        nearbyLoading = true
        let geo = await LocationService.shared.requestLocale()
        let result = await APIClient.shared.fetchNearbyVenues(country: geo?.countryCode, city: geo?.city)
        nearbyVenues = result.venues
        nearbyCountryName = result.countryName
        nearbyLoading = false
        if input.eventType == .local,
           input.locationName.isEmpty
            || input.locationName == "Local Premium Venue"
            || input.locationName.contains("Santorini"),
           let first = result.venues.first {
            input.locationName = first.name
            input.localCategory = first.localCategory
        }
    }

    private func chips<T: Hashable & Identifiable>(
        _ title: String,
        _ options: [T],
        label: KeyPath<T, String>,
        selection: Binding<T>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.ink.opacity(0.5))
            let rows = stride(from: 0, to: options.count, by: 3).map { Array(options[$0..<min($0 + 3, options.count)]) }
            GlassEffectContainer(spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 8) {
                            ForEach(row) { opt in
                                let isOn = selection.wrappedValue == opt
                                Button {
                                    selection.wrappedValue = opt
                                } label: {
                                    Text(opt[keyPath: label])
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .foregroundStyle(isOn ? MeridianTheme.paper : MeridianTheme.ink.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                                .meridianGlassCapsule(
                                    interactive: false,
                                    tint: isOn ? MeridianTheme.ink : nil
                                )
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }
}
