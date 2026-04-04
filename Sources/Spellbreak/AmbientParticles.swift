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
    var lifetime: Double
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
                for particle in particles {
                    let x = particle.x * size.width
                    let y = particle.y * size.height
                    
                    // Simple glow effect
                    let gradient = Gradient(stops: [
                        .init(color: particleColors[0].opacity(particle.opacity), location: 0),
                        .init(color: particleColors[1].opacity(particle.opacity * 0.55), location: 0.5),
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
                    
                    // Add blur for depth
                    context.addFilter(.blur(radius: 2))
                }
            }
            .drawingGroup()
            .onAppear {
                setupParticles()
            }
            .onChange(of: timeline.date) { _ in
                updateParticles()
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
                vx: Double.random(in: -0.001...0.001),
                vy: Double.random(in: -0.0015...0.0005),
                size: CGFloat.random(in: 20...40),  // Bigger particles
                opacity: Double.random(in: 0.2...0.5),  // More visible
                lifetime: Double.random(in: 0...1)
            )
        }
    }
    
    private func updateParticles() {
        for i in particles.indices {
            // Update position
            particles[i].x += particles[i].vx
            particles[i].y += particles[i].vy
            
            // Wrap around edges smoothly
            if particles[i].x < -0.05 { particles[i].x = 1.05 }
            if particles[i].x > 1.05 { particles[i].x = -0.05 }
            if particles[i].y < -0.05 { particles[i].y = 1.05 }
            if particles[i].y > 1.05 { particles[i].y = -0.05 }
            
            // Update lifetime for fade effect
            particles[i].lifetime += 0.005
            if particles[i].lifetime > 1 {
                particles[i].lifetime = 0
                particles[i].opacity = Double.random(in: 0.1...0.3)
            }
            
            // More dramatic pulsing
            let pulseMultiplier = visualTheme == "cosmic" ? 1.35 : 1.0
            particles[i].opacity = (0.3 + sin(particles[i].lifetime * .pi) * 0.2) * pulseMultiplier
        }
    }
}
