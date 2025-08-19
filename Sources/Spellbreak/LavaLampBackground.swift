//
//  LavaLampBackground.swift
//  Spellbreak
//
//  Retro 70s lava lamp effect with morphing blobs
//

import SwiftUI

struct LavaLampBackground: View {
    @State private var phase: Double = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // Deep retro background gradient
                let backgroundGradient = Gradient(colors: [
                    Color(red: 0.15, green: 0.05, blue: 0.25),  // Deep purple
                    Color(red: 0.3, green: 0.1, blue: 0.2)      // Wine
                ])
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        backgroundGradient,
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )
                
                // Draw morphing lava blobs
                drawLavaBlobs(context: context, size: size, time: time)
            }
        }
        .ignoresSafeArea()
    }
    
    private func drawLavaBlobs(context: GraphicsContext, size: CGSize, time: Double) {
        // Blob 1 - Large, slow orange-pink blob
        let blob1X = size.width * 0.3 + sin(time * 0.3) * size.width * 0.2
        let blob1Y = size.height * 0.5 + sin(time * 0.2) * size.height * 0.3
        let blob1Radius = 120 + sin(time * 0.4) * 40
        
        let blob1Gradient = Gradient(stops: [
            .init(color: Color(red: 1.0, green: 0.3, blue: 0.4).opacity(0.8), location: 0),
            .init(color: Color(red: 1.0, green: 0.5, blue: 0.2).opacity(0.6), location: 0.5),
            .init(color: Color(red: 0.9, green: 0.2, blue: 0.5).opacity(0.4), location: 1)
        ])
        
        // Morphing shape using multiple circles
        for i in 0..<3 {
            let offsetX = sin(time * 0.3 + Double(i)) * 30
            let offsetY = cos(time * 0.4 + Double(i)) * 30
            let morphRadius = blob1Radius + sin(time * 0.5 + Double(i) * 1.5) * 20
            
            context.fill(
                Circle().path(in: CGRect(
                    x: blob1X + offsetX - morphRadius/2,
                    y: blob1Y + offsetY - morphRadius/2,
                    width: morphRadius,
                    height: morphRadius
                )),
                with: .radialGradient(
                    blob1Gradient,
                    center: CGPoint(x: blob1X + offsetX, y: blob1Y + offsetY),
                    startRadius: 0,
                    endRadius: morphRadius
                )
            )
        }
        
        // Blob 2 - Medium purple-pink blob
        let blob2X = size.width * 0.7 + sin(time * 0.25 + 2) * size.width * 0.15
        let blob2Y = size.height * 0.3 + sin(time * 0.35) * size.height * 0.2
        let blob2Radius = 90 + sin(time * 0.3 + 1) * 30
        
        let blob2Gradient = Gradient(stops: [
            .init(color: Color(red: 0.8, green: 0.3, blue: 0.9).opacity(0.7), location: 0),
            .init(color: Color(red: 1.0, green: 0.4, blue: 0.8).opacity(0.5), location: 0.5),
            .init(color: Color(red: 0.6, green: 0.2, blue: 0.8).opacity(0.3), location: 1)
        ])
        
        for i in 0..<2 {
            let offsetX = sin(time * 0.4 + Double(i) * 2) * 25
            let offsetY = cos(time * 0.35 + Double(i) * 2) * 25
            let morphRadius = blob2Radius + sin(time * 0.45 + Double(i)) * 15
            
            context.fill(
                Circle().path(in: CGRect(
                    x: blob2X + offsetX - morphRadius/2,
                    y: blob2Y + offsetY - morphRadius/2,
                    width: morphRadius,
                    height: morphRadius
                )),
                with: .radialGradient(
                    blob2Gradient,
                    center: CGPoint(x: blob2X + offsetX, y: blob2Y + offsetY),
                    startRadius: 0,
                    endRadius: morphRadius
                )
            )
        }
        
        // Blob 3 - Small hot pink accent
        let blob3X = size.width * 0.5 + sin(time * 0.45) * size.width * 0.3
        let blob3Y = size.height * 0.7 + sin(time * 0.25 + 3) * size.height * 0.15
        let blob3Radius = 60 + sin(time * 0.6) * 20
        
        let blob3Gradient = Gradient(stops: [
            .init(color: Color(red: 1.0, green: 0.1, blue: 0.6).opacity(0.8), location: 0),
            .init(color: Color(red: 1.0, green: 0.3, blue: 0.5).opacity(0.5), location: 0.7),
            .init(color: Color(red: 0.8, green: 0.1, blue: 0.4).opacity(0.2), location: 1)
        ])
        
        context.fill(
            Circle().path(in: CGRect(
                x: blob3X - blob3Radius/2,
                y: blob3Y - blob3Radius/2,
                width: blob3Radius,
                height: blob3Radius
            )),
            with: .radialGradient(
                blob3Gradient,
                center: CGPoint(x: blob3X, y: blob3Y),
                startRadius: 0,
                endRadius: blob3Radius
            )
        )
        
        // Rising bubble effect - multiple small blobs
        for i in 0..<5 {
            let bubbleTime = time * 0.15 + Double(i) * 2
            let bubbleY = size.height - (bubbleTime.truncatingRemainder(dividingBy: size.height + 200))
            let bubbleX = size.width * (0.2 + Double(i) * 0.15) + sin(bubbleTime) * 20
            let bubbleRadius = 20 + Double(i) * 5
            
            let bubbleGradient = Gradient(stops: [
                .init(color: Color(red: 1.0, green: 0.6, blue: 0.7).opacity(0.6), location: 0),
                .init(color: Color(red: 1.0, green: 0.4, blue: 0.6).opacity(0.2), location: 1)
            ])
            
            context.fill(
                Circle().path(in: CGRect(
                    x: bubbleX - bubbleRadius/2,
                    y: bubbleY - bubbleRadius/2,
                    width: bubbleRadius,
                    height: bubbleRadius
                )),
                with: .radialGradient(
                    bubbleGradient,
                    center: CGPoint(x: bubbleX, y: bubbleY),
                    startRadius: 0,
                    endRadius: bubbleRadius
                )
            )
        }
    }
}