//
//  WeatherContingencyCard.swift
//  ios
//

import SwiftUI

struct WeatherContingencyCard: View {
    let forecast: WeatherForecast

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Weather & contingency", systemImage: "cloud.sun")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.atlantic)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(forecast.temperatureAvg)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(MeridianTheme.ink)
                Text("· \(forecast.conditions)")
                    .font(.system(size: 14))
                    .foregroundStyle(MeridianTheme.ink.opacity(0.55))
            }

            Text(forecast.advice)
                .font(.system(size: 14))
                .foregroundStyle(MeridianTheme.ink.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: forecast.indoorContingencyNeeded ? "exclamationmark.shield" : "checkmark.shield")
                    .foregroundStyle(MeridianTheme.atlantic)
                VStack(alignment: .leading, spacing: 2) {
                    Text(forecast.indoorContingencyNeeded ? "Indoor backup recommended" : "Outdoor-friendly outlook")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MeridianTheme.ink)
                    Text(forecast.contingencyPlan)
                        .font(.system(size: 12))
                        .foregroundStyle(MeridianTheme.ink.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MeridianTheme.atlantic.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MeridianTheme.paper.opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
                .stroke(MeridianTheme.ink.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous))
    }
}
