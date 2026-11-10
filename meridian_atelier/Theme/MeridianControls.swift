//
//  MeridianControls.swift
//  ios
//

import SwiftUI

enum MeridianMotion {
    /// ~180ms — chips, presses
    static let quick = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.18)
    /// ~280–340ms — pane / form swaps (matches web Club ease)
    static let soft = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.32)
    /// ~480ms — first paint / hero
    static let entrance = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.48)
}

struct MeridianPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(MeridianMotion.quick, value: configuration.isPressed)
    }
}

struct MeridianPhaseChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    init(_ title: String, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.selected = selected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: selected ? .semibold : .medium))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(selected ? MeridianTheme.paper : MeridianTheme.ink.opacity(0.7))
        }
        .buttonStyle(.plain)
        .meridianGlassCapsule(
            interactive: false,
            tint: selected ? MeridianTheme.ink : nil
        )
    }
}

/// Full-width Liquid Glass CTA — avoids `.glassProminent` width-shrink bugs.
struct MeridianPrimaryButton: View {
    let title: String
    var atlantic: Bool = false
    var paperOnInk: Bool = false
    var busy: Bool = false
    let action: () -> Void

    private var tint: Color {
        if paperOnInk { return MeridianTheme.paper.opacity(0.92) }
        return atlantic ? MeridianTheme.atlantic : MeridianTheme.ink
    }

    var body: some View {
        Button(action: action) {
            Text(busy ? "Please wait…" : title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(paperOnInk ? MeridianTheme.ink : MeridianTheme.paper)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous))
        .glassEffect(
            .regular.tint(tint).interactive(),
            in: RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
        )
        .disabled(busy)
    }
}

struct MeridianGhostButton: View {
    let title: String
    var light: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(light ? MeridianTheme.paper : MeridianTheme.ink)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous))
        .glassEffect(
            .regular.interactive(),
            in: RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
        )
        .opacity(light ? 0.95 : 1)
    }
}

/// Segment control — one shared glass capsule; selection is ink wash, not nested glass.
struct MeridianModeTab: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    init(_ title: String, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.selected = selected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? MeridianTheme.ink : MeridianTheme.ink.opacity(0.45))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule(style: .continuous)
                        .fill(selected ? MeridianTheme.atlantic.opacity(0.28) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .animation(MeridianMotion.quick, value: selected)
    }
}

struct MeridianLabeledField<Field: View>: View {
    let title: String
    var error: String? = nil
    @ViewBuilder var field: () -> Field

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(MeridianTheme.ink.opacity(0.5))
            field()
                .padding(12)
                .background(MeridianTheme.paper.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            error == nil ? MeridianTheme.ink.opacity(0.12) : Color.red.opacity(0.45),
                            lineWidth: 1
                        )
                        .animation(MeridianMotion.quick, value: error != nil)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            if let error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.8))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(MeridianMotion.quick, value: error)
    }
}

extension View {
    func meridianInputSurface(isError: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        return self
            .background(
                shape.fill(Color.white)
            )
            .overlay {
                shape
                    .stroke(
                        isError ? Color.red.opacity(0.45) : MeridianTheme.ink.opacity(0.12),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
        // Do not clipShape — SecureField uses a system overlay that
        // stops accepting keystrokes when the field is clipped.
    }

    /// Full-width glass CTA used by screens that build custom labels.
    func meridianGlassProminent(tint: Color = MeridianTheme.ink) -> some View {
        let shape = RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
        return self
            .buttonStyle(.plain)
            .contentShape(shape)
            .glassEffect(.regular.tint(tint).interactive(), in: shape)
    }

    func meridianGlassRegular(clear: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: MeridianGlass.panelRadius, style: .continuous)
        return self
            .buttonStyle(.plain)
            .contentShape(shape)
            .glassEffect(
                clear ? .clear.interactive() : .regular.interactive(),
                in: shape
            )
    }
}
