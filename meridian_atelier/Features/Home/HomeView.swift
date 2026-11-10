//
//  HomeView.swift
//  ios
//
//  Explore tab — Trip/Agoda-style browse (destinations + nearby venues).
//

import SwiftUI

struct HomeView: View {
    @Environment(PlanStore.self) private var store
    @State private var revealed = false
    @State private var destinations: [ExploreDestination] = DestinationsCatalog.trendingToday().destinations
    @State private var trendingLabel = "Trending today"
    @State private var nearbyVenues: [CuratedVenue] = []
    @State private var nearbyCountry: String?
    @State private var nearbyLoading = false
    @State private var locationDenied = false
    @State private var usingFallback = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                destinationsSection
                nearby
            }
        }
        .background {
            MeridianAmbientBackground()
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            withAnimation(MeridianMotion.entrance) {
                revealed = true
            }
            Task {
                async let trend: Void = loadTrending()
                async let near: Void = loadNearby()
                _ = await (trend, near)
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Image("LandingHero")
                .resizable()
                .scaledToFill()
                .frame(height: 420)
                .frame(maxWidth: .infinity)
                .clipped()
                .scaleEffect(revealed ? 1.0 : 1.035)
                .animation(MeridianMotion.entrance, value: revealed)

            LinearGradient(
                colors: [
                    .clear,
                    MeridianTheme.ink.opacity(0.18),
                    MeridianTheme.ink.opacity(0.55),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("EXPLORE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(MeridianTheme.paper.opacity(0.7))

                Text(AppConfig.brandName)
                    .font(.system(size: 40, weight: .medium, design: .serif))
                    .foregroundStyle(MeridianTheme.paper)

                Text("Browse destinations and venues — then build your plan.")
                    .font(.system(size: 15))
                    .foregroundStyle(MeridianTheme.paper.opacity(0.88))
                    .frame(maxWidth: 280, alignment: .leading)

                if let plan = store.activePlan {
                    Button {
                        store.openPlan(phase: .proposal)
                    } label: {
                        labelRow("Continue “\(plan.title.prefix(24))\(plan.title.count > 24 ? "…" : "")”")
                    }
                    .meridianGlassProminent(tint: MeridianTheme.paper)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
            .padding(.top, 72)
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 14)
        }
        .frame(height: 420)
        .frame(maxWidth: .infinity)
    }

    private var destinationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(trendingLabel.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundStyle(MeridianTheme.atlantic)

            Text("Destinations")
                .font(.system(size: 26, weight: .medium, design: .serif))
                .foregroundStyle(MeridianTheme.ink)

            Text("Refreshes daily · tap a place to start an overseas plan.")
                .font(.system(size: 14))
                .foregroundStyle(MeridianTheme.ink.opacity(0.5))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(destinations.enumerated()), id: \.element.id) { index, dest in
                        Button {
                            var seed = PlannerInput.starter(eventType: .overseas)
                            seed.locationName = dest.locationName
                            store.startNewPlan(seed: seed)
                        } label: {
                            destinationCard(dest)
                        }
                        .buttonStyle(MeridianPressStyle())
                        .opacity(revealed ? 1 : 0)
                        .offset(y: revealed ? 0 : 12)
                        .animation(MeridianMotion.entrance.delay(0.04 * Double(index)), value: revealed)
                    }
                }
                .padding(.trailing, 24)
                .padding(.vertical, 2)
            }
            .padding(.horizontal, -24)
            .padding(.leading, 24)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nearbySubtitle: String {
        if nearbyLoading { return "Finding hotels, beaches, and resorts near you…" }
        if locationDenied {
            return nearbyVenues.isEmpty
                ? "Location is blocked. Enable it in Settings, or browse curated picks."
                : "Location off — showing curated picks you can browse anyway."
        }
        if let nearbyCountry {
            return usingFallback
                ? "Curated picks in \(nearbyCountry)."
                : "Curated venues in \(nearbyCountry)."
        }
        return "Allow location to suggest hotels, beaches, and resorts."
    }

    private var nearby: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text("Near you")
                    .font(.system(size: 26, weight: .medium, design: .serif))
                    .foregroundStyle(MeridianTheme.ink)
                if nearbyLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if locationDenied {
                    Image(systemName: "location.slash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.35))
                } else if nearbyCountry != nil {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MeridianTheme.atlantic)
                }
                Spacer()
            }

            Text(nearbySubtitle)
                .font(.system(size: 14))
                .foregroundStyle(MeridianTheme.ink.opacity(0.5))

            if nearbyLoading && nearbyVenues.isEmpty {
                VStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(MeridianTheme.ink.opacity(0.06))
                                .frame(width: 72, height: 72)
                            VStack(alignment: .leading, spacing: 8) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(MeridianTheme.ink.opacity(0.06))
                                    .frame(height: 14)
                                    .frame(maxWidth: 160)
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(MeridianTheme.ink.opacity(0.04))
                                    .frame(height: 10)
                                    .frame(maxWidth: 110)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
                                .fill(MeridianTheme.paper.opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
                                .stroke(MeridianTheme.ink.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            } else if nearbyVenues.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        Task { await loadNearby(force: true) }
                    } label: {
                        Text(locationDenied ? "Try location again" : "Find venues near me")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MeridianTheme.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .meridianGlassProminent(tint: MeridianTheme.ink)

                    Text("Or pick a destination above to start planning without GPS.")
                        .font(.system(size: 12))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.4))
                }
            } else {
                if locationDenied {
                    Button {
                        Task { await loadNearby(force: true) }
                    } label: {
                        Text("Retry location")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MeridianTheme.atlantic)
                    }
                    .buttonStyle(.plain)
                }

                LazyVStack(spacing: 10) {
                    ForEach(nearbyVenues.prefix(6)) { venue in
                        Button {
                            var seed = PlannerInput.starter(eventType: .local)
                            seed.locationName = venue.name
                            seed.localCategory = venue.localCategory
                            store.startNewPlan(seed: seed)
                        } label: {
                            venueRow(venue)
                        }
                        .buttonStyle(MeridianPressStyle())
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 108)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func destinationCard(_ dest: ExploreDestination) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(dest.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 188, height: 220)
                .clipped()

            LinearGradient(
                colors: [
                    .clear,
                    MeridianTheme.ink.opacity(0.12),
                    MeridianTheme.ink.opacity(0.58),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(dest.region.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(MeridianTheme.paper.opacity(0.78))
                Text(dest.name)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(MeridianTheme.paper)
                Text(dest.blurb)
                    .font(.system(size: 12))
                    .foregroundStyle(MeridianTheme.paper.opacity(0.85))
                    .lineLimit(2)
                    .frame(maxWidth: 160, alignment: .leading)
            }
            .padding(14)
        }
        .frame(width: 188, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous))
        .shadow(color: MeridianTheme.ink.opacity(0.12), radius: 10, x: 0, y: 6)
    }

    private func venueRow(_ venue: CuratedVenue) -> some View {
        HStack(alignment: .center, spacing: 12) {
            venueThumbView(venue)
                .frame(width: 72, height: 72)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(venue.name)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(MeridianTheme.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text("\(venue.city) · \(venue.localCategory.label)")
                    .font(.system(size: 12))
                    .foregroundStyle(MeridianTheme.ink.opacity(0.45))
            }
            Spacer(minLength: 8)
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MeridianTheme.ink.opacity(0.35))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
                .fill(MeridianTheme.paper.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
                .stroke(MeridianTheme.ink.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func venueThumbView(_ venue: CuratedVenue) -> some View {
        if let asset = VenueImageCatalog.assetName(for: venue.id) {
            Image(asset)
                .resizable()
                .scaledToFill()
        } else if let raw = venue.imageUrl, let url = resolvedVenueURL(raw) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(venueThumbFallback(for: venue.localCategory))
                        .resizable()
                        .scaledToFill()
                case .empty:
                    MeridianTheme.ink.opacity(0.06)
                        .overlay { ProgressView().controlSize(.mini) }
                @unknown default:
                    Image(venueThumbFallback(for: venue.localCategory))
                        .resizable()
                        .scaledToFill()
                }
            }
        } else {
            Image(venueThumbFallback(for: venue.localCategory))
                .resizable()
                .scaledToFill()
        }
    }

    private func resolvedVenueURL(_ raw: String) -> URL? {
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
            return URL(string: raw)
        }
        if raw.hasPrefix("/") {
            let base = AppConfig.apiBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return URL(string: base + raw)
        }
        return URL(string: raw)
    }

    private func venueThumbFallback(for category: LocalCategory) -> String {
        switch category {
        case .hotel: return "DestCover"
        case .beach: return "DestBeach"
        case .resort: return "DestResort"
        case .restaurant: return "DestDining"
        }
    }

    private func labelRow(_ title: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            Spacer(minLength: 8)
            Image(systemName: "arrow.right")
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(MeridianTheme.ink)
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity)
    }

    private func loadNearby(force: Bool = false) async {
        if nearbyLoading { return }
        if !force, !nearbyVenues.isEmpty { return }
        nearbyLoading = true
        defer { nearbyLoading = false }
        let geo = await LocationService.shared.requestLocale()
        locationDenied = geo == nil
        let result = await APIClient.shared.fetchNearbyVenues(country: geo?.countryCode, city: geo?.city)
        nearbyCountry = result.countryName
        nearbyVenues = result.venues
        usingFallback = geo == nil
    }

    private func loadTrending() async {
        let result = await APIClient.shared.fetchTrendingDestinations()
        destinations = result.destinations
        trendingLabel = result.label
    }
}
