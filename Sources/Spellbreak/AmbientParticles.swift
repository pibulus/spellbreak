//
//  AmbientParticles.swift
//  Spellbreak
//
//  Floating particle system for atmospheric depth.
//

import SwiftUI

// MARK: - Particle Model
struct Particle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var size: CGFloat
    var opacity: Double
    var phase: Double
    var pulseSpeed: Double
}

// MARK: - Ambient Particles
/// Minimal floating orb system for dreamy vibes
struct AmbientParticles: View {
    @State private var particles: [Particle] = []
    @AppStorage("visualTheme") private var visualTheme: String = "aurora"

    private var particleColors: [Color] {
        switch visualTheme {
        case "lava":
            return [
                Color(red: 1.0, green: 0.65, blue: 0.35),
                Color(red: 1.0, green: 0.35, blue: 0.45)
            ]
        case "cosmic":
            return [
                Color(red: 0.8, green: 0.9, blue: 1.0),
                Color(red: 0.45, green: 0.65, blue: 1.0)
            ]
        default:
            return [
                Color.white,
                Color(red: 1.0, green: 0.7, blue: 0.55)
            ]
        }
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let x = wrapped(particle.x + time * particle.vx) * size.width
                    let y = wrapped(particle.y + time * particle.vy) * size.height
                    let pulse = sin((time * particle.pulseSpeed + particle.phase) * .pi * 2) * 0.5 + 0.5
                    let themeMultiplier = visualTheme == "cosmic" ? 1.25 : 1.0
                    let opacity = min((particle.opacity + pulse * 0.16) * themeMultiplier, 0.7)
                    
                    // Simple glow effect
                    let gradient = Gradient(stops: [
                        .init(color: particleColors[0].opacity(opacity), location: 0),
                        .init(color: particleColors[1].opacity(opacity * 0.55), location: 0.5),
                        .init(color: Color.clear, location: 1)
                    ])
                    
                    context.fill(
                        Circle().path(in: CGRect(
                            x: x - particle.size/2,
                            y: y - particle.size/2,
                            width: particle.size,
                            height: particle.size
                        )),
                        with: .radialGradient(
                            gradient,
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: particle.size/2
                        )
                    )
                }
            }
            .drawingGroup()
            .onAppear {
                setupParticles()
            }
            .onChange(of: visualTheme) { _ in
                setupParticles()
            }
        }
    }
    
    private func setupParticles() {
        let count: Int
        switch visualTheme {
        case "cosmic":
            count = 24
        case "lava":
            count = 18
        default:
            count = 15
        }

        particles = (0..<count).map { _ in
            Particle(
                x: Double.random(in: 0...1),
                y: Double.random(in: 0...1),
                vx: Double.random(in: -0.015...0.015),
                vy: Double.random(in: -0.025...0.008),
                size: CGFloat.random(in: 20...40),  // Bigger particles
                opacity: Double.random(in: 0.18...0.36),  // More visible
                phase: Double.random(in: 0...1),
                pulseSpeed: Double.random(in: 0.08...0.18)
            )
        }
    }

    private func wrapped(_ value: Double) -> Double {
        let range = 1.1
        let shifted = (value + 0.05).truncatingRemainder(dividingBy: range)
        return (shifted >= 0 ? shifted : shifted + range) - 0.05
    }
}
