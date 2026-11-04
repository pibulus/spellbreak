//
//  AuroraBackground.swift
//  Spellbreak
//
//  Animated gradient wave background with time-based color palettes.
//  Creates flowing organic effects using Canvas and TimelineView.
//

import SwiftUI

// MARK: - Aurora Palette
/// The colour a break wears. Aurora's signature move is time-awareness — it
/// dawns rose-gold, runs golden through the day, burns at sunset, and goes
/// violet at night. Ember and Violet pin that spectrum to one end so a break
/// can feel warm (or cool) at any hour, while Surprise rolls a fresh analogous
/// jewel-tone harmony on every break.
enum AuroraPalette: Equatable {
    case time
    case ember
    case violet
    case harmonious(seedHue: Double, spread: Double)

    /// Curated jewel-tone harmonic arcs (skipping muddy olive/chartreuse) so every
    /// Surprise break rolls a distinct, lush 4-layer aurora across all displays.
    static func rollHarmoniousDescriptor() -> String {
        let families: [(hueRange: ClosedRange<Double>, spreadRange: ClosedRange<Double>)] = [
            (0.90...0.98, -0.075 ... -0.055), // Rose-dusk → orchid → indigo
            (0.49...0.56,  0.065 ...  0.085), // Sea-glass teal → sapphire → ultraviolet
            (0.07...0.11, -0.045 ... -0.035), // Honey-apricot → sunset coral → wine-plum
            (0.70...0.77,  0.080 ...  0.105), // Starlight periwinkle → orchid → warm rose
            (0.43...0.48,  0.075 ...  0.095), // Northern borealis jade → cerulean → twilight
            (0.95...1.02, -0.065 ... -0.050)  // Pomegranate → berry magenta → aubergine
        ]
        let pick = families.randomElement() ?? families[0]
        let hue = Double.random(in: pick.hueRange)
        let spread = Double.random(in: pick.spreadRange)
        return String(format: "surprise:%.4f:%.4f", hue, spread)
    }

    /// Maps a stored or rolled `visualTheme` string to a concrete palette.
    static func from(theme: String) -> AuroraPalette {
        if theme.hasPrefix("surprise:") {
            let parts = theme.split(separator: ":")
            if parts.count == 3,
               let hue = Double(parts[1]),
               let spread = Double(parts[2]),
               hue.isFinite, spread.isFinite {
                return .harmonious(seedHue: hue, spread: spread)
            }
        }
        switch theme {
        case "ember": return .ember
        case "violet": return .violet
        case "random":
            return from(theme: rollHarmoniousDescriptor())
        default: return .time
        }
    }

    private static func wrapHue(_ h: Double) -> Double {
        let mod = h.truncatingRemainder(dividingBy: 1.0)
        return mod < 0 ? mod + 1.0 : mod
    }

    var glowColor: Color {
        switch self {
        case .ember:
            return Color(red: 1.0, green: 0.62, blue: 0.4)
        case .violet:
            return Color(red: 0.48, green: 0.30, blue: 1.0)
        case .time:
            return Color(red: 0.98, green: 0.46, blue: 0.78)
        case let .harmonious(seedHue, spread):
            return Color(hue: Self.wrapHue(seedHue + spread * 0.5), saturation: 0.72, brightness: 0.98)
        }
    }

    var particleColors: [Color] {
        switch self {
        case .ember:
            return [
                Color(red: 1.0, green: 0.75, blue: 0.45),
                Color(red: 1.0, green: 0.45, blue: 0.20)
            ]
        case .violet:
            return [
                Color(red: 0.60, green: 0.50, blue: 1.0),
                Color(red: 0.42, green: 0.36, blue: 1.0)
            ]
        case .time:
            return [
                Color(red: 0.99, green: 0.96, blue: 0.92),
                Color(red: 1.0, green: 0.6, blue: 0.4)
            ]
        case let .harmonious(seedHue, spread):
            return [
                Color(hue: Self.wrapHue(seedHue), saturation: 0.45, brightness: 1.0),
                Color(hue: Self.wrapHue(seedHue + spread), saturation: 0.78, brightness: 0.95)
            ]
        }
    }

    static func harmoniousColors(seedHue: Double, spread: Double) -> [Color] {
        [
            Color(hue: wrapHue(seedHue), saturation: 0.78, brightness: 0.98),
            Color(hue: wrapHue(seedHue + spread), saturation: 0.84, brightness: 0.92),
            Color(hue: wrapHue(seedHue + spread * 2.0), saturation: 0.78, brightness: 0.78),
            Color(hue: wrapHue(seedHue + spread * 2.7), saturation: 0.82, brightness: 0.46)
        ]
    }
}

// MARK: - Aurora Background
/// Animated gradient background with flowing wave effect.
/// Renders a serene static aurora when Reduce Motion is enabled.
struct AuroraBackground: View {
    var palette: AuroraPalette = .time
    var frameInterval: TimeInterval = 1.0 / 30.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var timeColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<10: // Dawn - rich rose gold
            return [
                Color(red: 1.0, green: 0.55, blue: 0.4),   // Rose gold
                Color(red: 0.95, green: 0.4, blue: 0.62),  // Deep rose
                Color(red: 0.72, green: 0.35, blue: 0.9),  // Violet
                Color(red: 0.4, green: 0.18, blue: 0.55)   // Deep plum
            ]
        case 10..<17: // Day - vibrant energy
            return [
                Color(red: 1.0, green: 0.62, blue: 0.15),  // Rich gold
                Color(red: 0.96, green: 0.44, blue: 0.32), // Coral
                Color(red: 0.88, green: 0.27, blue: 0.62), // Magenta
                Color(red: 0.36, green: 0.16, blue: 0.68)  // Royal purple
            ]
        case 17..<21: // Evening - sunset vibes
            return [
                Color(red: 1.0, green: 0.42, blue: 0.22),  // Sunset orange
                Color(red: 0.94, green: 0.31, blue: 0.61), // Hot magenta-pink
                Color(red: 0.68, green: 0.18, blue: 0.66), // Deep magenta
                Color(red: 0.28, green: 0.09, blue: 0.48)  // Twilight purple
            ]
        default: // Night - jewel tones
            return [
                Color(red: 0.66, green: 0.30, blue: 0.98), // Electric purple
                Color(red: 0.94, green: 0.31, blue: 0.61), // Hot magenta-pink
                Color(red: 0.94, green: 0.58, blue: 0.37), // Coral glow
                Color(red: 0.30, green: 0.12, blue: 0.55)  // Deep violet
            ]
        }
    }

    private var emberColors: [Color] {
        [
            Color(red: 1.00, green: 0.75, blue: 0.25),  // Amber
            Color(red: 1.00, green: 0.45, blue: 0.10),  // Orange
            Color(red: 0.92, green: 0.25, blue: 0.18),  // Coral red
            Color(red: 0.50, green: 0.10, blue: 0.14)   // Deep wine
        ]
    }

    private var violetColors: [Color] {
        [
            Color(red: 0.42, green: 0.36, blue: 1.00),  // Blue-violet
            Color(red: 0.58, green: 0.18, blue: 0.98),  // Violet
            Color(red: 0.30, green: 0.14, blue: 0.88),  // Deep purple
            Color(red: 0.11, green: 0.07, blue: 0.42)   // Indigo
        ]
    }

    private var paletteColors: [Color] {
        switch palette {
        case .ember: return emberColors
        case .violet: return violetColors
        case .time: return timeColors
        case let .harmonious(seedHue, spread):
            return AuroraPalette.harmoniousColors(seedHue: seedHue, spread: spread)
        }
    }

    var body: some View {
        Group {
            if reduceMotion {
                auroraCanvas(at: 42.0)
            } else {
                TimelineView(.animation(minimumInterval: frameInterval)) { timeline in
                    auroraCanvas(at: timeline.date.timeIntervalSinceReferenceDate * 0.3)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func auroraCanvas(at time: Double) -> some View {
        let colors = paletteColors
        return Canvas { context, size in
            for layer in 0..<4 {
                let layerOffset = Double(layer) * 0.5
                let speed = 0.2 + Double(layer) * 0.15
                let opacity = 0.68 - Double(layer) * 0.12

                let waveAmplitude = size.height * (0.25 + Double(layer) * 0.05)
                let waveFrequency = 1.2 + Double(layer) * 0.4

                var path = Path()
                path.move(to: CGPoint(x: 0, y: size.height))

                for x in stride(from: 0, through: size.width, by: 6) {
                    let relativeX = x / size.width

                    let wave1 = sin((relativeX * waveFrequency + time * speed + layerOffset) * .pi * 2) * waveAmplitude
                    let wave2 = sin((relativeX * 3.7 + time * speed * 0.8) * .pi) * waveAmplitude * 0.4
                    let wave3 = cos((relativeX * 5.3 + time * speed * 0.4) * .pi) * waveAmplitude * 0.2

                    let y = size.height * 0.5 + wave1 + wave2 + wave3
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.closeSubpath()

                let gradient = Gradient(stops: [
                    .init(color: colors[layer % 4].opacity(opacity), location: 0),
                    .init(color: colors[(layer + 1) % 4].opacity(opacity * 0.8), location: 0.4),
                    .init(color: colors[(layer + 2) % 4].opacity(opacity * 0.5), location: 0.7),
                    .init(color: colors[(layer + 3) % 4].opacity(opacity * 0.2), location: 1)
                ])

                // Fold outer blur radius directly into the layer blur so OverlayWindow
                // needs only one Metal offscreen pass instead of two full-screen blurs.
                context.drawLayer { layerContext in
                    layerContext.addFilter(.blur(radius: 18 + CGFloat(layer) * 14))
                    layerContext.fill(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: CGPoint(x: size.width * 0.3, y: 0),
                            endPoint: CGPoint(x: size.width * 0.7, y: size.height)
                        )
                    )
                }
            }

            drawLightRibbons(context: context, size: size, time: time, colors: colors)
        }
        .drawingGroup()
    }

    private func drawLightRibbons(context: GraphicsContext, size: CGSize, time: Double, colors: [Color]) {
        for ribbon in 0..<3 {
            let offset = Double(ribbon) * 0.28
            let speed = 0.12 + Double(ribbon) * 0.06
            let amplitude = size.height * (0.12 + Double(ribbon) * 0.035)
            let baseline = size.height * (0.36 + Double(ribbon) * 0.09)

            var path = Path()
            var didMove = false

            for x in stride(from: 0, through: size.width, by: 8) {
                let relativeX = x / size.width
                let wave = sin((relativeX * 1.8 + time * speed + offset) * .pi * 2) * amplitude
                let shimmer = cos((relativeX * 4.6 + time * speed * 0.6) * .pi * 2) * amplitude * 0.22
                let point = CGPoint(x: x, y: baseline + wave + shimmer)

                if didMove {
                    path.addLine(to: point)
                } else {
                    path.move(to: point)
                    didMove = true
                }
            }

            let gradient = Gradient(stops: [
                .init(color: Color.clear, location: 0),
                .init(color: colors[(ribbon + 1) % colors.count].opacity(0.42), location: 0.28),
                .init(color: Color.spellCream.opacity(0.20), location: 0.5),
                .init(color: colors[(ribbon + 2) % colors.count].opacity(0.36), location: 0.72),
                .init(color: Color.clear, location: 1)
            ])

            context.drawLayer { layerContext in
                layerContext.addFilter(.blur(radius: 10 + CGFloat(ribbon) * 3))
                layerContext.stroke(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: 0, y: baseline),
                        endPoint: CGPoint(x: size.width, y: baseline)
                    ),
                    style: StrokeStyle(lineWidth: 22 - CGFloat(ribbon) * 4, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}
