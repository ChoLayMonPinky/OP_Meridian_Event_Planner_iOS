//
//  SocialMarks.swift
//  ios
//

import SwiftUI

/// Multicolor Google “G” mark for social auth.
struct GoogleMark: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 24
            context.scaleBy(x: scale, y: scale)

            var blue = Path()
            blue.move(to: CGPoint(x: 22.56, y: 12.25))
            blue.addCurve(to: CGPoint(x: 22.36, y: 10), control1: CGPoint(x: 22.56, y: 11.47), control2: CGPoint(x: 22.49, y: 10.72))
            blue.addLine(to: CGPoint(x: 12, y: 10))
            blue.addLine(to: CGPoint(x: 12, y: 14.26))
            blue.addLine(to: CGPoint(x: 17.92, y: 14.26))
            blue.addCurve(to: CGPoint(x: 15.71, y: 17.57), control1: CGPoint(x: 17.66, y: 15.63), control2: CGPoint(x: 16.88, y: 16.79))
            blue.addLine(to: CGPoint(x: 15.71, y: 20.34))
            blue.addLine(to: CGPoint(x: 19.28, y: 20.34))
            blue.addCurve(to: CGPoint(x: 22.56, y: 12.25), control1: CGPoint(x: 21.36, y: 18.42), control2: CGPoint(x: 22.56, y: 15.6))
            blue.closeSubpath()
            context.fill(blue, with: .color(Color(red: 0.259, green: 0.522, blue: 0.957)))

            var green = Path()
            green.move(to: CGPoint(x: 12, y: 23))
            green.addCurve(to: CGPoint(x: 19.28, y: 20.34), control1: CGPoint(x: 14.97, y: 23), control2: CGPoint(x: 17.46, y: 22.02))
            green.addLine(to: CGPoint(x: 15.71, y: 17.57))
            green.addCurve(to: CGPoint(x: 12, y: 18.63), control1: CGPoint(x: 14.73, y: 18.23), control2: CGPoint(x: 13.48, y: 18.63))
            green.addCurve(to: CGPoint(x: 5.84, y: 14.1), control1: CGPoint(x: 9.14, y: 18.63), control2: CGPoint(x: 6.71, y: 16.7))
            green.addLine(to: CGPoint(x: 2.18, y: 16.94))
            green.addCurve(to: CGPoint(x: 12, y: 23), control1: CGPoint(x: 3.99, y: 20.53), control2: CGPoint(x: 7.7, y: 23))
            green.closeSubpath()
            context.fill(green, with: .color(Color(red: 0.204, green: 0.659, blue: 0.325)))

            var yellow = Path()
            yellow.move(to: CGPoint(x: 5.84, y: 14.09))
            yellow.addCurve(to: CGPoint(x: 5.49, y: 12), control1: CGPoint(x: 5.62, y: 13.43), control2: CGPoint(x: 5.49, y: 12.73))
            yellow.addCurve(to: CGPoint(x: 5.84, y: 9.91), control1: CGPoint(x: 5.49, y: 11.27), control2: CGPoint(x: 5.62, y: 10.57))
            yellow.addLine(to: CGPoint(x: 5.84, y: 7.07))
            yellow.addLine(to: CGPoint(x: 2.18, y: 7.07))
            yellow.addCurve(to: CGPoint(x: 1, y: 12), control1: CGPoint(x: 1.43, y: 8.55), control2: CGPoint(x: 1, y: 10.22))
            yellow.addCurve(to: CGPoint(x: 2.18, y: 16.93), control1: CGPoint(x: 1, y: 13.78), control2: CGPoint(x: 1.43, y: 15.45))
            yellow.addLine(to: CGPoint(x: 5.03, y: 14.71))
            yellow.addLine(to: CGPoint(x: 5.84, y: 14.09))
            yellow.closeSubpath()
            context.fill(yellow, with: .color(Color(red: 0.984, green: 0.737, blue: 0.02)))

            var red = Path()
            red.move(to: CGPoint(x: 12, y: 5.38))
            red.addCurve(to: CGPoint(x: 16.21, y: 7.02), control1: CGPoint(x: 13.62, y: 5.38), control2: CGPoint(x: 15.06, y: 5.94))
            red.addLine(to: CGPoint(x: 19.36, y: 3.87))
            red.addCurve(to: CGPoint(x: 12, y: 1), control1: CGPoint(x: 17.45, y: 2.09), control2: CGPoint(x: 14.97, y: 1))
            red.addCurve(to: CGPoint(x: 2.18, y: 7.07), control1: CGPoint(x: 7.7, y: 1), control2: CGPoint(x: 3.99, y: 3.47))
            red.addLine(to: CGPoint(x: 5.84, y: 9.91))
            red.addCurve(to: CGPoint(x: 12, y: 5.38), control1: CGPoint(x: 6.71, y: 7.31), control2: CGPoint(x: 9.14, y: 5.38))
            red.closeSubpath()
            context.fill(red, with: .color(Color(red: 0.918, green: 0.263, blue: 0.208)))
        }
        .accessibilityHidden(true)
    }
}
