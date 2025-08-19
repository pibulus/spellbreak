//
//  CosmicBackground.swift
//  Spellbreak
//
//  Deep space nebula effect with swirling cosmic clouds
//

import SwiftUI

struct CosmicBackground: View {
    @State private var phase: Double = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate * 0.1 // Slower for space vibe
                
                // Deep space background
                let spaceGradient = Gradient(colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.08),  // Almost black with hint of blue
                    Color(red: 0.05, green: 0.0, blue: 0.15),   // Deep space purple
                    Color(red: 0.1, green: 0.05, blue: 0.2)     // Nebula edge
                ])
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .radialGradient(
                        spaceGradient,
                        center: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
                        startRadius: 0,
                        endRadius: size.width
                    )
                )
                
                // Draw nebula clouds and stars
                drawNebulaLayers(context: context, size: size, time: time)
                drawStars(context: context, size: size, time: time)
            }
        }
        .ignoresSafeArea()
    }
    
    private func drawNebulaLayers(context: GraphicsContext, size: CGSize, time: Double) {
        // Layer 1 - Deep purple nebula cloud
        let nebula1CenterX = size.width * 0.3 + sin(time * 0.15) * 50
        let nebula1CenterY = size.height * 0.4 + cos(time * 0.1) * 30
        
        for i in 0..<4 {
            let offset = Double(i) * 50
            let rotation = time * 0.05 + Double(i) * 0.5
            let scale = 1.0 + sin(time * 0.2 + Double(i)) * 0.2
            
            let nebula1Gradient = Gradient(stops: [
                .init(color: Color(red: 0.4, green: 0.1, blue: 0.8).opacity(0.3), location: 0),
                .init(color: Color(red: 0.6, green: 0.2, blue: 0.9).opacity(0.15), location: 0.3),
                .init(color: Color(red: 0.3, green: 0.1, blue: 0.6).opacity(0.05), location: 0.7),
                .init(color: Color.clear, location: 1)
            ])
            
            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: nebula1CenterX, y: nebula1CenterY)
            transform = transform.rotated(by: rotation)
            transform = transform.scaledBy(x: scale, y: scale * 0.7)
            
            context.fill(
                Ellipse().path(in: CGRect(
                    x: -150 - offset/2,
                    y: -100 - offset/2,
                    width: 300 + offset,
                    height: 200 + offset
                )).applying(transform),
                with: .radialGradient(
                    nebula1Gradient,
                    center: CGPoint(x: nebula1CenterX, y: nebula1CenterY),
                    startRadius: 0,
                    endRadius: 200 + offset
                )
            )
        }
        
        // Layer 2 - Blue-cyan nebula wisps
        let nebula2CenterX = size.width * 0.7 + sin(time * 0.12 + 2) * 40
        let nebula2CenterY = size.height * 0.6 + cos(time * 0.15) * 40
        
        for i in 0..<3 {
            let offset = Double(i) * 40
            let rotation = time * -0.03 + Double(i) * 0.8
            
            let nebula2Gradient = Gradient(stops: [
                .init(color: Color(red: 0.1, green: 0.4, blue: 0.9).opacity(0.25), location: 0),
                .init(color: Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.1), location: 0.4),
                .init(color: Color(red: 0.1, green: 0.3, blue: 0.7).opacity(0.03), location: 0.8),
                .init(color: Color.clear, location: 1)
            ])
            
            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: nebula2CenterX, y: nebula2CenterY)
            transform = transform.rotated(by: rotation)
            transform = transform.scaledBy(x: 1.2, y: 0.6)
            
            context.fill(
                Ellipse().path(in: CGRect(
                    x: -120 - offset/2,
                    y: -80 - offset/2,
                    width: 240 + offset,
                    height: 160 + offset
                )).applying(transform),
                with: .radialGradient(
                    nebula2Gradient,
                    center: CGPoint(x: nebula2CenterX, y: nebula2CenterY),
                    startRadius: 0,
                    endRadius: 180 + offset
                )
            )
        }
        
        // Layer 3 - Pink/magenta stellar nursery
        let nebula3CenterX = size.width * 0.5 + sin(time * 0.08) * 30
        let nebula3CenterY = size.height * 0.3 + cos(time * 0.12) * 20
        
        let nebula3Gradient = Gradient(stops: [
            .init(color: Color(red: 0.9, green: 0.3, blue: 0.6).opacity(0.2), location: 0),
            .init(color: Color(red: 1.0, green: 0.4, blue: 0.7).opacity(0.08), location: 0.5),
            .init(color: Color(red: 0.7, green: 0.2, blue: 0.5).opacity(0.02), location: 0.9),
            .init(color: Color.clear, location: 1)
        ])
        
        context.fill(
            Ellipse().path(in: CGRect(
                x: nebula3CenterX - 100,
                y: nebula3CenterY - 70,
                width: 200,
                height: 140
            )),
            with: .radialGradient(
                nebula3Gradient,
                center: CGPoint(x: nebula3CenterX, y: nebula3CenterY),
                startRadius: 0,
                endRadius: 150
            )
        )
    }
    
    private func drawStars(context: GraphicsContext, size: CGSize, time: Double) {
        // Bright stars with twinkling
        let starPositions = [
            (0.2, 0.3), (0.8, 0.2), (0.5, 0.7), (0.3, 0.8), (0.7, 0.5),
            (0.1, 0.6), (0.9, 0.4), (0.4, 0.2), (0.6, 0.9), (0.15, 0.15)
        ]
        
        for (i, pos) in starPositions.enumerated() {
            let twinkle = sin(time * 2 + Double(i) * 1.5) * 0.5 + 0.5
            let starX = size.width * pos.0
            let starY = size.height * pos.1
            let starSize = 2 + twinkle * 2
            
            // Star glow
            let glowGradient = Gradient(stops: [
                .init(color: Color.white.opacity(0.9 * twinkle), location: 0),
                .init(color: Color(red: 0.8, green: 0.8, blue: 1.0).opacity(0.3 * twinkle), location: 0.3),
                .init(color: Color.clear, location: 1)
            ])
            
            context.fill(
                Circle().path(in: CGRect(
                    x: starX - starSize * 3,
                    y: starY - starSize * 3,
                    width: starSize * 6,
                    height: starSize * 6
                )),
                with: .radialGradient(
                    glowGradient,
                    center: CGPoint(x: starX, y: starY),
                    startRadius: 0,
                    endRadius: starSize * 3
                )
            )
            
            // Star core
            context.fill(
                Circle().path(in: CGRect(
                    x: starX - starSize/2,
                    y: starY - starSize/2,
                    width: starSize,
                    height: starSize
                )),
                with: .color(.white)
            )
        }
        
        // Distant star field
        for i in 0..<30 {
            let seed = Double(i)
            let x = size.width * (seed.truncatingRemainder(dividingBy: 1.0) * 1.618) // Golden ratio distribution
            let y = size.height * ((seed * 2.718).truncatingRemainder(dividingBy: 1.0))
            let brightness = 0.3 + (seed * 3.14).truncatingRemainder(dividingBy: 0.5)
            
            context.fill(
                Circle().path(in: CGRect(x: x, y: y, width: 1, height: 1)),
                with: .color(Color.white.opacity(brightness))
            )
        }
    }
}